# Hướng dẫn chạy project & Luồng sử dụng

Tài liệu này mô tả cách cài đặt/chạy ứng dụng **Journal Trend Analyzer** (Lab 03) và
luồng điều hướng thực tế của app sau khi tái cấu trúc điều hướng (mỗi tab tự nạp dữ
liệu theo "chủ đề đang chọn" chung — không còn ràng buộc "phải search ở Home trước").

---

## 1. Yêu cầu môi trường

- **Flutter SDK** `^3.11.4` (kênh stable), Dart đi kèm.
- **Android**: Android Studio + 1 emulator hoặc thiết bị thật (minSdk theo cấu hình Flutter).
- **Firebase**: project đã cấu hình sẵn qua `lib/firebase_options.dart` +
  `android/app/google-services.json` (đã có trong repo). App dùng: Auth (Google +
  Anonymous), Analytics, Storage, Messaging (FCM), Remote Config, Crashlytics.
- Kết nối mạng (gọi **OpenAlex API** công khai + Firebase).

Kiểm tra môi trường:

```bash
flutter --version
flutter doctor
```

---

## 2. Cài đặt & chạy app

```bash
# 1. Cài dependencies
flutter pub get

# 2. Chạy trên emulator/thiết bị đang kết nối
flutter run
```

> **Lưu ý màn đen trên EMULATOR:** một số emulator không vẽ frame đầu tiên với
> Impeller (màn đen tới khi bật/tắt màn hình). App đã **tắt Impeller** trong
> `AndroidManifest.xml` để dùng Skia cho ổn định. Nếu vẫn đen, đổi Graphics của
> emulator sang **Hardware - GLES 2.0** hoặc Cold Boot. Đây là vấn đề emulator,
> không phải logic app.

> **Font:** dùng `google_fonts` (Plus Jakarta Sans) — lần chạy đầu tải font qua
> mạng rồi cache; trong lúc tải hiển thị font dự phòng (không lỗi).

---

## 3. Luồng sử dụng (navigation flow)

```
LoginScreen  ──(đăng nhập Google)──►  MainShell (Bottom Nav 4 tab)
                                          │
        ┌──────────────┬─────────────────┼──────────────┐
        ▼              ▼                  ▼              ▼
     Home           Journals          Keywords        Profile
  (hub chọn        (xếp hạng         (ô search        (avatar,
   chủ đề +         tạp chí)          RIÊNG +          export PDF,
   overview +                        xếp hạng          notifications,
   danh sách        │                từ khoá)          logout)
   bài báo)         │                    │
     │              ▼                    ▼
     │        JournalDetail        KeywordDetail
     │        (bài báo trong       (trend theo năm +
     │         tạp chí)             top tác giả)
     ▼              │
PublicationDetail ◄─┘
(meta, tác giả, tóm tắt, link gốc, DOI)
```

### Nguyên tắc điều hướng chủ đề (quan trọng)
- Có **một "chủ đề đang phân tích" chung** ở cấp app (`TopicProvider`).
- Chọn chủ đề qua action dùng chung `selectTopic()` (ở [lib/utils/topic_actions.dart](../lib/utils/topic_actions.dart)):
  gọi một lần → nạp `SearchProvider` (danh sách bài báo) **và** `AnalysisProvider`
  (overview/Journals/Keywords). Nhờ vậy **mọi tab đều có dữ liệu bất kể bạn bấm
  Tìm từ tab nào** — bỏ ràng buộc "phải search ở Home trước".
- **Home**: hub chọn chủ đề (ô search + chip gợi ý) + overview (thống kê + biểu đồ
  xu hướng) + danh sách bài báo.
- **Keywords**: có **ô search riêng** — tìm chủ đề ngay tại tab này.
- **Journals**: view thụ động theo chủ đề đang chọn (không có ô search).
- **Profile**: hồ sơ + Xuất báo cáo PDF (Storage) + Trung tâm thông báo (FCM) +
  công cụ debug Crashlytics + Đăng xuất.

Chi tiết từng luồng nghiệp vụ (từ Lab 02): xem [docs/flows](./flows).

---

## 4. Chạy kiểm thử tự động (Patrol E2E)

Bộ test nằm ở thư mục `patrol_tests/` (cấu hình trong `pubspec.yaml` mục `patrol:`).

```bash
# Cài patrol_cli (một lần)
dart pub global activate patrol_cli

# Chạy toàn bộ test suite
patrol test

# Chạy 1 file test cụ thể
patrol test --target patrol_tests/authentication_test.dart
```

**Cấu hình quan trọng (đã set sẵn):**
- `android/app/build.gradle.kts` bật **ANDROIDX_TEST_ORCHESTRATOR** → mỗi test chạy
  trong process app mới (tránh lỗi `Invalid response 500` khi có ≥2 test/file với
  patrol 4.7.1).
- Test dùng `FakeAuthService` để **bỏ qua màn Google Sign-In thật** (không automate
  được UI ngoài app). TC9 (export) gọi `signInFirebaseAnon()` để có phiên Firebase
  thật cho Storage token → **cần bật provider Anonymous trong Firebase Console**.

**Danh sách test case:**

| File | TC | Nội dung |
|------|----|----|
| `authentication_test.dart` | TC1, TC11 | Đăng nhập / Đăng xuất |
| `publication_test.dart` | TC2, TC3 | Danh sách + chi tiết bài báo |
| `journal_test.dart` | TC4, TC5 | Top tạp chí + chi tiết journal |
| `keyword_test.dart` | TC6, TC7, TC12 | Top từ khoá + chi tiết + search trực tiếp ở tab Keywords |
| `profile_test.dart` | TC8 | Xem hồ sơ người dùng |
| `export_test.dart` | TC9 | Xuất báo cáo PDF + nhận URL |
| `remote_config_test.dart` | TC10 | Remote Config giới hạn số journal hiển thị |

> **Giới hạn OpenAlex (429):** OpenAlex dùng hạn mức credit theo ngày (~1000
> credit/ngày, mỗi request ~10 credit). Một lần chạy full suite tiêu ~700–770
> credit → **chỉ ~1 lần chạy suite sạch/ngày trên cùng IP**. Nếu gặp 429 ("Quá
> nhiều yêu cầu"), đợi tới nửa đêm UTC (≈ 7h sáng giờ VN) quota reset, hoặc đổi IP
> (hotspot). `OpenAlexService` đã có retry-backoff cho burst ngắn (không cứu được
> khi cạn quota cả ngày).

---

## 5. Thứ tự triển khai còn lại (Stage 5 → 6)

1. Chạy full Patrol suite sạch (khi có credit) → toàn bộ pass.
2. Merge `lab03-dev` → `main`.
3. Chạy AI Code Review (CodeRabbit) trên `main`, sửa finding, giữ bằng chứng.
4. Viết report + quay video demo theo checklist.
