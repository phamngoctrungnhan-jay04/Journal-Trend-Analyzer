import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase/notification_service.dart';
import '../models/app_notification.dart';

// App-level (đăng ký trong MultiProvider, không screen-scoped như
// ExportViewModel) vì cần sống xuyên suốt app để không bỏ lỡ message khi
// user đang ở tab khác Profile.
class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service;
  late final StreamSubscription<RemoteMessage> _messageSubscription;

  NotificationViewModel({NotificationService? service})
    : _service = service ?? NotificationService() {
    _messageSubscription = _service.onMessage.listen(_onMessage);
    unawaited(_init());
  }

  final List<AppNotification> _history = [];
  List<AppNotification> get history => List.unmodifiable(_history);

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> _init() async {
    await _service.requestPermission();
    _fcmToken = await _service.getToken();
    notifyListeners();
  }

  void _onMessage(RemoteMessage message) {
    _history.insert(
      0,
      AppNotification(
        title: message.notification?.title ?? '(Không có tiêu đề)',
        body: message.notification?.body ?? '',
        receivedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }
}
