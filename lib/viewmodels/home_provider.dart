import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/work.dart';
import '../models/journal.dart';
import '../models/author.dart';
import '../models/keyword.dart';
import '../models/research_scope.dart';
import '../services/openalex_service.dart';
import '../firebase/analytics_service.dart';
import '../utils/constants.dart';

enum HomeState { initial, loading, success, error }

// State của RIÊNG tab Home. Mỗi tab giữ phạm vi riêng, không tab nào đổi tab
// nào — bạn có thể xem Home ở "Software" trong khi Keywords ở "Blockchain".
//
// Gọi 6 API song song mỗi lần chọn phạm vi (đánh đổi có chủ đích cho Home v2
// nhiều thông tin hơn — Journals/Keywords vẫn chỉ tự gọi 1 API của riêng
// chúng khi user mở tab đó):
//   1. getWorks              -> danh sách bài báo + meta.count + TB trích dẫn
//   2. getPublicationsByYear -> biểu đồ xu hướng + năm sôi nổi
//   3. getTopJournals        -> card "Tạp chí xuất bản nhiều nhất"
//   4. getTopAuthors         -> card + list "Tác giả đóng góp nhiều nhất"
//   5. getTopKeywords        -> "Phân bố theo chủ đề" (tầng Topic, tái dùng
//                                nguyên method Keywords tab đang dùng)
//   6. getOpenAccessBreakdown -> stat "Tỷ lệ OA"
class HomeProvider extends ChangeNotifier {
  final OpenAlexService _service;
  final AnalyticsService _analytics;

  HomeProvider({OpenAlexService? service, AnalyticsService? analytics})
    : _service = service ?? OpenAlexService(),
      _analytics = analytics ?? AnalyticsService();

  HomeState _state = HomeState.initial;
  HomeState get state => _state;

  ResearchScope? _scope;
  ResearchScope? get scope => _scope;
  bool get hasScope => _scope != null;

  List<Work> _works = [];
  List<Work> get works => _works;

  List<YearlyTrend> _yearlyTrends = [];
  List<YearlyTrend> get yearlyTrends => _yearlyTrends;

  List<TopJournal> _topJournals = [];
  List<TopJournal> get topJournals => _topJournals;

  List<TopAuthor> _topAuthors = [];
  List<TopAuthor> get topAuthors => _topAuthors;

  List<Keyword> _topKeywords = [];
  List<Keyword> get topKeywords => _topKeywords;

  int _oaCount = 0;
  int _oaTotal = 0;
  double get oaRate => _oaTotal == 0 ? 0 : _oaCount / _oaTotal;
  String get formattedOaRate => '${(oaRate * 100).toStringAsFixed(1)}%';

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Tổng số bài báo TRONG PHẠM VI đang chọn (từ meta.count của getWorks) —
  // không phải tổng toàn OpenAlex.
  int _totalResults = 0;
  int get totalResults => _totalResults;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool get isInitial => _state == HomeState.initial;
  bool get isLoading => _state == HomeState.loading && _works.isEmpty;
  bool get isSuccess => _state == HomeState.success;
  bool get isError => _state == HomeState.error;

  // Trung bình trích dẫn ước lượng từ các bài dẫn đầu đã tải. getWorks đã sort
  // theo cited_by_count:desc nên không cần gọi thêm getTopCitedWorks.
  double get averageCitation {
    if (_works.isEmpty) return 0;
    final top = _works.take(AppConstants.topPapersCount).toList();
    final total = top.fold<int>(0, (sum, w) => sum + w.citedByCount);
    return total / top.length;
  }

  String get formattedAvgCitation => averageCitation.toStringAsFixed(1);

  YearlyTrend? get peakYear => _yearlyTrends.isEmpty
      ? null
      : _yearlyTrends.reduce((a, b) => a.count > b.count ? a : b);

