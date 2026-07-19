import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging;

  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  Future<void> requestPermission() => _messaging.requestPermission();

  Future<String?> getToken() => _messaging.getToken();

  // Chỉ xử lý message khi app đang foreground - onBackgroundMessage cần
  // 1 top-level function riêng (@pragma vm:entry-point), ngoài phạm vi đề
  // bài (chỉ cần thấy thông báo đến khi app đang mở).
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
}
