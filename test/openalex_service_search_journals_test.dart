// Cùng lý do với searchTopics (xem openalex_service_search_topics_test.dart):
// OpenAlex bắt TẤT CẢ từ trong câu tìm phải cùng khớp 1 nguồn nếu search
// nguyên câu. searchJournals dùng lại chiến lược OR-từng-từ-rồi-xếp-hạng, chỉ
// khác endpoint (/sources) và thêm filter type:journal để loại repository/
// ebook platform khỏi kết quả.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';

void main() {
  test(
    'câu tìm nhiều từ -> filter type:journal + OR từng từ trên text.search',
    () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final service = OpenAlexService(client: client);

      await service.searchJournals(query: 'nature science');

      expect(capturedUri, isNotNull);
      expect(
        capturedUri!.queryParameters['filter'],
        'type:journal,text.search:nature|science',
      );
    },
  );

  test('nguồn khớp nhiều từ hơn xếp trên nguồn chỉ khớp 1 từ', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'results': [
            {
              'id': 'https://openalex.org/S1',
              'display_name': 'Journal of Nature Studies',
              'works_count': 5000,
              'host_organization_name': 'Some Publisher',
            },
            {
              'id': 'https://openalex.org/S2',
              'display_name': 'Nature',
              'works_count': 449153,
              'host_organization_name': 'Nature Portfolio',
            },
          ],
        }),
        200,
      );
    });
    final service = OpenAlexService(client: client);

    final result = await service.searchJournals(query: 'nature');
    final names = (result['results'] as List)
        .cast<Map<String, dynamic>>()
        .map((j) => j['display_name'])
        .toList();

    // Cả 2 đều khớp "nature" (score bằng nhau) -> hoà điểm ưu tiên
    // works_count cao hơn, "Nature" (449153) phải lên trước.
    expect(names, ['Nature', 'Journal of Nature Studies']);
  });

  test('query rỗng sau khi lọc từ ngắn -> trả rỗng, không gọi API', () async {
    var apiCalled = false;
    final client = MockClient((request) async {
      apiCalled = true;
      return http.Response(jsonEncode({'results': []}), 200);
    });
    final service = OpenAlexService(client: client);

    final result = await service.searchJournals(query: 'a');

    expect(result['results'], isEmpty);
    expect(apiCalled, isFalse);
  });
}
