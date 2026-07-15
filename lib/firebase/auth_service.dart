import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

// Đại diện cho lỗi xác thực - giúp hiển thị thông báo lỗi thân thiện cho user
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
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

  Stream<fb_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  fb_auth.User? get currentUser => _firebaseAuth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize(serverClientId: _webClientId);
    _googleSignInInitialized = true;
  }

  // Trả về null nếu người dùng tự hủy đăng nhập (không coi là lỗi).
  Future<fb_auth.User?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final account = await _googleSignIn.authenticate();

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Không lấy được ID token từ Google.');
      }

      final credential =
          fb_auth.GoogleAuthProvider.credential(idToken: idToken);
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw AuthException(e.description ?? 'Đăng nhập Google thất bại.');
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Lỗi xác thực Firebase.');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
