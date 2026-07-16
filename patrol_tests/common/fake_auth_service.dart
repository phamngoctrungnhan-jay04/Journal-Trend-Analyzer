import 'dart:async';

import 'package:journal_trend_analyzer/firebase/auth_service.dart';
import 'package:journal_trend_analyzer/models/user_profile.dart';

// Google Sign-In mở UI native ngoài app (chọn tài khoản Google) - không thể
// automate bằng Patrol vì đó là màn hình hệ thống, không phải widget Flutter,
// và phụ thuộc 1 tài khoản Google thật đã đăng nhập sẵn trên thiết bị test.
// FakeAuthService thay AuthServiceBase thật bằng 1 luồng trạng thái giả lập
// tại chỗ, để mọi luồng sau đăng nhập (TC2-TC10) chạy được độc lập, ổn định,
// không phụ thuộc mạng/tài khoản ngoài.
class FakeAuthService implements AuthServiceBase {
  static const testProfile = UserProfile(
    uid: 'patrol-test-uid',
    displayName: 'Patrol Test User',
    email: 'patrol.test@example.com',
  );

  final _controller = StreamController<UserProfile?>.broadcast();

  FakeAuthService({bool signedIn = false}) {
    // authStateChanges() thật của Firebase luôn phát 1 giá trị ngay khi có
    // listener đầu tiên (trạng thái phiên hiện tại) - mô phỏng lại hành vi
    // đó bằng microtask thay vì phát đồng bộ trong constructor.
    Future.microtask(() => _controller.add(signedIn ? testProfile : null));
  }

  @override
  Stream<UserProfile?> get authStateChanges => _controller.stream;

  @override
  Future<bool> signInWithGoogle() async {
    _controller.add(testProfile);
    return true;
  }

  @override
  Future<void> signOut() async {
    _controller.add(null);
  }
}
