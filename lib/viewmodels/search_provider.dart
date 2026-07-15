import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../services/openalex_service.dart';
import '../utils/constants.dart';

enum SearchState { initial, loading, success, error }

class SearchProvider extends ChangeNotifier {
  final OpenAlexService _service;

  SearchProvider({OpenAlexService? service})
      : _service = service ?? OpenAlexService();

  // Trạng thái hiện tại
  SearchState _state = SearchState.initial;
  SearchState get state => _state;

  // Danh sách kết quả tìm kiếm
  List<Work> _works = [];
  List<Work> get works => _works;

  // Từ khoá đang tìm
  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  // Thông báo lỗi
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Tổng số kết quả từ API (dùng hiển thị "Tìm thấy X bài báo")
  int _totalResults = 0;
  int get totalResults => _totalResults;

  // Phân trang
  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _state == SearchState.loading && _works.isNotEmpty;

  // Getters tiện ích để Widget dùng
  bool get isInitial => _state == SearchState.initial;
  bool get isLoading => _state == SearchState.loading && _works.isEmpty;
  bool get isSuccess => _state == SearchState.success;
  bool get isError => _state == SearchState.error;

  // Tìm kiếm mới (reset toàn bộ kết quả cũ)
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _currentQuery = trimmed;
    _works = [];
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    _setState(SearchState.loading);

    await _fetchWorks();
  }

  // Load thêm trang tiếp theo (infinite scroll)
  Future<void> loadMore() async {
    if (!_hasMore || _state == SearchState.loading) return;
    _currentPage++;
    _setState(SearchState.loading);
    await _fetchWorks();
  }

  Future<void> _fetchWorks() async {
    try {
      final result = await _service.searchWorks(
        query: _currentQuery,
        page: _currentPage,
        perPage: AppConstants.defaultPerPage,
      );

      final meta = result['meta'] as Map<String, dynamic>? ?? {};
      _totalResults = meta['count'] as int? ?? 0;

      final resultsJson = result['results'] as List<dynamic>? ?? [];
      final newWorks = resultsJson
          .whereType<Map<String, dynamic>>()
          .map((json) => Work.fromJson(json))
          .where((w) => w.title != 'Untitled' && w.title.isNotEmpty)
          .toList();

      _works = [..._works, ...newWorks];

      // Kiểm tra còn trang tiếp theo không
      _hasMore = newWorks.length >= AppConstants.defaultPerPage;

      _setState(SearchState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (_works.isEmpty) {
        _setState(SearchState.error);
      } else {
        // Đang load more mà lỗi → giữ kết quả cũ, chỉ báo lỗi
        _currentPage--;
        _hasMore = false;
        _setState(SearchState.success);
      }
    }
  }

  void reset() {
    _state = SearchState.initial;
    _works = [];
    _currentQuery = '';
    _errorMessage = null;
    _totalResults = 0;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  void _setState(SearchState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
