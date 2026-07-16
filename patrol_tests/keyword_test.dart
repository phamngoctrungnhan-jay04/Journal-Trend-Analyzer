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

  // Chứng minh đã bỏ ràng buộc "phải search ở Home trước": vào thẳng tab
  // Keywords, dùng ô search RIÊNG của tab này, dữ liệu vẫn nạp bình thường.
  appTest('TC12 - Tìm chủ đề trực tiếp ở tab Keywords (không qua Home)', ($) async {
    await pumpAuthenticatedApp($);

    await $(const Key('nav_keywords')).tap();
    await $(const Key('keywords_search_field')).enterText('Machine Learning');
    await $(const Key('keywords_search_button')).tap();

    await $('Top từ khoá nghiên cứu').waitUntilVisible(timeout: searchTimeout);
    await scrollToKey($, const Key('ranked_item_1'));
    expect($(const Key('ranked_item_1')), findsOneWidget);
  });
}
