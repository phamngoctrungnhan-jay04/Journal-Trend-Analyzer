import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/research_scope.dart';
import '../utils/constants.dart';

// Đại diện cho lỗi từ API - giúp hiển thị thông báo lỗi thân thiện cho user
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class OpenAlexService {
  final http.Client _client;

  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();

  // Tất cả request đều thêm email vào query để OpenAlex ưu tiên rate limit cao hơn
  Uri _buildUri(String path, Map<String, String> params) {
    final allParams = {...params, 'mailto': 'phamngoctrungnhan0901@gmail.com'};
    return Uri.parse(
      '${AppConstants.baseUrl}$path',
    ).replace(queryParameters: allParams);
  }

  // Số lần thử lại khi bị OpenAlex giới hạn tần suất (429). Chờ backoff tăng
  // dần (1s, 2s, 4s) rồi thử lại - throttle của OpenAlex thường chỉ tạm thời,
  // nhất là khi gọi dồn dập (vd chạy nhiều test E2E liên tiếp).
  static const _maxRetriesOn429 = 3;

  Future<Map<String, dynamic>> _get(Uri uri) async {
    for (var attempt = 0; ; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        }

        if (response.statusCode == 429) {
          if (attempt < _maxRetriesOn429) {
            await Future.delayed(Duration(seconds: 1 << attempt));
            continue;
          }
          throw const ApiException(
            'Quá nhiều yêu cầu. Vui lòng đợi một chút rồi thử lại.',
            statusCode: 429,
          );
        }

        throw ApiException(
          'Lỗi máy chủ (${response.statusCode}). Vui lòng thử lại.',
          statusCode: response.statusCode,
        );
      } on ApiException {
        rethrow;
      } catch (e) {
        throw ApiException('Không thể kết nối. Kiểm tra kết nối mạng của bạn.');
      }
    }
  }

  // OpenAlex trả id dạng URL đầy đủ ("https://openalex.org/W123") nhưng filter
  // chỉ nhận phần cuối. Chấp nhận cả hai dạng để nơi gọi khỏi phải quan tâm.
  String _rawId(String id) =>
      id.startsWith('https://') ? id.split('/').last : id;

  // Dựng tham số giới hạn truy vấn về đúng phạm vi [scope]. Gom vào một chỗ vì
  // MỌI endpoint bên dưới đều cần đúng logic này; trước đây mỗi method tự nối
  // chuỗi filter bằng tay nên rất dễ lệch nhau.
  //
  // Luôn dùng `filter=` chứ không bao giờ `search=`: số đếm trả về nhờ đó luôn
  // là của riêng phạm vi đang chọn, không phải tổng full-text toàn OpenAlex.
  //
  // scope null khi truy vấn không gắn với 1 lĩnh vực nào (vd user tìm journal
  // trực tiếp ở JournalSearchField) -> bỏ hẳn mệnh đề lọc lĩnh vực, chỉ còn
  // extraFilter (thường là ràng buộc journal/keyword cụ thể).
  Map<String, String> _scopeParams(
    ResearchScope? scope, {
    String? extraFilter,
  }) {
    final filters = ['type:article', ?scope?.filterFragment, ?extraFilter];
    return {'filter': filters.join(',')};
  }

  // Số ứng viên lấy về trước khi xếp hạng lại ở client — cao hơn hẳn số gợi ý
  // hiển thị (topicSuggestionsCount) vì filter OR bên dưới cố tình quét rộng.
  // Dùng chung cho searchTopics và searchJournals (cùng chiến lược).
  static const _searchCandidates = 25;

  // Tìm CHỦ ĐỀ trong cây phân loại theo tên (không phải search bài báo). Trả
  // kèm field/subfield cha để dựng breadcrumb cho từng gợi ý.
  //
  // OpenAlex bắt buộc TẤT CẢ từ trong câu tìm phải cùng khớp 1 chủ đề (kể cả
  // với text.search quét rộng title+description+keywords) — gõ "Vietnamese
  // agriculture" ra 0 kết quả dù "agriculture" một mình ra 133 và "vietnam"
  // một mình ra 4 (kiểm chứng trực tiếp qua API thật). Xử lý: OR từng từ
  // (`text.search:word1|word2`) để quét rộng chủ đề khớp BẤT KỲ từ nào, rồi
  // xếp hạng lại theo số từ trùng — chủ đề khớp nguyên câu tự nhiên lên đầu
  // (đã bao gồm sẵn trong tập kết quả OR), chủ đề chỉ khớp 1 từ lẻ tẻ xuống
  // cuối, thay vì mất trắng như filter AND cũ.
  Future<Map<String, dynamic>> searchTopics({
    required String query,
    int perPage = AppConstants.topicSuggestionsCount,
  }) async {
    final words = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toList();
    if (words.isEmpty) return {'results': []};

    final uri = _buildUri('/topics', {
      'filter': 'text.search:${words.join('|')}',
      'select': 'id,display_name,subfield,field,works_count',
      'per_page': _searchCandidates.toString(),
    });
    final result = await _get(uri);
    return _rankByWordOverlap(result, words, take: perPage);
  }

  // Tìm JOURNAL trực tiếp theo tên (khác getTopJournals/FR 4.5 — cái đó xếp
  // hạng journal THEO 1 LĨNH VỰC, còn đây tìm journal không cần chọn lĩnh vực
  // trước). Cùng chiến lược OR-từng-từ-rồi-xếp-hạng như searchTopics, vì
  // /sources cũng đòi TẤT CẢ từ cùng khớp nếu search nguyên câu.
  //
  // `type:journal` lọc bớt các nguồn không phải journal thật (repository,
  // ebook platform...) mà OpenAlex cũng liệt vào /sources.
  Future<Map<String, dynamic>> searchJournals({
    required String query,
    int perPage = AppConstants.topicSuggestionsCount,
  }) async {
    final words = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toList();
    if (words.isEmpty) return {'results': []};

    final uri = _buildUri('/sources', {
      'filter': 'type:journal,text.search:${words.join('|')}',
      'select': 'id,display_name,works_count,host_organization_name',
      'per_page': _searchCandidates.toString(),
    });
    final result = await _get(uri);
    return _rankByWordOverlap(result, words, take: perPage);
  }

  // Chi tiết 1 journal (metadata, không phải bài báo) - dùng làm header cho
  // JournalDetailScreen: publisher, h-index, năm hoạt động, OA, homepage.
  Future<Map<String, dynamic>> getJournalById(String journalId) async {
    final uri = _buildUri('/sources/${_rawId(journalId)}', {
      'select': [
        'id',
        'display_name',
        'host_organization_name',
        'works_count',
        'cited_by_count',
        'summary_stats',
        'is_oa',
        'first_publication_year',
        'last_publication_year',
        'homepage_url',
      ].join(','),
    });
    return _get(uri);
  }

  // Volumes GẦN ĐÂY của 1 journal (>= minYear). group_by=biblio.volume mặc
  // định xếp theo SỐ BÀI nhiều nhất, không phải volume mới nhất -> volume cũ
  // tích luỹ hàng chục năm luôn thắng volume mới, ra toàn volume cổ nếu không
  // lọc năm trước (kiểm chứng qua API thật: Nature không lọc năm ra volume
  // 184/181/182... từ đầu thế kỷ). Lọc publication_year trước rồi mới
  // group_by volume để chỉ còn volume trong khoảng năm gần đây; nơi gọi tự
  // sắp lại theo số volume giảm dần (group_by không đảm bảo thứ tự đó).
  Future<Map<String, dynamic>> getRecentVolumes({
    required String journalId,
    required int minYear,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'filter':
          'primary_location.source.id:${_rawId(journalId)},'
          'publication_year:>${minYear - 1}',
      'group_by': 'biblio.volume',
    });
    return _get(uri);
  }

  // Danh sách bài báo trong 1 volume cụ thể của 1 journal, mới nhất trước.
  Future<Map<String, dynamic>> getWorksByVolume({
    required String journalId,
    required String volume,
    int perPage = AppConstants.journalWorksPerPage,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'filter':
          'primary_location.source.id:${_rawId(journalId)},'
          'biblio.volume:$volume',
      'sort': 'publication_date:desc',
      'per_page': perPage.toString(),
      'select': [
        'id',
        'title',
        'publication_year',
        'cited_by_count',
        'authorships',
        'primary_location',
        'doi',
      ].join(','),
    });
    return _get(uri);
  }

  // Danh sách bài báo của 1 tác giả cụ thể, trích dẫn cao nhất trước — mở từ
  // mục "Top tác giả đóng góp" (bấm vào 1 tác giả để xem các bài báo họ đã
  // viết). Không cần scope: authorId đã tự đủ ràng buộc, giống getWorksByVolume.
  Future<Map<String, dynamic>> getWorksByAuthor({
    required String authorId,
    int perPage = AppConstants.journalWorksPerPage,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'filter': 'type:article,authorships.author.id:${_rawId(authorId)}',
      'sort': 'cited_by_count:desc',
      'per_page': perPage.toString(),
      'select': [
        'id',
        'title',
        'publication_year',
        'cited_by_count',
        'authorships',
        'primary_location',
        'doi',
      ].join(','),
    });
    return _get(uri);
  }

  // Nhiều từ trong [words] xuất hiện trong tên (topic/journal) hơn -> liên
  // quan hơn. Hoà điểm thì ưu tiên works_count cao hơn — phổ biến hơn nghĩa
  // là khớp với ý người dùng đang tìm nhiều khả năng hơn.
  Map<String, dynamic> _rankByWordOverlap(
    Map<String, dynamic> result,
    List<String> words, {
    required int take,
  }) {
    final results = (result['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    int overlapScore(Map<String, dynamic> topic) {
      final name = (topic['display_name'] as String? ?? '').toLowerCase();
      return words.where((w) => name.contains(w.toLowerCase())).length;
    }

    results.sort((a, b) {
      final byOverlap = overlapScore(b).compareTo(overlapScore(a));
      if (byOverlap != 0) return byOverlap;
      final aCount = a['works_count'] as int? ?? 0;
      final bCount = b['works_count'] as int? ?? 0;
      return bCount.compareTo(aCount);
    });

    return {...result, 'results': results.take(take).toList()};
  }

  // Danh sách lĩnh vực phụ của 1 lĩnh vực chính. Endpoint /subfields rẻ hơn
  // nhiều so với /works nên gọi khi user mở 1 lĩnh vực là chấp nhận được
  // (TaxonomyProvider cache lại -> mỗi lĩnh vực chỉ 1 request/phiên).
  Future<Map<String, dynamic>> getSubfields({required String fieldId}) async {
    final uri = _buildUri('/subfields', {
      'filter': 'field.id:$fieldId',
      'select': 'id,display_name',
      'per_page': '50',
    });
    return _get(uri);
  }

  // FR 4.1 - Danh sách bài báo trong phạm vi đang chọn, sắp theo trích dẫn
  // giảm dần. Trả về works + tổng số kết quả (meta.count).
  Future<Map<String, dynamic>> getWorks({
    required ResearchScope scope,
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope),
      'sort': 'cited_by_count:desc',
      'per_page': perPage.toString(),
      'page': page.toString(),
      'select': [
        'id',
        'title',
        'publication_year',
        'cited_by_count',
        'authorships',
        'primary_location',
        'doi',
        'type',
      ].join(','),
    });

    return _get(uri);
  }

  // FR 4.2 - Chi tiết 1 bài báo (có thêm abstract)
  Future<Map<String, dynamic>> getWorkById(String workId) async {
    final uri = _buildUri(
      '${AppConstants.worksEndpoint}/${_rawId(workId)}',
      {},
    );
    return _get(uri);
  }

  // FR 4.3 - Số lượng bài báo theo từng năm (dùng group_by)
  // group_by trả về {key: "2023", count: 150} — rất hiệu quả, không cần tải toàn bộ data
  Future<Map<String, dynamic>> getPublicationsByYear({
    required ResearchScope scope,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope),
      'group_by': 'publication_year',
      'per_page': '200',
    });
    return _get(uri);
  }

  // FR 4.4 - Top bài báo được trích dẫn nhiều nhất
  Future<Map<String, dynamic>> getTopCitedWorks({
    required ResearchScope scope,
    int perPage = AppConstants.topPapersCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope, extraFilter: 'cited_by_count:>0'),
      'sort': 'cited_by_count:desc',
      'per_page': perPage.toString(),
      'select': [
        'id',
        'title',
        'publication_year',
        'cited_by_count',
        'authorships',
        'primary_location',
        'doi',
      ].join(','),
    });
    return _get(uri);
  }

  // FR 4.5 - Top journals theo số bài báo (dùng group_by primary_location.source.id)
  Future<Map<String, dynamic>> getTopJournals({
    required ResearchScope scope,
    int perPage = AppConstants.topJournalsCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope),
      'group_by': 'primary_location.source.id',
      'per_page': perPage.toString(),
    });
    return _get(uri);
  }

  // FR 4.6 - Top tác giả theo số bài báo (dùng group_by authorships.author.id)
  Future<Map<String, dynamic>> getTopAuthors({
    required ResearchScope scope,
    int perPage = AppConstants.topAuthorsCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope),
      'group_by': 'authorships.author.id',
      'per_page': perPage.toString(),
    });
    return _get(uri);
  }

  // Keywords - top từ khoá theo tần suất (dùng group_by topics.id, không
  // dùng concepts.id vì OpenAlex đã deprecate concepts để chuyển sang topics).
  //
  // Đây chính là tầng thứ 3 của cây phân loại (4.516 topic): khi scope là 1
  // lĩnh vực phụ, kết quả là các chủ đề hẹp nằm trong lĩnh vực phụ đó.
  Future<Map<String, dynamic>> getTopKeywords({
    required ResearchScope scope,
    int perPage = AppConstants.topKeywordsCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope),
      'group_by': 'topics.id',
      'per_page': perPage.toString(),
    });
    return _get(uri);
  }

  // Phân tích từ khóa TỰ DO (tab Keywords, gõ + Enter) - chuyển câu tìm ->
  // filter fragment lọc /works. CHỈ dùng entity keywords.id nếu có mục khớp
  // CHÍNH XÁC (không phân biệt hoa/thường) với đúng câu user gõ — không lấy
  // đại kết quả có relevance_score cao nhất, vì OpenAlex thường không có
  // entity trùng tên 1-1 mà chỉ có các cụm chứa từ đó (gõ "plant" ra top-1
  // là "Medicinal plants" chứ không phải "Plant", kiểm chứng qua API thật) —
  // lấy nhầm cụm đó sẽ phân tích sai hẳn khái niệm user muốn. Không khớp
  // chính xác (kể cả do không có entity nào tên y hệt, hoặc do tiếng Việt vì
  // entity OpenAlex chỉ có tên tiếng Anh) -> lùi về full-text default.search
  // ngay trên ĐÚNG câu gốc, không thay bằng khái niệm nào khác.
  Future<({String filter, String label})> resolveKeywordQuery(
    String query,
  ) async {
    final trimmed = query.trim();
    final uri = _buildUri('/keywords', {
      'filter': 'text.search:$trimmed',
      'per_page': '25',
    });
    final result = await _get(uri);
    final results = result['results'] as List<dynamic>? ?? [];
    final exactMatch = results
        .whereType<Map<String, dynamic>>()
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (m) =>
              (m?['display_name'] as String?)?.toLowerCase() ==
              trimmed.toLowerCase(),
          orElse: () => null,
        );
    if (exactMatch != null) {
      final id = exactMatch['id'] as String?;
      final name = exactMatch['display_name'] as String?;
      if (id != null && name != null) {
        return (filter: 'keywords.id:${_rawId(id)}', label: name);
      }
    }
    return (filter: 'default.search:$trimmed', label: trimmed);
  }

  Future<Map<String, dynamic>> analyzeKeywordYearlyTrend({
    required String matchFilter,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(null, extraFilter: matchFilter),
      'group_by': 'publication_year',
      'per_page': '200',
    });
    return _get(uri);
  }

  Future<Map<String, dynamic>> analyzeKeywordTopAuthors({
    required String matchFilter,
    int perPage = AppConstants.keywordAuthorsCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(null, extraFilter: matchFilter),
      'group_by': 'authorships.author.id',
      'per_page': perPage.toString(),
    });
    return _get(uri);
  }

  Future<Map<String, dynamic>> analyzeRelatedKeywords({
    required String matchFilter,
    int perPage = AppConstants.relatedKeywordsCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(null, extraFilter: matchFilter),
      'group_by': 'keywords.id',
      'per_page': perPage.toString(),
    });
    return _get(uri);
  }

  // Mẫu bài trích dẫn cao nhất để tính "điểm đánh giá" (TB trích dẫn/bài) cho
  // phần tổng quan — group_by KHÔNG trả tổng trích dẫn (chỉ đếm số bài), nên
  // phải lấy mẫu bài thật rồi tính trung bình ở tầng viewmodel, giống hệt
  // cách JournalDetailViewModel.averageCitation đã làm.
  Future<Map<String, dynamic>> analyzeKeywordTopWorks({
    required String matchFilter,
    int perPage = AppConstants.keywordTopWorksSampleSize,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(null, extraFilter: matchFilter),
      'sort': 'cited_by_count:desc',
      'per_page': perPage.toString(),
      'select': [
        'id',
        'title',
        'publication_year',
        'cited_by_count',
        'authorships',
        'primary_location',
        'doi',
      ].join(','),
    });
    return _get(uri);
  }

  // Keyword Detail - trend theo năm, lọc thêm theo 1 keyword cụ thể
  Future<Map<String, dynamic>> getKeywordYearlyTrend({
    required ResearchScope scope,
    required String keywordId,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope, extraFilter: 'topics.id:${_rawId(keywordId)}'),
      'group_by': 'publication_year',
      'per_page': '200',
    });
    return _get(uri);
  }

  // Keyword Detail - từ khóa liên quan (entity keywords.id chính thống của
  // OpenAlex, KHÔNG tự tách chữ từ title/abstract). Lọc theo cùng 1 topic +
  // scope như getKeywordYearlyTrend/getKeywordTopAuthors nên trả về đúng bộ
  // keywords hay đi kèm chủ đề đang xem, không phải mảnh âm tiết.
  Future<Map<String, dynamic>> getRelatedKeywords({
    required ResearchScope scope,
    required String keywordId,
    int perPage = AppConstants.relatedKeywordsCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope, extraFilter: 'topics.id:${_rawId(keywordId)}'),
      'group_by': 'keywords.id',
      'per_page': perPage.toString(),
    });
    return _get(uri);
  }

  // Keyword Detail - rank tác giả, lọc thêm theo 1 keyword cụ thể
  Future<Map<String, dynamic>> getKeywordTopAuthors({
    required ResearchScope scope,
    required String keywordId,
    int perPage = AppConstants.keywordAuthorsCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope, extraFilter: 'topics.id:${_rawId(keywordId)}'),
      'group_by': 'authorships.author.id',
      'per_page': perPage.toString(),
    });
    return _get(uri);
  }

  // Journal Detail - danh sách bài báo trong 1 journal cụ thể. scope null khi
  // user tìm journal trực tiếp (JournalSearchField, không qua chọn lĩnh vực)
  // -> chỉ còn ràng buộc journal, không lọc lĩnh vực.
  Future<Map<String, dynamic>> getWorksByJournal({
    ResearchScope? scope,
    required String journalId,
    int perPage = AppConstants.journalWorksPerPage,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(
        scope,
        extraFilter: 'primary_location.source.id:${_rawId(journalId)}',
      ),
      'sort': 'cited_by_count:desc',
      'per_page': perPage.toString(),
      'select': [
        'id',
        'title',
        'publication_year',
        'cited_by_count',
        'authorships',
        'primary_location',
        'doi',
      ].join(','),
    });
    return _get(uri);
  }

  // Journal Detail - xu hướng xuất bản theo năm của CHÍNH journal này, không
  // giới hạn lĩnh vực nào (khác getKeywordYearlyTrend cần scope) — journal đã
  // tự đủ ràng buộc, giống getWorksByVolume/getRecentVolumes.
  Future<Map<String, dynamic>> getJournalYearlyTrend({
    required String journalId,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'filter': 'type:article,primary_location.source.id:${_rawId(journalId)}',
      'group_by': 'publication_year',
      'per_page': '200',
    });
    return _get(uri);
  }

  // Tỷ lệ Open Access của phạm vi đang chọn. group_by=open_access.is_oa trả về
  // đúng 2 nhóm (true/false) trong 1 lần gọi — rẻ hơn hẳn so với gọi riêng
  // getWorks với filter open_access.is_oa:true rồi tự trừ ra false.
  Future<Map<String, dynamic>> getOpenAccessBreakdown({
    required ResearchScope scope,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      ..._scopeParams(scope),
      'group_by': 'open_access.is_oa',
    });
    return _get(uri);
  }

  void dispose() {
    _client.close();
  }
}
