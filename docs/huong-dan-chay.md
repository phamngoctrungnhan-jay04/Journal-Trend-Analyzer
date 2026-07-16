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

### ⚠️ Máy mới clone về: BẮT BUỘC đăng ký SHA-1 (phải làm ĐỦ 2 LỚP)

**Nguyên nhân:** Google Sign-In trên Android xác thực bằng **SHA-1 của
`debug.keystore`**. Mỗi máy dev có `debug.keystore` **riêng, SHA-1 khác nhau** (do
Android Studio tự sinh khi cài). Google chỉ chấp nhận SHA-1 **đã đăng ký**.

**Triệu chứng chung:** app **vẫn build và chạy bình thường**, nhưng **kẹt ở màn
Login** — bấm "Đăng nhập với Google" là báo lỗi.

> Chỉ **Google Sign-In** cần SHA-1. Các dịch vụ khác (FCM, Analytics, Crashlytics,
> Remote Config, Storage) **không cần** — chúng chạy được ngay trên máy mới.

SHA-1 bị chặn ở **hai lớp độc lập**. ⚠️ **Thêm ở lớp 1 KHÔNG tự động mở lớp 2** —
thiếu lớp nào cũng không đăng nhập được:

| Lớp | Quản ở đâu | Thông báo lỗi nếu thiếu |
|-----|-----------|------------------------|
| **1. OAuth client** | Firebase Console | `ApiException: 10` / `DEVELOPER_ERROR` → "Đăng nhập Google thất bại." |
| **2. Giới hạn API key** | Google Cloud Console | `An internal error has occurred. [ Requests from this Android client application com.prm393.journal_trend_analyzer are blocked. ]` |

---

#### Bước 1 — Lấy SHA-1 của máy mới

```bash
cd android
./gradlew signingReport
```

Lấy dòng `SHA1:` ở variant **debug** (`Config: debug`), dạng
`AA:BB:CC:...` (20 cặp hex).

> Nếu `gradlew` báo *"JAVA_HOME is not set"*: dùng keytool của JDK do Android
> Studio cài kèm (đường dẫn xem bằng `flutter doctor -v`, dòng *Java binary at*):
> ```bash
> <duong-dan-jdk>/bin/keytool -list -v \
>   -keystore ~/.android/debug.keystore \
>   -alias androiddebugkey -storepass android -keypass android
> ```

#### Bước 2 — LỚP 1: Đăng ký OAuth client (Firebase Console)

`https://console.firebase.google.com/project/prm393-lab3-se1834-27919/settings/general`

→ mục **Your apps** → app Android `com.prm393.journal_trend_analyzer` →
**Add fingerprint** → dán SHA-1 → **Save**.

> Firebase cho phép **nhiều SHA-1 cùng lúc** — thêm fingerprint mới **không làm
> mất** của người khác. Cả nhóm mỗi người thêm một cái.

#### Bước 3 — Tải lại `google-services.json`

Vẫn ở trang đó → nút **google-services.json** → thay file
`android/app/google-services.json` → **commit + push**. File mới sẽ có thêm một
`oauth_client` với `client_type: 1` ứng với SHA-1 vừa thêm.

#### Bước 4 — LỚP 2: Nới giới hạn API key (Google Cloud Console)

⚠️ **Đây là bước hay bị bỏ sót nhất** — làm xong bước 2–3 mà quên bước này thì vẫn
dính lỗi *"...are blocked"*.

`https://console.cloud.google.com/apis/credentials?project=prm393-lab3-se1834-27919`

1. Bảng **API Keys** → bấm **"Android key (auto created by Firebase)"**
   (cột *Restrictions* ghi **"Android apps, 25 APIs"**).
2. Kéo tới **Application restrictions** → đang chọn **Android apps**.
3. Bấm **+ Add** → điền:
   - **Package name:** `com.prm393.journal_trend_analyzer`
   - **SHA-1 certificate fingerprint:** SHA-1 của máy mới
4. Bấm **Done** → kéo xuống cuối bấm **Save** ⚠️ (quên Save là không ăn).

> Không đụng vào *iOS key* / *Browser key* — không liên quan.

#### Bước 5 — Máy mới chạy lại

```bash
git pull
flutter clean
flutter pub get
flutter run
```

> Google cần **~5 phút** (đôi khi 10–15 phút) để propagate. Không cần rebuild sau
> khi sửa lớp 2 — API key không đổi, chỉ cần tắt hẳn app rồi mở lại.

---

#### Kiểm tra nhanh cấu hình

- SHA-1 máy bạn phải xuất hiện trong `android/app/google-services.json` ở trường
  `certificate_hash` (dạng chữ thường, **không** dấu hai chấm).
- `client_id` của `client_type: 3` (Web client) trong file đó phải **khớp** hằng số
  `_webClientId` trong [lib/firebase/auth_service.dart](../lib/firebase/auth_service.dart)
  — nếu Firebase đổi web client thì phải sửa hằng số này trong code.

#### Vẫn lỗi sau khi làm đủ 2 lớp?

1. Đợi thêm **10–15 phút** (propagate lâu hơn mốc 5 phút Google ghi).
2. Trên máy đó: **Settings → Apps → Journal Trend Analyzer → Storage → Clear data**
   → mở lại (xoá token cache của Play Services).
3. Vẫn lỗi → tạm đổi **Application restrictions** sang **None** → **Save**. Nếu
   chạy được thì chắc chắn SHA-1 ở lớp 2 **nhập sai** (thừa/thiếu ký tự) → nhập lại
   cho đúng rồi bật **Android apps** trở lại.

> Đặt **None** cũng là phương án nhanh khi demo (khỏi thêm SHA-1 từng máy), nhưng
> kém an toàn hơn — key không còn ràng buộc theo app. Với đồ án thì chấp nhận
> được; sản phẩm thật nên giữ **Android apps**.

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
