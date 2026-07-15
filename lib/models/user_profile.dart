import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

// Entity mới của Lab 03, chưa có ở Lab 02 (app cũ không có đăng nhập).
class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  factory UserProfile.fromFirebaseUser(fb_auth.User user) {
    return UserProfile(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }
}
