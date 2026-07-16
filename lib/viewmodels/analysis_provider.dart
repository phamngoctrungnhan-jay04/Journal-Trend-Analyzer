import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../models/author.dart';
import '../models/journal.dart';
import '../models/keyword.dart';
import '../models/dashboard_stats.dart';
import '../services/openalex_service.dart';
import '../firebase/analytics_service.dart';

enum AnalysisState { initial, loading, success, error }

class AnalysisProvider extends ChangeNotifier {
  final OpenAlexService _service;
  final AnalyticsService _analytics;

  AnalysisProvider({OpenAlexService? service, AnalyticsService? analytics})
      : _service = service ?? OpenAlexService(),
        _analytics = analytics ?? AnalyticsService();

  void logViewJournal(TopJournal journal) {
    unawaited(_analytics.logViewJournal(journal.displayName));
  }

  void logViewKeyword(Keyword keyword) {
    unawaited(_analytics.logViewKeyword(keyword.displayName));
  }

  AnalysisState _state = AnalysisState.initial;
  AnalysisState get state => _state;

  String _currentTopic = '';
  String get currentTopic => _currentTopic;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Dữ liệu cho từng FR
  List<YearlyTrend> _yearlyTrends = [];
  List<YearlyTrend> get yearlyTrends => _yearlyTrends;

  List<Work> _topCitedWorks = [];
  List<Work> get topCitedWorks => _topCitedWorks;

  List<TopJournal> _topJournals = [];
  List<TopJournal> get topJournals => _topJournals;

  List<TopAuthor> _topAuthors = [];
  List<TopAuthor> get topAuthors => _topAuthors;

  List<Keyword> _topKeywords = [];
  List<Keyword> get topKeywords => _topKeywords;

  DashboardStats? _dashboardStats;
  DashboardStats? get dashboardStats => _dashboardStats;

  // Getters tiện ích
  bool get isInitial => _state == AnalysisState.initial;
  bool get isLoading => _state == AnalysisState.loading;
  bool get isSuccess => _state == AnalysisState.success;
  bool get isError => _state == AnalysisState.error;

  // Fetch toàn bộ dữ liệu cho 1 topic — gọi song song bằng Future.wait
  // để tiết kiệm thời gian (4 API cùng lúc thay vì tuần tự)
  Future<void> analyze(String topic) async {
    final trimmed = topic.trim();
    if (trimmed.isEmpty) return;

    _currentTopic = trimmed;
    _errorMessage = null;
    _clearData();
    _setState(AnalysisState.loading);

    try {
      // Gọi 6 API cùng lúc — Future.wait chờ tất cả hoàn thành
      final results = await Future.wait([
        _service.getPublicationsByYear(query: trimmed),   // index 0
        _service.getTopCitedWorks(query: trimmed),        // index 1
        _service.getTopJournals(query: trimmed),          // index 2
        _service.getTopAuthors(query: trimmed),           // index 3
        _service.getDashboardOverview(query: trimmed),    // index 4
        _service.getTopKeywords(query: trimmed),          // index 5
      ]);

      // Parse yearly trends (từ group_by)
      final yearGroups = results[0]['group_by'] as List<dynamic>? ?? [];
      _yearlyTrends = yearGroups
          .whereType<Map<String, dynamic>>()
          .map((j) => YearlyTrend.fromGroupByJson(j))
          .where((t) => t.year >= 1990 && t.year <= DateTime.now().year)
          .toList()
        ..sort((a, b) => a.year.compareTo(b.year));

      // Parse top cited works
      final worksJson = results[1]['results'] as List<dynamic>? ?? [];
      _topCitedWorks = worksJson
          .whereType<Map<String, dynamic>>()
          .map((j) => Work.fromJson(j))
          .toList();

      // Parse top journals (từ group_by)
      final journalGroups = results[2]['group_by'] as List<dynamic>? ?? [];
      _topJournals = journalGroups
          .whereType<Map<String, dynamic>>()
          .map((j) => TopJournal.fromGroupByJson(j))
          .where((j) => j.displayName.isNotEmpty && j.id.isNotEmpty)
          .toList();

      // Parse top authors (từ group_by)
      final authorGroups = results[3]['group_by'] as List<dynamic>? ?? [];
      _topAuthors = authorGroups
          .whereType<Map<String, dynamic>>()
          .map((j) => TopAuthor.fromGroupByJson(j))
          .where((a) => a.displayName.isNotEmpty && a.id.isNotEmpty)
          .toList();

      // Parse top keywords (từ group_by topics.id)
      final keywordGroups = results[5]['group_by'] as List<dynamic>? ?? [];
      _topKeywords = keywordGroups
          .whereType<Map<String, dynamic>>()
          .map((j) => Keyword.fromGroupByJson(j))
          .where((k) => k.displayName.isNotEmpty && k.id.isNotEmpty)
          .toList();

      // Tính average citation từ overview
      final meta = results[4]['meta'] as Map<String, dynamic>? ?? {};
      final totalCount = meta['count'] as int? ?? 0;

      // Tính average citation từ top cited works (ước lượng đủ dùng)
      double avgCitation = 0;
      if (_topCitedWorks.isNotEmpty) {
        final total = _topCitedWorks.fold<int>(
          0, (sum, w) => sum + w.citedByCount,
        );
        avgCitation = total / _topCitedWorks.length;
      }

      // Tổng hợp Dashboard
      _dashboardStats = DashboardStats.fromAnalysisData(
        topic: trimmed,
        totalPublications: totalCount,
        yearlyTrends: _yearlyTrends,
        topJournals: _topJournals,
        topAuthors: _topAuthors,
        topKeywords: _topKeywords,
        topCitedWorks: _topCitedWorks,
        averageCitationCount: avgCitation,
      );

      _setState(AnalysisState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AnalysisState.error);
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
      _setState(AnalysisState.error);
    }
  }

  void _clearData() {
    _yearlyTrends = [];
    _topCitedWorks = [];
    _topJournals = [];
    _topAuthors = [];
    _topKeywords = [];
    _dashboardStats = null;
  }

  void reset() {
    _state = AnalysisState.initial;
    _currentTopic = '';
    _errorMessage = null;
    _clearData();
    notifyListeners();
  }

  void _setState(AnalysisState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
