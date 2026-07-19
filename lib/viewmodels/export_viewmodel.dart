import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/dashboard_stats.dart';
import '../models/work.dart';
import '../models/journal.dart';
import '../models/author.dart';
import '../models/keyword.dart';
import '../models/research_scope.dart';
import '../services/openalex_service.dart';
import '../services/pdf_report_service.dart';
import '../firebase/storage_service.dart';
import '../firebase/analytics_service.dart';
import '../utils/constants.dart';

enum ExportState { idle, loading, success, error }

// Orchestrator xuất báo cáo PDF. Từ khi mỗi tab giữ phạm vi riêng, app không
// còn "một chủ đề chung" để lấy sẵn dữ liệu — nên ExportViewModel tự chọn phạm
// vi (user tìm ở Profile) và TỰ gọi API gom đủ dữ liệu cho báo cáo, rồi mới
// build PDF -> upload Storage -> log Analytics.
//
// 5 call chỉ chạy khi user thực sự bấm Xuất (không phải load-on-entry) nên
// chấp nhận được về quota.
class ExportViewModel extends ChangeNotifier {
  final OpenAlexService _service;
  final PdfReportService _pdfService;
  final StorageService _storageService;
  final AnalyticsService _analytics;

  ExportViewModel({
    OpenAlexService? service,
    PdfReportService? pdfService,
    StorageService? storageService,
    AnalyticsService? analytics,
  }) : _service = service ?? OpenAlexService(),
       _pdfService = pdfService ?? PdfReportService(),
       _storageService = storageService ?? StorageService(),
       _analytics = analytics ?? AnalyticsService();

  ExportState _state = ExportState.idle;
  ExportState get state => _state;

  // Phạm vi user đã chọn để xuất (null = chưa chọn -> nút Xuất bị khoá).
  ResearchScope? _scope;
  ResearchScope? get scope => _scope;
  bool get hasScope => _scope != null;

  String? _downloadUrl;
  String? get downloadUrl => _downloadUrl;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ExportState.loading;
  bool get isSuccess => _state == ExportState.success;
  bool get isError => _state == ExportState.error;

  // Chọn phạm vi để xuất. Reset kết quả cũ để tránh hiện URL của lần xuất trước
  // sau khi user đã đổi sang chủ đề khác.
  void selectScope(ResearchScope scope) {
    _scope = scope;
    _state = ExportState.idle;
    _downloadUrl = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> exportReport() async {
    final scope = _scope;
    if (scope == null) return;

    _state = ExportState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final stats = await _fetchStats(scope);
      final bytes = await _pdfService.buildReport(
        stats: stats.dashboard,
        yearlyTrends: stats.yearlyTrends,
        topJournals: stats.topJournals,
        topAuthors: stats.topAuthors,
        topKeywords: stats.topKeywords,
      );
      final fileName =
          '${_sanitize(scope.label)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final url = await _storageService.uploadPdf(
        fileName: fileName,
        bytes: bytes,
      );
      _downloadUrl = url;
      _state = ExportState.success;
      unawaited(_analytics.logExportPdf(scope.label));
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ExportState.error;
    } catch (e) {
      _errorMessage = 'Không thể xuất báo cáo. Vui lòng thử lại.';
      _state = ExportState.error;
    }
    notifyListeners();
  }

  // Gom đủ dữ liệu cho 1 báo cáo bằng cách gọi song song. getWorks trả cả
  // meta.count (tổng bài trong phạm vi) lẫn danh sách bài dẫn đầu.
  Future<_ReportData> _fetchStats(ResearchScope scope) async {
    final results = await Future.wait([
      _service.getWorks(scope: scope, perPage: AppConstants.topPapersCount),
      _service.getPublicationsByYear(scope: scope),
      _service.getTopJournals(scope: scope),
      _service.getTopAuthors(scope: scope),
      _service.getTopKeywords(scope: scope),
    ]);

    final meta = results[0]['meta'] as Map<String, dynamic>? ?? {};
    final totalCount = meta['count'] as int? ?? 0;
    final worksJson = results[0]['results'] as List<dynamic>? ?? [];
    final topCitedWorks = worksJson
        .whereType<Map<String, dynamic>>()
        .map((j) => Work.fromJson(j))
        .toList();

    final yearGroups = results[1]['group_by'] as List<dynamic>? ?? [];
    final yearlyTrends =
        yearGroups
            .whereType<Map<String, dynamic>>()
            .map((j) => YearlyTrend.fromGroupByJson(j))
            .where((t) => t.year >= 1990 && t.year <= DateTime.now().year)
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    final journalGroups = results[2]['group_by'] as List<dynamic>? ?? [];
    final topJournals = journalGroups
        .whereType<Map<String, dynamic>>()
        .map((j) => TopJournal.fromGroupByJson(j))
        .where((j) => j.displayName.isNotEmpty && j.id.isNotEmpty)
        .toList();

    final authorGroups = results[3]['group_by'] as List<dynamic>? ?? [];
    final topAuthors = authorGroups
        .whereType<Map<String, dynamic>>()
        .map((j) => TopAuthor.fromGroupByJson(j))
        .where((a) => a.displayName.isNotEmpty && a.id.isNotEmpty)
        .toList();

    final keywordGroups = results[4]['group_by'] as List<dynamic>? ?? [];
    final topKeywords = keywordGroups
        .whereType<Map<String, dynamic>>()
        .map((j) => Keyword.fromGroupByJson(j))
        .where((k) => k.displayName.isNotEmpty && k.id.isNotEmpty)
        .toList();

    double avgCitation = 0;
    if (topCitedWorks.isNotEmpty) {
      final total = topCitedWorks.fold<int>(
        0,
        (sum, w) => sum + w.citedByCount,
      );
      avgCitation = total / topCitedWorks.length;
    }

    final dashboard = DashboardStats.fromAnalysisData(
      topic: scope.label,
      totalPublications: totalCount,
      yearlyTrends: yearlyTrends,
      topJournals: topJournals,
      topAuthors: topAuthors,
      topKeywords: topKeywords,
      topCitedWorks: topCitedWorks,
      averageCitationCount: avgCitation,
    );

    return _ReportData(
      dashboard: dashboard,
      yearlyTrends: yearlyTrends,
      topJournals: topJournals,
      topAuthors: topAuthors,
      topKeywords: topKeywords,
    );
  }

  void reset() {
    _state = ExportState.idle;
    _downloadUrl = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _sanitize(String topic) =>
      topic.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

// Gói dữ liệu một báo cáo. DashboardStats không giữ được list journals/authors/
// keywords đầy đủ (chỉ giữ "top 1" cho overview) nên PDF cần list riêng.
class _ReportData {
  final DashboardStats dashboard;
  final List<YearlyTrend> yearlyTrends;
  final List<TopJournal> topJournals;
  final List<TopAuthor> topAuthors;
  final List<Keyword> topKeywords;

  const _ReportData({
    required this.dashboard,
    required this.yearlyTrends,
    required this.topJournals,
    required this.topAuthors,
    required this.topKeywords,
  });
}
