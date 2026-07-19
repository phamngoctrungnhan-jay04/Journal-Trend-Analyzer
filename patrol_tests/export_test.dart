import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/pump_app.dart';

// Build PDF + upload Storage thật (mạng), cần timeout rộng hơn.
const _exportTimeout = Duration(seconds: 45);

void main() {
  appTest('TC9 - Xuất báo cáo PDF và nhận URL tải về', ($) async {
    await pumpAuthenticatedApp($);
    // Cấp phiên Firebase thật (anonymous) để Storage getDownloadURL() có token
    // hợp lệ - FakeAuth chỉ fake tầng UI, không tạo phiên Firebase thật.
    await signInFirebaseAnon();

    await $(const Key('nav_profile')).tap();

    // ExportViewModel có scope RIÊNG của thẻ "Xuất báo cáo" — không còn phụ
    // thuộc scope đã chọn ở Home như kiến trúc cũ. Chọn chủ đề ngay tại đây
    // (keyPrefix mặc định 'taxonomy_search', duy nhất trên cây widget vì
    // Home/Journals đã tách sang keyPrefix riêng).
    // Thẻ "Xuất báo cáo" nằm sau thẻ "Bài báo đã lưu" trong ListView của
    // Profile (ListView build lazy theo viewport, khác SingleChildScrollView)
    // nên phải cuộn tới mới chắc chắn hit-testable. Chỉ đích danh view =
    // profile_list — mặc định scrollTo lấy Scrollable ĐẦU TIÊN trong toàn
    // app, có thể trúng nhầm tab khác (IndexedStack của MainShell vẫn giữ
    // các tab khác tồn tại ngầm).
    await scrollToKey(
      $,
      const Key('taxonomy_search_field'),
      view: find.byKey(const Key('profile_list')),
    );
    await $(const Key('taxonomy_search_field')).enterText('Machine Learning');
    await waitFirstWithKeyPrefix($, 'topic_suggestion_');
    await tapFirstWithKeyPrefix($, 'topic_suggestion_');

    // Xác nhận chủ đề đã thực sự được chọn (ExportViewModel.hasScope = true)
    // TRƯỚC khi bấm xuất — nếu bước chọn ở trên thất bại âm thầm, nút "Xuất
    // báo cáo PDF" vẫn ở trạng thái khoá (xám, onPressed: null) và bấm vào
    // sẽ không làm gì, khiến lỗi chỉ lộ ra rất trễ dưới dạng timeout mơ hồ ở
    // bước chờ "Xuất báo cáo thành công!" thay vì báo đúng chỗ sai.
    await $(
      const Key('export_selected_scope'),
    ).waitUntilVisible(timeout: searchTimeout);
    expect($(const Key('export_selected_scope')), findsOneWidget);

    await $(const Key('export_pdf_button')).waitUntilVisible();
    // noSettle: ngay khi bấm, ExportViewModel hiện CircularProgressIndicator
    // (animation vô hạn) trong lúc build PDF + upload Storage. tap mặc định
    // (trySettle -> pumpAndTrySettle) sẽ cố pump tới khi cây widget đứng yên,
    // nhưng spinner không bao giờ đứng yên nên treo dưới LiveTestBinding của
    // Patrol. noSettle chỉ pump 1 frame rồi trả về; waitUntilVisible bên dưới
    // tự poll (pump 100ms/lần) nên vẫn bắt được dòng thành công khi upload xong.
    await $(
      const Key('export_pdf_button'),
    ).tap(settlePolicy: SettlePolicy.noSettle);

    await $(
      'Xuất báo cáo thành công!',
    ).waitUntilVisible(timeout: _exportTimeout);
    expect($('Xuất báo cáo thành công!'), findsOneWidget);
  });
}