  Future<void> load(ResearchScope scope) async {
    _scope = scope;
    _works = [];
    _yearlyTrends = [];
    _topJournals = [];
    _topAuthors = [];
    _topKeywords = [];
    _oaCount = 0;
    _oaTotal = 0;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    _setState(HomeState.loading);
    unawaited(_analytics.logSearchTopic(scope.label));

    try {
      final results = await Future.wait([
        _service.getWorks(
          scope: scope,
          page: 1,
          perPage: AppConstants.defaultPerPage,
        ),
        _service.getPublicationsByYear(scope: scope),
        _service.getTopJournals(scope: scope),
        _service.getTopAuthors(scope: scope),
        _service.getTopKeywords(scope: scope),
        _service.getOpenAccessBreakdown(scope: scope),
      ]);

      _parseWorks(results[0]);

      final yearGroups = results[1]['group_by'] as List<dynamic>? ?? [];
      _yearlyTrends =
          yearGroups
              .whereType<Map<String, dynamic>>()
              .map((j) => YearlyTrend.fromGroupByJson(j))
              .where((t) => t.year >= 1990 && t.year <= DateTime.now().year)
              .toList()
            ..sort((a, b) => a.year.compareTo(b.year));

      final journalGroups = results[2]['group_by'] as List<dynamic>? ?? [];
      _topJournals = journalGroups
          .whereType<Map<String, dynamic>>()
          .map((j) => TopJournal.fromGroupByJson(j))
          .where((j) => j.displayName.isNotEmpty && j.id.isNotEmpty)
          .toList();

      final authorGroups = results[3]['group_by'] as List<dynamic>? ?? [];
      _topAuthors = authorGroups
          .whereType<Map<String, dynamic>>()
          .map((j) => TopAuthor.fromGroupByJson(j))
          .where((a) => a.displayName.isNotEmpty && a.id.isNotEmpty)
          .toList();

      final keywordGroups = results[4]['group_by'] as List<dynamic>? ?? [];
      _topKeywords = keywordGroups
          .whereType<Map<String, dynamic>>()
          .map((j) => Keyword.fromGroupByJson(j))
          .where((k) => k.displayName.isNotEmpty && k.id.isNotEmpty)
          .toList();

      // group_by open_access.is_oa trả về 2 nhóm: key là "0"/"1" (đã kiểm
      // chứng bằng API thật), key_display_name mới là "false"/"true" — đọc
      // key_display_name cho rõ nghĩa, tránh phụ thuộc vào mã số nội bộ.
      final oaGroups = results[5]['group_by'] as List<dynamic>? ?? [];
      for (final g in oaGroups.whereType<Map<String, dynamic>>()) {
        final isTrue = g['key_display_name'] == 'true';
        final count = g['count'] as int? ?? 0;
        _oaTotal += count;
        if (isTrue) _oaCount = count;
      }

      _setState(HomeState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(HomeState.error);
    } catch (e) {
      // Lỗi ngoài dự kiến (vd parse JSON hỏng). Thiếu nhánh này thì lỗi thoát
      // ra ngoài mà không ai bắt -> _state kẹt ở loading, màn hình quay
      // spinner mãi thay vì báo lỗi.
      _errorMessage = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
      _setState(HomeState.error);
    }
  }

  Future<void> retry() async {
    final s = _scope;
    if (s != null) await load(s);
  }

  // Quay về lưới chọn lĩnh vực.
  void clear() {
    _scope = null;
    _works = [];
    _yearlyTrends = [];
    _topJournals = [];
    _topAuthors = [];
    _topKeywords = [];
    _oaCount = 0;
    _oaTotal = 0;
    _totalResults = 0;
    _setState(HomeState.initial);
  }

  // Trang tiếp theo cho tab Bài báo (cuộn vô hạn).
  Future<void> loadMore() async {
    final scope = _scope;
    if (scope == null || !_hasMore || _state == HomeState.loading) return;

    _currentPage++;
    _setState(HomeState.loading);

    try {
      final result = await _service.getWorks(
        scope: scope,
        page: _currentPage,
        perPage: AppConstants.defaultPerPage,
      );
      _parseWorks(result);
      _setState(HomeState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _failLoadMore();
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
      _failLoadMore();
    }
  }

  void _parseWorks(Map<String, dynamic> result) {
    final meta = result['meta'] as Map<String, dynamic>? ?? {};
    _totalResults = meta['count'] as int? ?? 0;

    final resultsJson = result['results'] as List<dynamic>? ?? [];
    final newWorks = resultsJson
        .whereType<Map<String, dynamic>>()
        .map((json) => Work.fromJson(json))
        .where((w) => w.title != 'Untitled' && w.title.isNotEmpty)
        .toList();

    _works = [..._works, ...newWorks];
    _hasMore = newWorks.length >= AppConstants.defaultPerPage;
  }

  // Lỗi khi đang tải thêm trang -> giữ kết quả cũ, chỉ dừng phân trang (không
  // đá user ra màn lỗi trắng khi họ đã có dữ liệu).
  void _failLoadMore() {
    _currentPage--;
    _hasMore = false;
    _setState(HomeState.success);
  }

  void logViewPublication(Work work) {
    unawaited(
      _analytics.logViewPublication(
        title: work.title,
        year: work.publicationYear,
      ),
    );
  }

  void _setState(HomeState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
