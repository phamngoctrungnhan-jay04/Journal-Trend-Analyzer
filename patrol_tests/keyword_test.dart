import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/pump_app.dart';

void main() {
  appTest('TC6 - Xem danh sách Top từ khoá nghiên cứu', ($) async {
    await pumpAuthenticatedApp($);
    await searchTopic($);

    await $(const Key('nav_keywords')).tap();

    await $('Top từ khoá nghiên cứu').waitUntilVisible(timeout: searchTimeout);
    await scrollToKey($, const Key('ranked_item_1'));
    expect($(const Key('ranked_item_1')), findsOneWidget);
  });

  appTest('TC7 - Xem chi tiết 1 keyword (trend + top tác giả)', ($) async {
    await pumpAuthenticatedApp($);
    await searchTopic($);

    await $(const Key('nav_keywords')).tap();
    await $('Top từ khoá nghiên cứu').waitUntilVisible(timeout: searchTimeout);
    await scrollToKey($, const Key('ranked_item_1'));
    await $(const Key('ranked_item_1')).tap();

    await $('Top tác giả đóng góp nhiều nhất')
        .waitUntilVisible(timeout: searchTimeout);
    expect($('Top tác giả đóng góp nhiều nhất'), findsOneWidget);
  });
}
