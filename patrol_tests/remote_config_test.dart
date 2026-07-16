import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';

import 'common/pump_app.dart';

void main() {
  appTest(
    'TC10 - Remote Config giới hạn số journal hiển thị (max_journals_displayed)',
    ($) async {
      await pumpAuthenticatedApp($);
      await searchTopic($);

      await $(const Key('nav_journals')).tap();
      await $('Top tạp chí nghiên cứu').waitUntilVisible(timeout: searchTimeout);

      // Đọc trực tiếp giá trị đã fetch/activate từ Remote Config Console -
      // đúng giá trị RemoteConfigProvider (dùng trong JournalsScreen) đã áp
      // dụng, không phải hằng số mặc định trong code.
      final remoteConfig = RemoteConfigService();
      await remoteConfig.init();
      final maxJournals = remoteConfig.maxJournalsDisplayed;

      // RankedBarList nằm trong SingleChildScrollView (không lazy) nên mọi
      // item đều tồn tại trong cây widget dù có thể ngoài màn hình -> kiểm tra
      // sự tồn tại (findsOneWidget/findsNothing) không cần cuộn.
      expect($(Key('ranked_item_$maxJournals')), findsOneWidget);
      expect($(Key('ranked_item_${maxJournals + 1}')), findsNothing);
    },
  );
}
