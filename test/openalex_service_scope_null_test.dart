// JournalDetailScreen giờ nhận scope null khi user vào từ JournalSearchField
// (tìm journal trực tiếp, không qua chọn lĩnh vực). Bộ test này khoá lại
// đúng 2 chiều: scope null -> filter KHÔNG có primary_topic (không giới hạn
// lĩnh vực); scope khác null -> filter VẪN có primary_topic (không phá luồng
// cũ — Journals tab theo lĩnh vực và Home vẫn phải lọc đúng phạm vi).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analyzer/models/research_scope.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';

void main() {
  test('scope null -> getWorksByJournal không lọc theo lĩnh vực', () async {
    Uri? capturedUri;
    final client = MockClient((request) async {
      capturedUri = request.url;
      return http.Response(jsonEncode({'results': []}), 200);
    });
    final service = OpenAlexService(client: client);

    await service.getWorksByJournal(journalId: 'S137773608');

    final filter = capturedUri!.queryParameters['filter']!;
    expect(filter, isNot(contains('primary_topic')));
    expect(filter, contains('primary_location.source.id:S137773608'));
    expect(filter, contains('type:article'));
  });

  test('có scope -> getWorksByJournal vẫn lọc đúng lĩnh vực', () async {
    Uri? capturedUri;
    final client = MockClient((request) async {
      capturedUri = request.url;
      return http.Response(jsonEncode({'results': []}), 200);
    });
    final service = OpenAlexService(client: client);
    const scope = ResearchScope.field(id: '17', label: 'Computer Science');

    await service.getWorksByJournal(scope: scope, journalId: 'S137773608');

    final filter = capturedUri!.queryParameters['filter']!;
    expect(filter, contains('primary_topic.field.id:17'));
    expect(filter, contains('primary_location.source.id:S137773608'));
  });
}
