import 'dart:async';
import 'package:flutter/foundation.dart';

import '../firebase/auth_service.dart';
import '../firebase/analytics_service.dart';
import '../models/user_profile.dart';

enum AuthState { loading, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  final AuthServiceBase _authService;
  final AnalyticsService _analytics;
  late final StreamSubscription<UserProfile?> _authSubscription;

  // authService cho phép inject AuthServiceBase khác (vd FakeAuthService ở
  // patrol_tests/) để bỏ qua màn hình chọn tài khoản Google thật khi chạy
  // E2E test - không thể automate UI ngoài app của Google Sign-In.
  AuthViewModel({AuthServiceBase? authService, AnalyticsService? analytics})
      : _authService = authService ?? AuthService(),
        _analytics = analytics ?? AnalyticsService() {
    _authSubscription =
        _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // Bắt đầu ở loading để chờ Firebase Auth khôi phục phiên đăng nhập cũ
  // (nếu có) trước khi quyết định hiển thị Login hay Home.
  AuthState _state = AuthState.loading;
  AuthState get state => _state;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;

  bool get isAuthenticated => _state == AuthState.authenticated;

  void _onAuthStateChanged(UserProfile? profile) {
    _userProfile = profile;
    _state =
        profile != null ? AuthState.authenticated : AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isSigningIn = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.signInWithGoogle();
      // Nếu thành công, _onAuthStateChanged sẽ tự cập nhật _state khi
      // FirebaseAuth phát sự kiện - không cần set thủ công ở đây.
      if (success) {
        unawaited(_analytics.logLogin());
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    unawaited(_analytics.logLogout());
    await _authService.signOut();
    // _onAuthStateChanged sẽ tự chuyển _state về unauthenticated.
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
