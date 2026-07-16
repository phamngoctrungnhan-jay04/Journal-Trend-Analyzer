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
    expect($('Xuất báo cáo'), findsOneWidget);
    expect($('Trung tâm thông báo'), findsOneWidget);
  });
}
