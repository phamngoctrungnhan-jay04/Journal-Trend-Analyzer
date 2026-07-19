import 'package:firebase_analytics/firebase_analytics.dart';

// 7 event đúng tên theo đề bài Lab 03. Chỉ có 1 dòng gọi
// FirebaseAnalytics cho mỗi hàm - logic gọi ở đâu (ViewModel nào, lúc
// nào) do nơi gọi quyết định, service này không biết gì về UI.
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  // Event chuẩn "login" - dùng method có sẵn của Firebase thay vì tự
  // gọi logEvent(name: 'login') tay.
  Future<void> logLogin() => _analytics.logLogin();

  Future<void> logSearchTopic(String keyword) => _analytics.logEvent(
    name: 'search_topic',
    parameters: {'keyword': keyword},
  );

  Future<void> logViewPublication({
    required String title,
    required int? year,
  }) => _analytics.logEvent(
    name: 'view_publication',
    parameters: {'title': title, if (year != null) 'year': year},
  );

  Future<void> logViewJournal(String name) =>
      _analytics.logEvent(name: 'view_journal', parameters: {'name': name});

  Future<void> logViewKeyword(String keyword) => _analytics.logEvent(
    name: 'view_keyword',
    parameters: {'keyword': keyword},
  );

  Future<void> logExportPdf(String topic) =>
      _analytics.logEvent(name: 'export_pdf', parameters: {'topic': topic});

  Future<void> logLogout() => _analytics.logEvent(name: 'logout');
}
