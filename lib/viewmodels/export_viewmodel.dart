import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/dashboard_stats.dart';
import '../models/work.dart';
import '../models/journal.dart';
import '../models/author.dart';
import '../models/keyword.dart';
import '../services/pdf_report_service.dart';
import '../firebase/storage_service.dart';
import '../firebase/analytics_service.dart';

enum ExportState { idle, loading, success, error }

// Orchestrator: build PDF -> upload Storage -> log Analytics. Dùng cục bộ
// trong ProfileScreen (không đăng ký vào MultiProvider toàn app) vì đây
// là hành động one-off có feedback tại chỗ, không phải load-on-entry.
class ExportViewModel extends ChangeNotifier {
  final PdfReportService _pdfService;
  final StorageService _storageService;
  final AnalyticsService _analytics;

  ExportViewModel({
    PdfReportService? pdfService,
    StorageService? storageService,
    AnalyticsService? analytics,
  })  : _pdfService = pdfService ?? PdfReportService(),
        _storageService = storageService ?? StorageService(),
        _analytics = analytics ?? AnalyticsService();

  ExportState _state = ExportState.idle;
  ExportState get state => _state;

  String? _downloadUrl;
  String? get downloadUrl => _downloadUrl;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ExportState.loading;
  bool get isSuccess => _state == ExportState.success;
  bool get isError => _state == ExportState.error;

  Future<void> exportReport({
    required DashboardStats stats,
    required List<YearlyTrend> yearlyTrends,
    required List<TopJournal> topJournals,
    required List<TopAuthor> topAuthors,
    required List<Keyword> topKeywords,
  }) async {
    _state = ExportState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final bytes = await _pdfService.buildReport(
        stats: stats,
        yearlyTrends: yearlyTrends,
        topJournals: topJournals,
        topAuthors: topAuthors,
        topKeywords: topKeywords,
      );
      final fileName =
          '${_sanitize(stats.topic)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final url = await _storageService.uploadPdf(
        fileName: fileName,
        bytes: bytes,
      );
      _downloadUrl = url;
      _state = ExportState.success;
      unawaited(_analytics.logExportPdf(stats.topic));
    } catch (e) {
      _errorMessage = 'Không thể xuất báo cáo. Vui lòng thử lại.';
      _state = ExportState.error;
    }
    notifyListeners();
  }

  void reset() {
    _state = ExportState.idle;
    _downloadUrl = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _sanitize(String topic) =>
      topic.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
