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
// chứa retry-with-backoff khi OpenAlex throttle 429 (tối đa ~7s/call).
const searchTimeout = Duration(seconds: 60);

// Wrapper thay cho patrolTest: đặt settlePolicy = noSettle cho TẤT CẢ action.
//
// App có nhiều animation chạy liên tục (shimmer khi search, spinner khi
// export/tải chi tiết, biểu đồ fl_chart tự lên lịch repaint). Mặc định patrol
// dùng trySettle -> mỗi tap/enterText gọi pumpAndTrySettle chờ cây widget
// "đứng yên"; gặp animation vô hạn nó không bao giờ đứng yên và TREO dưới
// LiveTestWidgetsFlutterBinding của Patrol (vượt xa settleTimeout 10s).
// noSettle chỉ pump 1 frame rồi trả về ngay; mọi phép chờ trong test đã dùng
// waitUntilVisible (tự poll pump 100ms/lần) nên vẫn bắt đúng trạng thái. Đây
// là pattern khuyến nghị cho app có animation.
void appTest(
  String description,
  Future<void> Function(PatrolIntegrationTester $) callback,
) {
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
      authViewModel: AuthViewModel(
        authService: FakeAuthService(signedIn: true),
      ),
    ),
  );
}

// Dùng riêng cho TC1 (sign-in) - app khởi động ở trạng thái CHƯA đăng nhập,
// hiển thị LoginScreen như thật.
Future<void> pumpUnauthenticatedApp(PatrolIntegrationTester $) async {
  await ensureFirebaseInitialized();
  await $.pumpWidgetAndSettle(
    JournalTrendApp(
      authViewModel: AuthViewModel(
        authService: FakeAuthService(signedIn: false),
      ),
    ),
  );
}

// Cuộn tới [target] (nằm dưới fold). [view] = Scrollable cụ thể (bắt buộc cho
// Home vì có nhiều Scrollable); bỏ trống cho màn chỉ có 1 Scrollable
// (Journals/Keywords/Profile).
//
// settleBetweenScrollsTimeout: settle CÓ GIỚI HẠN (2s) sau mỗi lần cuộn để
// list kịp render/dừng cuộn rồi mới kiểm tra target. Config toàn cục noSettle
// (cần cho tap để không treo trên spinner vô hạn) lại quá gắt cho cuộn — chỉ
// pump 1 frame nên item chưa kịp visible -> dragUntilVisible flaky timeout
// 5s. Bounded 2s đủ cho list render mà vẫn không treo trên biểu đồ fl_chart
// (hữu hạn).
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

// Tìm MỌI widget có ValueKey<String> bắt đầu bằng [prefix] — cần cho các item
// key ĐỘNG theo id (vd 'topic_suggestion_T10270',
// 'trending_keyword_keywords/machine-learning') mà test không biết trước giá
// trị chính xác, chỉ cần "gợi ý/kết quả ĐẦU TIÊN".
//
// KHÔNG áp .first ở đây (khác với bản cũ) — Finder.first của Flutter
// (_FirstFinderMixin) gọi Iterable.first trên danh sách candidate NGAY khi
// evaluate, nên nếu candidate đang rỗng (gợi ý chưa kịp tải) nó throw
// StateError('No element') tức thì thay vì trả về rỗng. waitUntilVisible bên
// dưới chỉ vòng lặp chờ dựa trên `finder.evaluate().isEmpty` — không bắt
// được StateError đó — nên test luôn crash ngay ở lần poll đầu tiên, trước
// khi API kịp trả dữ liệu. Giữ finder ở dạng "khớp nhiều" và chỉ lấy phần tử
// đầu tiên ở bước tap/enterText (PatrolFinder.first dùng .take(1), an toàn
// với danh sách rỗng) mới đúng ngữ nghĩa "đợi rồi mới lấy đầu tiên".
Finder _withKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}

Future<PatrolFinder> waitFirstWithKeyPrefix(
  PatrolIntegrationTester $,
  String prefix, {
  Duration? timeout,
}) {
  return $(
    _withKeyPrefix(prefix),
  ).waitUntilVisible(timeout: timeout ?? searchTimeout);
}

Future<void> tapFirstWithKeyPrefix(
  PatrolIntegrationTester $,
  String prefix,
) async {
  await $(_withKeyPrefix(prefix)).tap();
}

// Gõ [topic] vào ô tìm chủ đề CỦA HOME (keyPrefix 'home_taxonomy' — tách
// riêng khỏi Journals/Profile vì IndexedStack build cả 4 tab cùng lúc, dùng
// chung keyPrefix sẽ ra 3 widget key trùng). Chọn gợi ý ĐẦU TIÊN rồi chờ
// HomeProvider nạp xong (mốc: stat card 'Tổng tài liệu' — chỉ render khi
// scope đã có dữ liệu).
Future<void> loadHomeScope(
  PatrolIntegrationTester $, {
  String topic = 'Machine Learning',
}) async {
  await $(const Key('home_taxonomy_field')).enterText(topic);
  await waitFirstWithKeyPrefix($, 'topic_suggestion_');
  await tapFirstWithKeyPrefix($, 'topic_suggestion_');
  await $('Tổng tài liệu').waitUntilVisible(timeout: searchTimeout);
}

// Tương tự [loadHomeScope] nhưng cho ô tìm CỦA TAB JOURNALS (chế độ "Theo
// lĩnh vực", keyPrefix 'journals_taxonomy'). Mốc chờ: tiêu đề
// 'Top tạp chí nghiên cứu' xuất hiện khi RankedBarList đã có dữ liệu.
Future<void> loadJournalsScope(
  PatrolIntegrationTester $, {
  String topic = 'Machine Learning',
}) async {
  await $(const Key('journals_taxonomy_field')).enterText(topic);
  await waitFirstWithKeyPrefix($, 'topic_suggestion_');
  await tapFirstWithKeyPrefix($, 'topic_suggestion_');
  await $('Top tạp chí nghiên cứu').waitUntilVisible(timeout: searchTimeout);
}

// Gõ [keyword] vào ô "Phân tích từ khóa" (tab Keywords) rồi bấm Enter/nút
// tìm — khác Home/Journals, luồng này KHÔNG qua bước chọn lĩnh vực, phân
// tích thẳng câu gõ. Mốc chờ: section 'Trending Keywords' (từ khóa liên
// quan) xuất hiện khi KeywordsProvider.analyze() thành công.
Future<void> analyzeKeyword(
  PatrolIntegrationTester $, {
  String keyword = 'Machine Learning',
}) async {
  await $(const Key('keyword_search_field')).enterText(keyword);
  await $(const Key('keyword_search_button')).tap();
  await $('Trending Keywords').waitUntilVisible(timeout: searchTimeout);
}
