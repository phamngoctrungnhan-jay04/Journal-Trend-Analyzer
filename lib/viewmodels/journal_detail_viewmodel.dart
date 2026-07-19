import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/journal.dart';
import '../models/work.dart';
import '../models/research_scope.dart';
import '../services/openalex_service.dart';
import '../firebase/analytics_service.dart';
import '../utils/constants.dart';

enum JournalDetailState { loading, success, error }

// ViewModel scoped riêng cho JournalDetailScreen (không đăng ký vào
// MultiProvider toàn app - tạo mới mỗi lần vào màn hình, tự dispose khi rời).
//
// scope null khi user vào đây từ JournalSearchField (tìm journal trực tiếp,
// không qua chọn lĩnh vực) — getWorksByJournal khi đó chỉ còn lọc theo
// journal, danh sách "Bài nổi bật" là CẢ journal chứ không giới hạn 1 lĩnh
// vực.
class JournalDetailViewModel extends ChangeNotifier {
  final OpenAlexService _service;
  final AnalyticsService _analytics;

  JournalDetailViewModel({
    OpenAlexService? service,
    AnalyticsService? analytics,
  }) : _service = service ?? OpenAlexService(),
       _analytics = analytics ?? AnalyticsService();

  void logViewPublication(Work work) {
    unawaited(
      _analytics.logViewPublication(
        title: work.title,
        year: work.publicationYear,
      ),
    );
  }

  JournalDetailState _state = JournalDetailState.loading;
  JournalDetailState get state => _state;

  JournalDetail? _detail;
  JournalDetail? get detail => _detail;

  List<Work> _works = [];
  List<Work> get works => _works;

  List<JournalVolume> _volumes = [];
  List<JournalVolume> get volumes => _volumes;

  List<YearlyTrend> _yearlyTrends = [];
  List<YearlyTrend> get yearlyTrends => _yearlyTrends;

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

  Future<void> load({
    ResearchScope? scope,
    required String journalId,
    int papersPerPage = AppConstants.journalWorksPerPage,
  }) async {
    _state = JournalDetailState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cần last_publication_year của CHÍNH journal này trước khi tính "volume
      // gần đây" -> không gộp chung Future.wait với volumes ngay từ đầu:
      // journal ngừng xuất bản lâu rồi mà cứng "năm hiện tại - N" thì cửa sổ
      // rơi vào khoảng trống, ra 0 volume dù journal có hàng trăm volume cũ.
      final detailJson = await _service.getJournalById(journalId);
      final detail = JournalDetail.fromJson(detailJson);
      final minYear =
          (detail.lastPublicationYear ?? DateTime.now().year) -
          AppConstants.recentVolumesWindowYears +
          1;

      final results = await Future.wait([
        _service.getRecentVolumes(journalId: journalId, minYear: minYear),
        _service.getWorksByJournal(
          scope: scope,
          journalId: journalId,
          perPage: papersPerPage,
        ),
        _service.getJournalYearlyTrend(journalId: journalId),
      ]);

      final volumeGroups = results[0]['group_by'] as List<dynamic>? ?? [];
      _volumes =
          volumeGroups
              .whereType<Map<String, dynamic>>()
              .map((j) => JournalVolume.fromGroupByJson(j))
              .where((v) => v.volume.isNotEmpty)
              .toList()
            ..sort(_compareVolumesDesc);

      final worksJson = results[1]['results'] as List<dynamic>? ?? [];
      _works = worksJson
          .whereType<Map<String, dynamic>>()
          .map((j) => Work.fromJson(j))
          .toList();

      final yearGroups = results[2]['group_by'] as List<dynamic>? ?? [];
      _yearlyTrends =
          yearGroups
              .whereType<Map<String, dynamic>>()
              .map((j) => YearlyTrend.fromGroupByJson(j))
              .where((t) => t.year >= 1990 && t.year <= DateTime.now().year)
              .toList()
            ..sort((a, b) => a.year.compareTo(b.year));

      _detail = detail;
      _state = JournalDetailState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = JournalDetailState.error;
    } catch (e) {
      // Bắt mọi lỗi ngoài dự kiến (vd parse JSON hỏng). Không có nhánh này thì
      // lỗi thoát khỏi load() mà không ai bắt -> _state kẹt ở loading và màn
      // hình quay spinner vĩnh viễn thay vì báo lỗi cho user.
      _errorMessage = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
      _state = JournalDetailState.error;
    }
    notifyListeners();
  }

  // Volume mới nhất (số lớn nhất) lên đầu. Volume không phải số (vd "Suppl
  // 1") -> đẩy xuống cuối thay vì làm sort so sánh sai hoặc ném lỗi.
  int _compareVolumesDesc(JournalVolume a, JournalVolume b) {
    final an = a.numericVolume;
    final bn = b.numericVolume;
    if (an == null && bn == null) return 0;
    if (an == null) return 1;
    if (bn == null) return -1;
    return bn.compareTo(an);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
