import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/pump_app.dart';

void main() {
  appTest('TC2 - Tìm kiếm chủ đề hiển thị danh sách bài báo', ($) async {
    await pumpAuthenticatedApp($);

    await searchTopic($);

    // Card bài báo nằm dưới phần overview (stat + biểu đồ) trong list lazy,
    // phải cuộn tới nơi mới render + visible được.
    await scrollToInHomeList($, const Key('publication_card_0'));
    expect($(const Key('publication_card_0')), findsOneWidget);
  });

  appTest('TC3 - Xem chi tiết bài báo từ kết quả tìm kiếm', ($) async {
    await pumpAuthenticatedApp($);

    await searchTopic($);

    await scrollToInHomeList($, const Key('publication_card_0'));
    await $(const Key('publication_card_0')).tap();

    await $('Chi tiết bài báo').waitUntilVisible();
    expect($('Chi tiết bài báo'), findsOneWidget);
    expect($('Tác giả'), findsWidgets);
  });
}
