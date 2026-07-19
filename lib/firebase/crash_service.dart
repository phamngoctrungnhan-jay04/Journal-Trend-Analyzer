import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashService {
  final FirebaseCrashlytics _crashlytics;

  CrashService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  void setupErrorHandlers() {
    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> recordHandledException(Object error, StackTrace stack) =>
      _crashlytics.recordError(error, stack, fatal: false);

  // Ép crash thật để test - app sẽ đóng ngay lập tức, report chỉ upload
  // lên Console sau khi mở lại app lần kế tiếp (hành vi chuẩn của
  // Crashlytics, không phải bug).
  void triggerTestCrash() => _crashlytics.crash();
}
