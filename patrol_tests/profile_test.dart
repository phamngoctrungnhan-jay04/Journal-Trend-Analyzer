import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/fake_auth_service.dart';
import 'common/pump_app.dart';

void main() {
  appTest('TC8 - Xem thông tin hồ sơ người dùng', ($) async {
    await pumpAuthenticatedApp($);

    await $(const Key('nav_profile')).tap();

    await $(FakeAuthService.testProfile.displayName!).waitUntilVisible();
    expect($(FakeAuthService.testProfile.displayName!), findsOneWidget);
    expect($(FakeAuthService.testProfile.email!), findsOneWidget);
    expect($('Bài báo đã lưu'), findsOneWidget);

    // Thẻ "Xuất báo cáo" và "Trung tâm thông báo" nằm dưới thẻ "Bài báo đã
    // lưu" trong ListView (build lazy theo viewport, khác SingleChildScrollView
    // — không tự có trong cây widget nếu chưa cuộn tới) nên phải cuộn tới
    // từng thẻ mới chắc chắn tìm thấy. Chỉ đích danh view = profile_list —
    // mặc định scrollTo lấy Scrollable ĐẦU TIÊN trong toàn app, có thể trúng
    // nhầm tab khác (IndexedStack của MainShell vẫn giữ các tab khác tồn tại
    // ngầm).
    final profileList = find.byKey(const Key('profile_list'));
    await scrollToKey($, const Key('export_pdf_button'), view: profileList);
    expect($('Xuất báo cáo'), findsOneWidget);
    await scrollToKey($, const Key('notification_card'), view: profileList);
    expect($('Trung tâm thông báo'), findsOneWidget);
  });
}
