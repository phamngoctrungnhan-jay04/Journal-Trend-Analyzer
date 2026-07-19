import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../services/openalex_service.dart';
import '../firebase/analytics_service.dart';
import '../utils/constants.dart';

enum VolumeWorksState { loading, success, error }

// ViewModel scoped riêng cho VolumeWorksScreen (danh sách bài báo trong 1
// volume cụ thể của 1 journal) — tạo mới mỗi lần vào màn hình, tự dispose
// khi rời, giống JournalDetailViewModel.
class VolumeWorksViewModel extends ChangeNotifier {
  final OpenAlexService _service;
  final AnalyticsService _analytics;

  VolumeWorksViewModel({OpenAlexService? service, AnalyticsService? analytics})
    : _service = service ?? OpenAlexService(),
      _analytics = analytics ?? AnalyticsService();

  void logViewPublication(Work work) {
    unawaited(
      _analytics.logViewPublication(
        title: work.title,
        year: work.publicationYear,
      ),
    );
  }

  VolumeWorksState _state = VolumeWorksState.loading;
  VolumeWorksState get state => _state;

  List<Work> _works = [];
  List<Work> get works => _works;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == VolumeWorksState.loading;
  bool get isError => _state == VolumeWorksState.error;

  Future<void> load({
    required String journalId,
    required String volume,
    int papersPerPage = AppConstants.journalWorksPerPage,
  }) async {
    _state = VolumeWorksState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getWorksByVolume(
        journalId: journalId,
        volume: volume,
        perPage: papersPerPage,
      );
      final worksJson = result['results'] as List<dynamic>? ?? [];
      _works = worksJson
          .whereType<Map<String, dynamic>>()
          .map((j) => Work.fromJson(j))
          .toList();
      _state = VolumeWorksState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = VolumeWorksState.error;
    } catch (e) {
      // Bắt mọi lỗi ngoài dự kiến (vd parse JSON hỏng). Không có nhánh này thì
      // lỗi thoát khỏi load() mà không ai bắt -> _state kẹt ở loading và màn
      // hình quay spinner vĩnh viễn thay vì báo lỗi cho user.
      _errorMessage = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
      _state = VolumeWorksState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
