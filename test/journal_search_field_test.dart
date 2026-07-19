// Cùng bộ hành vi với taxonomy_search_field_test.dart (dùng chung
// EntitySearchField) — khoá lại 3 trạng thái phản hồi bắt buộc và việc chọn
// xong trả đúng TopJournal (qua JournalSuggestion.toTopJournal()).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analyzer/models/journal.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';
import 'package:journal_trend_analyzer/widgets/journal_search_field.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

OpenAlexService _serviceReturning(Map<String, dynamic> body) {
  final client = MockClient(
    (request) async => http.Response(jsonEncode(body), 200),
  );
  return OpenAlexService(client: client);
}

void main() {
  testWidgets('chưa gõ gì -> không hiện thông báo nào', (tester) async {
    await tester.pumpWidget(_wrap(JournalSearchField(onSelected: (_) {})));

    expect(find.byKey(const Key('journal_search_hint')), findsNothing);
    expect(find.byKey(const Key('journal_search_empty')), findsNothing);
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
        JournalSearchField(
          onSelected: (_) {},
          service: OpenAlexService(client: client),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('journal_search_field')), 'na');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal_search_hint')), findsOneWidget);
    expect(apiCalled, isFalse);
  });

  testWidgets(
    'gõ đủ ký tự nhưng không có tạp chí khớp -> hiện thông báo không tìm thấy',
    (tester) async {
      final service = _serviceReturning({'results': []});

      await tester.pumpWidget(
        _wrap(JournalSearchField(onSelected: (_) {}, service: service)),
      );

      await tester.enterText(
        find.byKey(const Key('journal_search_field')),
        'Khong Ton Tai Nao',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byKey(const Key('journal_search_empty')), findsOneWidget);
    },
  );

  testWidgets('gõ đủ ký tự có kết quả -> chọn được, trả đúng TopJournal', (
    tester,
  ) async {
    final service = _serviceReturning({
      'results': [
        {
          'id': 'https://openalex.org/S137773608',
          'display_name': 'Nature',
          'works_count': 449153,
          'host_organization_name': 'Nature Portfolio',
        },
      ],
    });

    TopJournal? selected;
    await tester.pumpWidget(
      _wrap(
        JournalSearchField(onSelected: (j) => selected = j, service: service),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('journal_search_field')),
      'nature',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(
      find.byKey(const Key('journal_suggestion_S137773608')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('journal_suggestion_S137773608')));
    await tester.pump();

    expect(selected?.id, 'S137773608');
    expect(selected?.displayName, 'Nature');
    expect(selected?.worksCount, 449153);
  });
}
