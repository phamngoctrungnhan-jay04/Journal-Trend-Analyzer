# lib/firebase/

Thư mục dành riêng cho các Firebase service của Lab 03 (chưa triển khai ở Stage 0).

Kế hoạch (Stage 1 – Stage 4):
- `auth_service.dart` — Google Sign-In, currentUser stream (Stage 1)
- `analytics_service.dart` — 7 event log (Stage 3)
- `storage_service.dart` — upload PDF report, trả về download URL (Stage 3)
- `fcm_service.dart` — token, foreground message handling (Stage 4)
- `remote_config_service.dart` — fetch/activate remote config keys (Stage 4)
- `crashlytics_service.dart` — handled exception + test crash (Stage 4)

File này sẽ được xóa khi thư mục có ít nhất 1 service thật.
