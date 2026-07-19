// OpenAlex bắt buộc TẤT CẢ từ trong câu tìm phải cùng khớp 1 chủ đề, kể cả
// với filter quét rộng (text.search) — gõ "Vietnamese agriculture" ra 0 kết
// quả dù mỗi từ riêng lẻ đều có hàng chục/hàng trăm chủ đề liên quan (kiểm
// chứng trực tiếp qua API thật). searchTopics xử lý bằng cách OR từng từ rồi
// xếp hạng lại theo số từ trùng ở client. Bộ test này khoá lại đúng 2 phần:
// URI OR đúng cú pháp, và thứ tự xếp hạng đúng logic.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';

void main() {
  test('câu tìm nhiều từ -> filter OR từng từ, không AND nguyên câu', () async {
    Uri? capturedUri;
    final client = MockClient((request) async {
      capturedUri = request.url;
      return http.Response(jsonEncode({'results': []}), 200);
    });
    final service = OpenAlexService(client: client);

    await service.searchTopics(query: 'Vietnamese agriculture');

    expect(capturedUri, isNotNull);
    expect(
      capturedUri!.queryParameters['filter'],
      'text.search:Vietnamese|agriculture',
    );
  });

  test('chủ đề khớp nhiều từ hơn xếp trên chủ đề chỉ khớp 1 từ', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'results': [
            // Chỉ khớp "agriculture" (1/2 từ), works_count rất cao.
            {
              'id': 'https://openalex.org/T1',
              'display_name': 'Remote Sensing in Agriculture',
              'works_count': 999999,
            },
            // Khớp cả 2 từ, works_count thấp hơn hẳn -> vẫn phải lên đầu.
            {
              'id': 'https://openalex.org/T2',
              'display_name': 'Vietnamese Agriculture Economics',
              'works_count': 10,
            },
            // Không khớp từ nào trong display_name.
            {
              'id': 'https://openalex.org/T3',
              'display_name': 'Unrelated Legal Topic',
              'works_count': 500,
            },
          ],
        }),
        200,
      );
    });
    final service = OpenAlexService(client: client);

    final result = await service.searchTopics(query: 'Vietnamese agriculture');
    final names = (result['results'] as List)
        .cast<Map<String, dynamic>>()
        .map((t) => t['display_name'])
        .toList();

    expect(names, [
      'Vietnamese Agriculture Economics',
      'Remote Sensing in Agriculture',
      'Unrelated Legal Topic',
    ]);
  });

  test('hoà điểm số từ trùng -> ưu tiên works_count cao hơn', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'results': [
            {
              'id': 'https://openalex.org/T1',
              'display_name': 'Blockchain in Education',
              'works_count': 100,
            },
            {
              'id': 'https://openalex.org/T2',
              'display_name': 'Blockchain Security',
              'works_count': 50000,
            },
          ],
        }),
        200,
      );
    });
    final service = OpenAlexService(client: client);

    final result = await service.searchTopics(query: 'blockchain');
    final names = (result['results'] as List)
        .cast<Map<String, dynamic>>()
        .map((t) => t['display_name'])
        .toList();

    expect(names, ['Blockchain Security', 'Blockchain in Education']);
  });

  test('query rỗng sau khi lọc từ ngắn -> trả rỗng, không gọi API', () async {
    var apiCalled = false;
    final client = MockClient((request) async {
      apiCalled = true;
      return http.Response(jsonEncode({'results': []}), 200);
    });
    final service = OpenAlexService(client: client);

    final result = await service.searchTopics(query: 'a');

    expect(result['results'], isEmpty);
    expect(apiCalled, isFalse);
  });
}
