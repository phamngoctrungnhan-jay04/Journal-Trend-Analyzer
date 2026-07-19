// Trước đây khi user gõ chủ đề mà OpenAlex không trả gợi ý nào (vd gõ tiếng
// Việt, tên tác giả, hoặc chưa đủ ký tự), ô tìm kiếm im lặng hoàn toàn — user
// không phân biệt được "app đang đơ" với "không có chủ đề nào khớp". Bộ test
// này khoá lại 3 trạng thái phản hồi bắt buộc phải có.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analyzer/models/research_scope.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';
import 'package:journal_trend_analyzer/widgets/taxonomy_search_field.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

OpenAlexService _serviceReturning(Map<String, dynamic> body) {
  final client = MockClient(
    (request) async => http.Response(jsonEncode(body), 200),
  );
  return OpenAlexService(client: client);
}

void main() {
  testWidgets('chưa gõ gì -> không hiện thông báo nào', (tester) async {
    await tester.pumpWidget(_wrap(TaxonomySearchField(onSelected: (_) {})));

    expect(find.byKey(const Key('taxonomy_search_hint')), findsNothing);
    expect(find.byKey(const Key('taxonomy_search_empty')), findsNothing);
  });

  testWidgets('gõ dưới ngưỡng ký tự -> hiện gợi ý nhập thêm, không gọi API', (
    tester,
  ) async {
    var apiCalled = false;
    final client = MockClient((request) async {
      apiCalled = true;
      return http.Response(jsonEncode({'results': []}), 200);
    });

    await tester.pumpWidget(
      _wrap(
        TaxonomySearchField(
          onSelected: (_) {},
          service: OpenAlexService(client: client),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('taxonomy_search_field')),
      'ai',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('taxonomy_search_hint')), findsOneWidget);
    expect(apiCalled, isFalse);
  });

  testWidgets(
    'gõ đủ ký tự nhưng không có chủ đề khớp -> hiện thông báo không tìm thấy',
    (tester) async {
      final service = _serviceReturning({'results': []});

      await tester.pumpWidget(
        _wrap(TaxonomySearchField(onSelected: (_) {}, service: service)),
      );

      await tester.enterText(
        find.byKey(const Key('taxonomy_search_field')),
        'Nguyễn Văn A',
      );
      // Bơm quá 350ms debounce cho Timer kịp nổ, rồi bơm thêm để flush Future
      // của MockClient (không tự sinh frame mới nên pumpAndSettle không đủ).
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byKey(const Key('taxonomy_search_empty')), findsOneWidget);
      expect(find.byKey(const Key('taxonomy_search_hint')), findsNothing);
    },
  );

  testWidgets('gõ đủ ký tự có kết quả -> hiện danh sách gợi ý, chọn được', (
    tester,
  ) async {
    final service = _serviceReturning({
      'results': [
        {
          'id': 'https://openalex.org/T10270',
          'display_name': 'Blockchain Technology Applications and Security',
          'subfield': {'display_name': 'Information Systems'},
          'field': {'display_name': 'Computer Science'},
          'works_count': 51340,
        },
      ],
    });

    ResearchScope? selected;
    await tester.pumpWidget(
      _wrap(
        TaxonomySearchField(onSelected: (s) => selected = s, service: service),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('taxonomy_search_field')),
      'blockchain',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.byKey(const Key('taxonomy_search_empty')), findsNothing);
    expect(find.byKey(const Key('topic_suggestion_T10270')), findsOneWidget);

    await tester.tap(find.byKey(const Key('topic_suggestion_T10270')));
    await tester.pump();

    expect(selected?.filterFragment, 'primary_topic.id:T10270');
  });
}
