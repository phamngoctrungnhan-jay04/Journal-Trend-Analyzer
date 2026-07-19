import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../services/openalex_service.dart';
import '../firebase/analytics_service.dart';
import '../utils/constants.dart';

enum AuthorWorksState { loading, success, error }

// ViewModel scoped riêng cho AuthorWorksScreen (danh sách bài báo của 1 tác
// giả cụ thể) — tạo mới mỗi lần vào màn hình, tự dispose khi rời, giống
// VolumeWorksViewModel/KeywordWorksViewModel.
class AuthorWorksViewModel extends ChangeNotifier {
  final OpenAlexService _service;
  final AnalyticsService _analytics;

  AuthorWorksViewModel({OpenAlexService? service, AnalyticsService? analytics})
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

  AuthorWorksState _state = AuthorWorksState.loading;
  AuthorWorksState get state => _state;

  List<Work> _works = [];
  List<Work> get works => _works;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == AuthorWorksState.loading;
  bool get isError => _state == AuthorWorksState.error;

  Future<void> load({
    required String authorId,
    int papersPerPage = AppConstants.journalWorksPerPage,
  }) async {
    _state = AuthorWorksState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getWorksByAuthor(
        authorId: authorId,
        perPage: papersPerPage,
      );
      final worksJson = result['results'] as List<dynamic>? ?? [];
      _works = worksJson
          .whereType<Map<String, dynamic>>()
          .map((j) => Work.fromJson(j))
          .toList();
      _state = AuthorWorksState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthorWorksState.error;
    } catch (e) {
      // Bắt mọi lỗi ngoài dự kiến (vd parse JSON hỏng). Không có nhánh này thì
      // lỗi thoát khỏi load() mà không ai bắt -> _state kẹt ở loading và màn
      // hình quay spinner vĩnh viễn thay vì báo lỗi cho user.
      _errorMessage = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
      _state = AuthorWorksState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
