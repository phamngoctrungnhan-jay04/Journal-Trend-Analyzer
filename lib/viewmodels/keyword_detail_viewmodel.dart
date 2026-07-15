import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../models/author.dart';
import '../services/openalex_service.dart';

enum KeywordDetailState { loading, success, error }

// ViewModel scoped riêng cho KeywordDetailScreen (không đăng ký vào
// MultiProvider toàn app - tạo mới mỗi lần vào màn hình, tự dispose khi rời).
class KeywordDetailViewModel extends ChangeNotifier {
  final OpenAlexService _service;

  KeywordDetailViewModel({OpenAlexService? service})
      : _service = service ?? OpenAlexService();

  KeywordDetailState _state = KeywordDetailState.loading;
  KeywordDetailState get state => _state;

  List<YearlyTrend> _yearlyTrends = [];
  List<YearlyTrend> get yearlyTrends => _yearlyTrends;

  List<TopAuthor> _topAuthors = [];
  List<TopAuthor> get topAuthors => _topAuthors;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == KeywordDetailState.loading;
  bool get isError => _state == KeywordDetailState.error;

  Future<void> load({required String query, required String keywordId}) async {
    _state = KeywordDetailState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getKeywordYearlyTrend(query: query, keywordId: keywordId),
        _service.getKeywordTopAuthors(query: query, keywordId: keywordId),
      ]);

      final yearGroups = results[0]['group_by'] as List<dynamic>? ?? [];
      _yearlyTrends = yearGroups
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

      _state = KeywordDetailState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = KeywordDetailState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
