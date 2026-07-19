import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/pump_app.dart';

void main() {
  appTest('TC4 - Xem danh sách Top tạp chí nghiên cứu', ($) async {
    await pumpAuthenticatedApp($);

    await $(const Key('nav_journals')).tap();
    await loadJournalsScope($);

    // Item đầu nằm dưới biểu đồ bar, cuộn tới mới visible. Chỉ đích danh view
    // = journals_results_list — mặc định (không truyền view) scrollTo lấy
    // Scrollable ĐẦU TIÊN tìm thấy trong TOÀN app (find.byType(Scrollable)),
    // có thể trúng nhầm Scrollable của tab khác đang được IndexedStack giữ
    // sống ngầm (MainShell), khiến cuộn sai chỗ và không bao giờ thấy item.
    final journalsList = find.byKey(const Key('journals_results_list'));
    await scrollToKey($, const Key('ranked_item_1'), view: journalsList);
    expect($(const Key('ranked_item_1')), findsOneWidget);
  });

  appTest('TC5 - Xem chi tiết 1 journal (bài báo + thống kê)', ($) async {
    await pumpAuthenticatedApp($);

    await $(const Key('nav_journals')).tap();
    await loadJournalsScope($);
    await scrollToKey(
      $,
      const Key('ranked_item_1'),
      view: find.byKey(const Key('journals_results_list')),
    );
    await $(const Key('ranked_item_1')).tap();

    await $('Tổng bài báo').waitUntilVisible(timeout: searchTimeout);
    expect($('Tổng bài báo'), findsOneWidget);
    expect($('TB trích dẫn'), findsOneWidget);
    expect($('Xu hướng'), findsOneWidget);
    expect($('Volumes'), findsOneWidget);
    expect($('Bài nổi bật'), findsOneWidget);

    // Quay lại Journals, thử lại y hệt bằng chế độ "Tìm tạp chí" (gõ tên trực
    // tiếp, không qua chọn lĩnh vực) — JournalsScreen có 2 chế độ tìm độc lập
    // (journals_mode_toggle), chế độ này trước đây chưa được thử ở đây.
    await $(find.byType(BackButton)).tap();
    await $('Tìm tạp chí').tap();

    await $(const Key('journal_search_field')).enterText('Nature');
    await waitFirstWithKeyPrefix($, 'journal_suggestion_');
    await tapFirstWithKeyPrefix($, 'journal_suggestion_');

    // Chế độ này vào thẳng JournalDetailScreen với scope null (không qua
    // lĩnh vực) nhưng vẫn cùng 1 màn chi tiết, đủ 3 tab như trên.
    await $('Tổng bài báo').waitUntilVisible(timeout: searchTimeout);
    expect($('Tổng bài báo'), findsOneWidget);
    expect($('TB trích dẫn'), findsOneWidget);
    expect($('Xu hướng'), findsOneWidget);
    expect($('Volumes'), findsOneWidget);
    expect($('Bài nổi bật'), findsOneWidget);
  });
}
