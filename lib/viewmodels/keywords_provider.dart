import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/work.dart';
import '../models/author.dart';
import '../models/keyword.dart';
import '../services/openalex_service.dart';
import '../firebase/analytics_service.dart';

enum KeywordAnalysisState { initial, loading, success, error }

// State của tab Keywords — gõ MỘT câu tìm tự do rồi Enter là phân tích ngay
// (không qua bước chọn lĩnh vực nào), khác hẳn KeywordDetailViewModel (dùng
// cho "Phân bố theo chủ đề" ở Home, cần chọn lĩnh vực trước, dựa trên
// topics.id trong cây phân loại). 2 luồng độc lập, không đụng nhau.
class KeywordsProvider extends ChangeNotifier {
  final OpenAlexService _service;
  final AnalyticsService _analytics;

  KeywordsProvider({OpenAlexService? service, AnalyticsService? analytics})
    : _service = service ?? OpenAlexService(),
      _analytics = analytics ?? AnalyticsService();

  KeywordAnalysisState _state = KeywordAnalysisState.initial;
  KeywordAnalysisState get state => _state;

  String _query = '';
  String get query => _query;

  String _resolvedLabel = '';
  String get resolvedLabel => _resolvedLabel;

  // Filter dùng để xem TOÀN BỘ bài báo khớp đúng câu tìm vừa phân tích
  // (keywords.id:X nếu khớp entity, default.search:X nếu lùi về full-text) —
  // cho KeywordWorksScreen mở từ chính kết quả tìm, không chỉ từ khóa liên
  // quan.
  String _resolvedFilter = '';
  String get resolvedFilter => _resolvedFilter;

  List<YearlyTrend> _yearlyTrends = [];
  List<YearlyTrend> get yearlyTrends => _yearlyTrends;

  List<TopAuthor> _topAuthors = [];
  List<TopAuthor> get topAuthors => _topAuthors;

  List<Keyword> _relatedKeywords = [];
  List<Keyword> get relatedKeywords => _relatedKeywords;

  int _totalWorksCount = 0;
  int get totalWorksCount => _totalWorksCount;

  List<Work> _topWorks = [];
  // TB trích dẫn/bài trên mẫu bài trích dẫn cao nhất — dùng làm "điểm đánh
  // giá" cho từ khóa, tính được cho MỌI câu tìm (kể cả khi phải lùi về
  // full-text) vì không phụ thuộc entity keywords.id có khớp hay không.
  double get averageCitation {
    if (_topWorks.isEmpty) return 0;
    final total = _topWorks.fold<int>(0, (sum, w) => sum + w.citedByCount);
    return total / _topWorks.length;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isInitial => _state == KeywordAnalysisState.initial;
  bool get isLoading => _state == KeywordAnalysisState.loading;
  bool get isError => _state == KeywordAnalysisState.error;

  Future<void> analyze(String rawQuery) async {
    final trimmed = rawQuery.trim();
    if (trimmed.isEmpty) return;

    _query = trimmed;
    _errorMessage = null;
    _setState(KeywordAnalysisState.loading);

    try {
      final resolved = await _service.resolveKeywordQuery(trimmed);
      _resolvedLabel = resolved.label;
      _resolvedFilter = resolved.filter;

      final results = await Future.wait([
        _service.analyzeKeywordYearlyTrend(matchFilter: resolved.filter),
        _service.analyzeKeywordTopAuthors(matchFilter: resolved.filter),
        _service.analyzeRelatedKeywords(matchFilter: resolved.filter),
        _service.analyzeKeywordTopWorks(matchFilter: resolved.filter),
      ]);

      final meta = results[0]['meta'] as Map<String, dynamic>?;
      _totalWorksCount = meta?['count'] as int? ?? 0;

      final yearGroups = results[0]['group_by'] as List<dynamic>? ?? [];
      _yearlyTrends =
          yearGroups
              .whereType<Map<String, dynamic>>()
              .map((j) => YearlyTrend.fromGroupByJson(j))
              .where((t) => t.year >= 1990 && t.year <= DateTime.now().year)
              .toList()
            ..sort((a, b) => a.year.compareTo(b.year));

      final authorGroups = results[1]['group_by'] as List<dynamic>? ?? [];
      _topAuthors = authorGroups
          .whereType<Map<String, dynamic>>()
          .map((j) => TopAuthor.fromGroupByJson(j))
          .where((a) => a.displayName.isNotEmpty && a.id.isNotEmpty)
          .toList();

      final relatedGroups = results[2]['group_by'] as List<dynamic>? ?? [];
      _relatedKeywords = relatedGroups
          .whereType<Map<String, dynamic>>()
          .map((j) => Keyword.fromGroupByJson(j))
          .where(
            (k) =>
                k.displayName.isNotEmpty &&
                k.id.isNotEmpty &&
                k.displayName.toLowerCase() != _resolvedLabel.toLowerCase(),
          )
          .toList();

      final topWorksJson = results[3]['results'] as List<dynamic>? ?? [];
      _topWorks = topWorksJson
          .whereType<Map<String, dynamic>>()
          .map((j) => Work.fromJson(j))
          .toList();

      _setState(KeywordAnalysisState.success);
      unawaited(_analytics.logSearchTopic(trimmed));
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(KeywordAnalysisState.error);
    } catch (e) {
      // Thiếu nhánh này thì lỗi ngoài dự kiến làm _state kẹt ở loading.
      _errorMessage = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
      _setState(KeywordAnalysisState.error);
    }
  }

  Future<void> retry() async {
    if (_query.isNotEmpty) await analyze(_query);
  }

  void _setState(KeywordAnalysisState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
