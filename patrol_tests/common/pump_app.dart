import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:journal_trend_analyzer/firebase_options.dart';
import 'package:journal_trend_analyzer/main.dart';
import 'package:journal_trend_analyzer/viewmodels/auth_viewmodel.dart';
import 'package:patrol/patrol.dart';

import 'fake_auth_service.dart';

// Timeout chung cho các bước phụ thuộc mạng thật (OpenAlex API). Đủ rộng để
// chứa retry-with-backoff khi OpenAlex throttle 429 (tối đa ~7s/call, analyze
// gọi 6 call song song).
const searchTimeout = Duration(seconds: 60);

// Wrapper thay cho patrolTest: đặt settlePolicy = noSettle cho TẤT CẢ action.
//
// App có nhiều animation chạy liên tục (shimmer SkeletonCard khi search,
// CircularProgressIndicator khi export/tải journal detail, biểu đồ fl_chart
// tự lên lịch repaint). Mặc định patrol dùng trySettle -> mỗi tap/enterText
// gọi pumpAndTrySettle chờ cây widget "đứng yên"; gặp animation vô hạn nó
// không bao giờ đứng yên và TREO dưới LiveTestWidgetsFlutterBinding của Patrol
// (vượt xa settleTimeout 10s). noSettle chỉ pump 1 frame rồi trả về ngay; mọi
// phép chờ trong test đã dùng waitUntilVisible (tự poll pump 100ms/lần) nên
// vẫn bắt đúng trạng thái. Đây là pattern khuyến nghị cho app có animation.
void appTest(String description, Future<void> Function(PatrolIntegrationTester $) callback) {
  patrolTest(
    description,
    config: const PatrolTesterConfig(settlePolicy: SettlePolicy.noSettle),
    callback,
  );
}

// Mỗi file test (= 1 Dart test riêng theo instrumentation.listDartTests())
// chạy trong context có thể đã/chưa có app Firebase mặc định -> tránh lỗi
// [core/duplicate-app] khi gọi lại initializeApp().
Future<void> ensureFirebaseInitialized() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

// Đăng nhập Firebase Auth THẬT bằng anonymous (không mở UI native nào) để
// tầng Firebase có 1 phiên hợp lệ. Firebase Storage tự đính token của
// FirebaseAuth.instance vào request; nếu không có user thật, getDownloadURL()
// ở TC9 retry lấy token vô hạn -> treo. Việc này ĐỘC LẬP với FakeAuthService
// (chỉ fake tầng UI của app qua AuthViewModel), hai bên không xung đột.
// Yêu cầu: bật provider Anonymous trong Firebase Console.
Future<void> signInFirebaseAnon() async {
  if (fb_auth.FirebaseAuth.instance.currentUser == null) {
    await fb_auth.FirebaseAuth.instance.signInAnonymously();
  }
}

// Dùng cho mọi test case KHÔNG phải luồng đăng nhập (TC2-TC10) - bỏ qua
// LoginScreen, vào thẳng MainShell với user giả đã đăng nhập sẵn.
Future<void> pumpAuthenticatedApp(PatrolIntegrationTester $) async {
  await ensureFirebaseInitialized();
  await $.pumpWidgetAndSettle(
    JournalTrendApp(
      authViewModel:
          AuthViewModel(authService: FakeAuthService(signedIn: true)),
    ),
  );
}

// Dùng riêng cho TC1 (sign-in) - app khởi động ở trạng thái CHƯA đăng nhập,
// hiển thị LoginScreen như thật.
Future<void> pumpUnauthenticatedApp(PatrolIntegrationTester $) async {
  await ensureFirebaseInitialized();
  await $.pumpWidgetAndSettle(
    JournalTrendApp(
      authViewModel:
          AuthViewModel(authService: FakeAuthService(signedIn: false)),
    ),
  );
}

// Nhập topic vào ô search ở Home và bấm Tìm, rồi chờ tới khi CẢ
// SearchProvider (render list kết quả) LẪN AnalysisProvider (render overview)
// hoàn thành. Tín hiệu "xong" = stat card 'Tổng bài báo' hiển thị: nó chỉ
// render khi search có kết quả (mở list) VÀ analyze thành công (mở overview),
// nên là mốc chờ ổn định nhất, lại luôn nằm ở đầu list (không cần cuộn).
Future<void> searchTopic(
  PatrolIntegrationTester $, {
  String topic = 'Machine Learning',
}) async {
  await $(const Key('home_search_field')).enterText(topic);
  await $(const Key('home_search_button')).tap();
  await $('Tổng bài báo').waitUntilVisible(timeout: searchTimeout);
}

// Cuộn tới [target] (nằm dưới fold). [view] = Scrollable cụ thể (bắt buộc cho
// Home vì có nhiều Scrollable); bỏ trống cho màn chỉ có 1 Scrollable
// (Journals/Keywords/Profile).
//
// settleBetweenScrollsTimeout: settle CÓ GIỚI HẠN (2s) sau mỗi lần cuộn để list
// kịp render/dừng cuộn rồi mới kiểm tra target. Config toàn cục noSettle (cần
// cho tap để không treo trên spinner vô hạn) lại quá gắt cho cuộn — chỉ pump 1
// frame nên item chưa kịp visible -> dragUntilVisible flaky timeout 5s. Bounded
// 2s đủ cho list render mà vẫn không treo trên biểu đồ fl_chart (hữu hạn).
Future<PatrolFinder> scrollToKey(
  PatrolIntegrationTester $,
  Key target, {
  Finder? view,
}) {
  return $(target).scrollTo(
    view: view,
    settleBetweenScrollsTimeout: const Duration(seconds: 2),
  );
}

// Cuộn list kết quả ở Home tới [target].
Future<PatrolFinder> scrollToInHomeList(
  PatrolIntegrationTester $,
  Key target,
) {
  return scrollToKey($, target, view: find.byKey(const Key('home_results_list')));
}
