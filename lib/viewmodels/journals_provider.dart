import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/journal.dart';
import '../models/research_scope.dart';
import '../services/openalex_service.dart';
import '../firebase/analytics_service.dart';

enum JournalsState { initial, loading, success, error }

// Tab Journals hỗ trợ 2 kiểu tìm: theo LĨNH VỰC (FR 4.5 - xếp hạng journal
// trong 1 lĩnh vực, dùng load(scope)) hoặc tìm JOURNAL trực tiếp theo tên
// (JournalSearchField, không qua API của provider này — chọn xong push thẳng
// JournalDetailScreen). Đây chỉ là state UI cho toggle, không gọi API.
enum JournalsSearchMode { byField, byJournal }

// State của RIÊNG tab Journals — phạm vi độc lập với Home/Keywords. Chỉ gọi
// đúng 1 API (getTopJournals) và chỉ khi user thực sự chọn chủ đề ở tab này.
class JournalsProvider extends ChangeNotifier {
  final OpenAlexService _service;
  final AnalyticsService _analytics;

  JournalsProvider({OpenAlexService? service, AnalyticsService? analytics})
    : _service = service ?? OpenAlexService(),
      _analytics = analytics ?? AnalyticsService();

  JournalsSearchMode _mode = JournalsSearchMode.byField;
  JournalsSearchMode get mode => _mode;

  void setMode(JournalsSearchMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  JournalsState _state = JournalsState.initial;
  JournalsState get state => _state;

  ResearchScope? _scope;
  ResearchScope? get scope => _scope;

  List<TopJournal> _topJournals = [];
  List<TopJournal> get topJournals => _topJournals;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isInitial => _state == JournalsState.initial;
  bool get isLoading => _state == JournalsState.loading;
  bool get isError => _state == JournalsState.error;

  Future<void> load(ResearchScope scope) async {
    _scope = scope;
    _topJournals = [];
    _errorMessage = null;
    _setState(JournalsState.loading);

    try {
      final result = await _service.getTopJournals(scope: scope);
      final groups = result['group_by'] as List<dynamic>? ?? [];
      _topJournals = groups
          .whereType<Map<String, dynamic>>()
          .map((j) => TopJournal.fromGroupByJson(j))
          .where((j) => j.displayName.isNotEmpty && j.id.isNotEmpty)
          .toList();
      _setState(JournalsState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(JournalsState.error);
    } catch (e) {
      // Thiếu nhánh này thì lỗi ngoài dự kiến làm _state kẹt ở loading.
      _errorMessage = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
      _setState(JournalsState.error);
    }
  }

  Future<void> retry() async {
    final s = _scope;
    if (s != null) await load(s);
  }

  void logViewJournal(TopJournal journal) {
    unawaited(_analytics.logViewJournal(journal.displayName));
  }

  void _setState(JournalsState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
