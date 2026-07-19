// getRecentVolumes group_by mặc định xếp theo SỐ BÀI nhiều nhất, không phải
// volume mới nhất (kiểm chứng qua API thật — xem comment trong
// openalex_service.dart). JournalDetailViewModel phải tự sắp lại theo số
// volume giảm dần, đẩy volume không phải số xuống cuối. Bộ test này mock cả
// 3 lệnh gọi (getJournalById, getRecentVolumes, getWorksByJournal) để khoá
// lại thứ tự đó mà không cần mạng thật.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analyzer/firebase/analytics_service.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';
import 'package:journal_trend_analyzer/viewmodels/journal_detail_viewmodel.dart';

// AnalyticsService() mặc định gọi FirebaseAnalytics.instance -> đụng
// Firebase.app() và crash trong unit test thuần (không có
// TestWidgetsFlutterBinding/Firebase mock). implements (không extends) nên
// không bao giờ chạm constructor thật của AnalyticsService.
class _NoopAnalyticsService implements AnalyticsService {
  @override
  Future<void> logExportPdf(String topic) async {}
  @override
  Future<void> logLogin() async {}
  @override
  Future<void> logLogout() async {}
  @override
  Future<void> logSearchTopic(String keyword) async {}
  @override
  Future<void> logViewJournal(String name) async {}
  @override
  Future<void> logViewKeyword(String keyword) async {}
  @override
  Future<void> logViewPublication({
    required String title,
    required int? year,
  }) async {}
}

http.Client _mockClient({
  required Map<String, dynamic> detailJson,
  required List<Map<String, dynamic>> volumeGroups,
  required List<Map<String, dynamic>> works,
}) {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.contains('/sources/')) {
      return http.Response(jsonEncode(detailJson), 200);
    }
    if (request.url.queryParameters['group_by'] == 'biblio.volume') {
      return http.Response(jsonEncode({'group_by': volumeGroups}), 200);
    }
    return http.Response(jsonEncode({'results': works}), 200);
  });
}

void main() {
  test('volumes sắp xếp giảm dần theo số, volume chữ đẩy xuống cuối', () async {
    final client = _mockClient(
      detailJson: {
        'id': 'https://openalex.org/S137773608',
        'display_name': 'Nature',
        'host_organization_name': 'Nature Portfolio',
        'works_count': 449153,
        'cited_by_count': 27085623,
        'summary_stats': {'h_index': 1847},
        'is_oa': false,
        'first_publication_year': 1851,
        'last_publication_year': 2026,
      },
      volumeGroups: [
        {'key': '629', 'count': 310},
        {'key': 'Suppl 1', 'count': 4},
        {'key': '634', 'count': 319},
        {'key': '632', 'count': 298},
      ],
      works: [
        {'id': 'W1', 'title': 'A', 'cited_by_count': 100},
        {'id': 'W2', 'title': 'B', 'cited_by_count': 50},
      ],
    );
    final vm = JournalDetailViewModel(
      service: OpenAlexService(client: client),
      analytics: _NoopAnalyticsService(),
    );

    await vm.load(journalId: 'S137773608');

    expect(vm.isError, isFalse);
    expect(vm.volumes.map((v) => v.volume).toList(), [
      '634',
      '632',
      '629',
      'Suppl 1',
    ]);
    expect(vm.detail?.displayName, 'Nature');
    expect(vm.detail?.hIndex, 1847);
    expect(vm.works.length, 2);
    expect(vm.averageCitation, 75.0);
  });

  test('lỗi ở bước lấy chi tiết journal -> state error', () async {
    final client = MockClient((request) async {
      return http.Response('{"error": "not found"}', 404);
    });
    final vm = JournalDetailViewModel(
      service: OpenAlexService(client: client),
      analytics: _NoopAnalyticsService(),
    );

    await vm.load(journalId: 'S_khong_ton_tai');

    expect(vm.isError, isTrue);
    expect(vm.errorMessage, isNotNull);
  });
}
