import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../services/openalex_service.dart';
import '../utils/constants.dart';
import '../firebase/analytics_service.dart';

enum KeywordWorksState { loading, success, error }

// ViewModel scoped riêng cho KeywordWorksScreen (danh sách bài báo khớp 1
// filter cụ thể — có thể là 1 keyword liên quan (keywords.id:X) hoặc chính
// câu tìm người dùng vừa phân tích (matchFilter từ resolveKeywordQuery,
// keywords.id:X hoặc default.search:X)) — tạo mới mỗi lần vào màn hình, tự
// dispose khi rời, giống VolumeWorksViewModel.
class KeywordWorksViewModel extends ChangeNotifier {
  final OpenAlexService _service;
  final AnalyticsService _analytics;

  KeywordWorksViewModel({OpenAlexService? service, AnalyticsService? analytics})
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

  KeywordWorksState _state = KeywordWorksState.loading;
  KeywordWorksState get state => _state;

  List<Work> _works = [];
  List<Work> get works => _works;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == KeywordWorksState.loading;
  bool get isError => _state == KeywordWorksState.error;

  Future<void> load({
    required String matchFilter,
    int papersPerPage = AppConstants.journalWorksPerPage,
  }) async {
    _state = KeywordWorksState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.analyzeKeywordTopWorks(
        matchFilter: matchFilter,
        perPage: papersPerPage,
      );
      final worksJson = result['results'] as List<dynamic>? ?? [];
      _works = worksJson
          .whereType<Map<String, dynamic>>()
          .map((j) => Work.fromJson(j))
          .toList();
      _state = KeywordWorksState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = KeywordWorksState.error;
    } catch (e) {
      // Bắt mọi lỗi ngoài dự kiến (vd parse JSON hỏng). Không có nhánh này thì
      // lỗi thoát khỏi load() mà không ai bắt -> _state kẹt ở loading và màn
      // hình quay spinner vĩnh viễn thay vì báo lỗi cho user.
      _errorMessage = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
      _state = KeywordWorksState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
