// Skeleton cho Stage 0 — entity mới của Lab 03, chưa có ở Lab 02 (app cũ
// không có đăng nhập).
//
// TODO (Stage 1): map từ firebase_auth User sau khi tích hợp auth_service.dart.
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
}
