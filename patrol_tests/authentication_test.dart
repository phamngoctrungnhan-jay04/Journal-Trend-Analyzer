import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/pump_app.dart';

void main() {
  appTest('TC1 - Đăng nhập Google thành công, vào Home', ($) async {
    await pumpUnauthenticatedApp($);

    expect($('Đăng nhập với Google'), findsOneWidget);

    await $(const Key('google_sign_in_button')).tap();

    // FakeAuthService phát user ngay lập tức -> _AuthGate chuyển sang
    // MainShell, bottom nav với 4 tab hiển thị.
    await $(const Key('nav_home')).waitUntilVisible();
    expect($(const Key('nav_journals')), findsOneWidget);
    expect($(const Key('nav_keywords')), findsOneWidget);
    expect($(const Key('nav_profile')), findsOneWidget);
  });

  appTest('TC11 - Đăng xuất quay lại màn hình đăng nhập', ($) async {
    await pumpAuthenticatedApp($);

    await $(const Key('nav_profile')).tap();
    // Nút đăng xuất nằm cuối màn Profile (dưới card bookmark/export/thông
    // báo/cài đặt hiển thị/debug) nên phải cuộn tới. Chỉ đích danh view =
    // profile_list — mặc định scrollTo lấy Scrollable ĐẦU TIÊN trong toàn
    // app, có thể trúng nhầm tab khác (IndexedStack của MainShell vẫn giữ
    // các tab khác tồn tại ngầm).
    await scrollToKey(
      $,
      const Key('logout_button'),
      view: find.byKey(const Key('profile_list')),
    );
    await $(const Key('logout_button')).tap();

    await $('Đăng nhập với Google').waitUntilVisible();
    expect($('Đăng nhập với Google'), findsOneWidget);
  });
}
