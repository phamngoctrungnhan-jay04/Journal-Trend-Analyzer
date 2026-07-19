import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';

import 'common/pump_app.dart';

void main() {
  appTest(
    'TC10 - Remote Config giới hạn số journal hiển thị (max_journals_displayed)',
    ($) async {
      await pumpAuthenticatedApp($);

      await $(const Key('nav_journals')).tap();
      await loadJournalsScope($);

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

  appTest(
    'TC10b - Chỉnh max_papers_displayed bằng slider ở Profile, giới hạn số bài báo hiển thị',
    ($) async {
      await pumpAuthenticatedApp($);

      await $(const Key('nav_profile')).tap();
      final profileList = find.byKey(const Key('profile_list'));
      final sliderKey = find.byKey(const Key('max_papers_slider'));
      await scrollToKey($, const Key('max_papers_slider'), view: profileList);

      // Kéo hết cỡ sang trái để chốt về giá trị NHỎ NHẤT (5) — deterministic,
      // không cần tính pixel chính xác theo vị trí hiện tại của thumb (không
      // biết trước giá trị mặc định đang fetch từ Remote Config là bao
      // nhiêu). Slider tự clamp về min khi kéo vượt quá phạm vi track.
      await $.tester.drag(sliderKey, const Offset(-1000, 0));
      await $.tester.pump();

      await $(
        const Key('reset_max_papers_button'),
      ).waitUntilVisible(timeout: searchTimeout);
      expect($('Số bài báo hiển thị tối đa: 5'), findsOneWidget);

      // Mở 1 journal, xác nhận tab "Bài nổi bật" hiển thị đúng 5 bài — chứng
      // minh override từ slider (không phải giá trị Remote Config gốc) đã
      // thực sự được JournalDetailScreen áp dụng.
      await $(const Key('nav_journals')).tap();
      await loadJournalsScope($);
      await scrollToKey(
        $,
        const Key('ranked_item_1'),
        view: find.byKey(const Key('journals_results_list')),
      );
      await $(const Key('ranked_item_1')).tap();
      await $('Bài nổi bật').waitUntilVisible(timeout: searchTimeout);
      await $('Bài nổi bật').tap();

      // journal_publication_card_$index đánh số từ 0 -> item cuối cùng có
      // index 4 (5 bài). TabBarView giữ cả 3 tab tồn tại trong cây nên phải
      // chỉ đích danh Scrollable của tab "Bài nổi bật".
      final featuredWorksList = find.byKey(
        const Key('journal_featured_works_list'),
      );
      await scrollToKey(
        $,
        const Key('journal_publication_card_4'),
        view: featuredWorksList,
      );
      expect($(const Key('journal_publication_card_4')), findsOneWidget);
      expect($(const Key('journal_publication_card_5')), findsNothing);

      // Dọn dẹp: override lưu qua SharedPreferences nên TỒN TẠI XUYÊN SUỐT
      // trên máy (khác state trong RAM tự reset mỗi appTest) — nếu không
      // khôi phục mặc định ở đây, các lần chạy patrol test SAU trên cùng máy
      // sẽ luôn bị kẹt ở giới hạn 5 bài.
      await $(const Key('nav_profile')).tap();
      await scrollToKey(
        $,
        const Key('reset_max_papers_button'),
        view: profileList,
      );
      await $(const Key('reset_max_papers_button')).tap();
    },
  );
}
