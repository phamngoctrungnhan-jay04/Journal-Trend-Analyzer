import 'dart:convert';
import 'package:http/http.dart' as http;
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
    final allParams = {
      ...params,
      'mailto': 'phamngoctrungnhan0901@gmail.com',
    };
    return Uri.parse('${AppConstants.baseUrl}$path').replace(
      queryParameters: allParams,
    );
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 429) {
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

  // FR 4.1 - Tìm kiếm bài báo theo từ khoá
  // Trả về danh sách works + tổng số kết quả
  Future<Map<String, dynamic>> searchWorks({
    required String query,
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'search': query,
      'filter': 'type:article',
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
    // workId có thể là full URL "https://openalex.org/W..." hoặc chỉ "W..."
    final id = workId.startsWith('https://') ? workId.split('/').last : workId;
    final uri = _buildUri(
      '${AppConstants.worksEndpoint}/$id',
      {},
    );
    return _get(uri);
  }

  // FR 4.3 - Số lượng bài báo theo từng năm (dùng group_by)
  // group_by trả về {key: "2023", count: 150} — rất hiệu quả, không cần tải toàn bộ data
  Future<Map<String, dynamic>> getPublicationsByYear({
    required String query,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'search': query,
      'filter': 'type:article',
      'group_by': 'publication_year',
      'per_page': '200',
    });
    return _get(uri);
  }

  // FR 4.4 - Top bài báo được trích dẫn nhiều nhất
  Future<Map<String, dynamic>> getTopCitedWorks({
    required String query,
    int perPage = AppConstants.topPapersCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'search': query,
      'filter': 'type:article,cited_by_count:>0',
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
    required String query,
    int perPage = AppConstants.topJournalsCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'search': query,
      'filter': 'type:article',
      'group_by': 'primary_location.source.id',
      'per_page': perPage.toString(),
    });
    return _get(uri);
  }

  // FR 4.6 - Top tác giả theo số bài báo (dùng group_by authorships.author.id)
  Future<Map<String, dynamic>> getTopAuthors({
    required String query,
    int perPage = AppConstants.topAuthorsCount,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'search': query,
      'filter': 'type:article',
      'group_by': 'authorships.author.id',
      'per_page': perPage.toString(),
    });
    return _get(uri);
  }

  // FR 4.7 Dashboard - lấy tổng quan (tổng số bài, average citation)
  // Dùng per_page=1 để chỉ lấy metadata, không tải toàn bộ dữ liệu
  Future<Map<String, dynamic>> getDashboardOverview({
    required String query,
  }) async {
    final uri = _buildUri(AppConstants.worksEndpoint, {
      'search': query,
      'filter': 'type:article',
      'per_page': '1',
      'select': 'id,cited_by_count',
    });
    return _get(uri);
  }

  void dispose() {
    _client.close();
  }
}
