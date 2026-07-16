import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../services/openalex_service.dart';
import '../firebase/analytics_service.dart';

enum JournalDetailState { loading, success, error }

// ViewModel scoped riêng cho JournalDetailScreen (không đăng ký vào
// MultiProvider toàn app - tạo mới mỗi lần vào màn hình, tự dispose khi rời).
class JournalDetailViewModel extends ChangeNotifier {
  final OpenAlexService _service;
  final AnalyticsService _analytics;

  JournalDetailViewModel({OpenAlexService? service, AnalyticsService? analytics})
      : _service = service ?? OpenAlexService(),
        _analytics = analytics ?? AnalyticsService();

  void logViewPublication(Work work) {
    unawaited(_analytics.logViewPublication(
      title: work.title,
      year: work.publicationYear,
    ));
  }

  JournalDetailState _state = JournalDetailState.loading;
  JournalDetailState get state => _state;

  List<Work> _works = [];
  List<Work> get works => _works;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == JournalDetailState.loading;
  bool get isError => _state == JournalDetailState.error;

  // Trung bình trích dẫn ước lượng từ danh sách đã tải (cùng cách tiếp cận
  // AnalysisProvider đang dùng cho avg citation của toàn topic).
  double get averageCitation {
    if (_works.isEmpty) return 0;
    final total = _works.fold<int>(0, (sum, w) => sum + w.citedByCount);
    return total / _works.length;
  }

  Future<void> load({required String query, required String journalId}) async {
    _state = JournalDetailState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getWorksByJournal(
        query: query,
        journalId: journalId,
      );
      final worksJson = result['results'] as List<dynamic>? ?? [];
      _works = worksJson
          .whereType<Map<String, dynamic>>()
          .map((j) => Work.fromJson(j))
          .toList();
      _state = JournalDetailState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = JournalDetailState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
