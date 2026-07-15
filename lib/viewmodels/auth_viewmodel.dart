import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../firebase/auth_service.dart';
import '../models/user_profile.dart';

enum AuthState { loading, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  late final StreamSubscription<fb_auth.User?> _authSubscription;

  AuthViewModel({AuthService? authService})
      : _authService = authService ?? AuthService() {
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

  void _onAuthStateChanged(fb_auth.User? user) {
    _userProfile = user != null ? UserProfile.fromFirebaseUser(user) : null;
    _state =
        user != null ? AuthState.authenticated : AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isSigningIn = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
      // Nếu thành công, _onAuthStateChanged sẽ tự cập nhật _state khi
      // FirebaseAuth phát sự kiện - không cần set thủ công ở đây.
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    // _onAuthStateChanged sẽ tự chuyển _state về unauthenticated.
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
