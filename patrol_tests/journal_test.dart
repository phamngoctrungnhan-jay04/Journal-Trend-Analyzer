import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/pump_app.dart';

void main() {
  appTest('TC4 - Xem danh sách Top tạp chí nghiên cứu', ($) async {
    await pumpAuthenticatedApp($);
    await searchTopic($);

    await $(const Key('nav_journals')).tap();

    // Tiêu đề hiện ở đầu màn khi RankedBarList đã có dữ liệu (state success).
    await $('Top tạp chí nghiên cứu').waitUntilVisible(timeout: searchTimeout);
    // Item đầu nằm dưới biểu đồ bar, cuộn tới mới visible (JournalsScreen chỉ
    // có 1 Scrollable nên scrollTo tự nhận đúng).
    await scrollToKey($, const Key('ranked_item_1'));
    expect($(const Key('ranked_item_1')), findsOneWidget);
  });

  appTest('TC5 - Xem chi tiết 1 journal (bài báo + thống kê)', ($) async {
    await pumpAuthenticatedApp($);
    await searchTopic($);

    await $(const Key('nav_journals')).tap();
    await $('Top tạp chí nghiên cứu').waitUntilVisible(timeout: searchTimeout);
    await scrollToKey($, const Key('ranked_item_1'));
    await $(const Key('ranked_item_1')).tap();

    await $('Số bài báo').waitUntilVisible(timeout: searchTimeout);
    expect($('Số bài báo'), findsOneWidget);
    expect($('TB trích dẫn'), findsOneWidget);
  });
}
