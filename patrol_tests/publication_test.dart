import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/pump_app.dart';

void main() {
  appTest('TC2 - Tìm kiếm chủ đề hiển thị danh sách bài báo', ($) async {
    await pumpAuthenticatedApp($);
    await loadHomeScope($);

    // Danh sách bài báo nằm ở tab con "Bài báo" (Home có 3 tab: Tổng quan/
    // Xu hướng/Bài báo, mỗi tab 1 Scrollable riêng).
    await $('Bài báo').tap();
    await scrollToKey(
      $,
      const Key('publication_card_0'),
      view: find.byKey(const Key('publications_list')),
    );
    expect($(const Key('publication_card_0')), findsOneWidget);
  });

  appTest('TC3 - Xem chi tiết bài báo từ kết quả tìm kiếm', ($) async {
    await pumpAuthenticatedApp($);
    await loadHomeScope($);

    await $('Bài báo').tap();
    await scrollToKey(
      $,
      const Key('publication_card_0'),
      view: find.byKey(const Key('publications_list')),
    );
    await $(const Key('publication_card_0')).tap();

    await $('Chi tiết bài báo').waitUntilVisible();
    expect($('Chi tiết bài báo'), findsOneWidget);
    expect($('Tác giả'), findsWidgets);
  });
}
