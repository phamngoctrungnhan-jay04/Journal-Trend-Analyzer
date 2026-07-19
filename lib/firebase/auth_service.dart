import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_profile.dart';

// Đại diện cho lỗi xác thực - giúp hiển thị thông báo lỗi thân thiện cho user
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

// Interface tối giản mà AuthViewModel phụ thuộc vào - cho phép Patrol test
// (patrol_tests/) inject FakeAuthService để bỏ qua màn hình chọn tài khoản
// Google thật (không automate được), không đụng tới AuthService thật.
abstract class AuthServiceBase {
  Stream<UserProfile?> get authStateChanges;

  // true = đăng nhập thành công, false = người dùng tự hủy (không phải lỗi).
  Future<bool> signInWithGoogle();
  Future<void> signOut();
}

class AuthService implements AuthServiceBase {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Web client ID (OAuth client_type: 3) mà Firebase tự tạo khi bật Google
  // làm sign-in provider. Bắt buộc truyền vào initialize() trên Android để
  // idToken được cấp đúng audience mà firebase_auth chấp nhận (google_sign_in
  // >=7.0 không còn tự suy ra client id từ google-services.json như bản cũ).
  static const _webClientId =
      '32439771113-nteh1002fm4n4612q1sd90mp1l2haitc.apps.googleusercontent.com';

  bool _googleSignInInitialized = false;

  AuthService({fb_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  @override
  Stream<UserProfile?> get authStateChanges => _firebaseAuth
      .authStateChanges()
      .map((user) => user != null ? UserProfile.fromFirebaseUser(user) : null);

  fb_auth.User? get currentUser => _firebaseAuth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize(serverClientId: _webClientId);
    _googleSignInInitialized = true;
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final account = await _googleSignIn.authenticate();

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Không lấy được ID token từ Google.');
      }

      final credential = fb_auth.GoogleAuthProvider.credential(
        idToken: idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return false;
      }
      throw AuthException(e.description ?? 'Đăng nhập Google thất bại.');
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Lỗi xác thực Firebase.');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
