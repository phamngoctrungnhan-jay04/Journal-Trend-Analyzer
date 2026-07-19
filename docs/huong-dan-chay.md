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
  (search +        (search RIÊNG    (search RIÊNG    (avatar,
   lưới 26 lĩnh     + xếp hạng       + xếp hạng       export PDF
   vực → phụ)       tạp chí)         từ khoá)         theo chủ đề
     │              │                  │              tự chọn,
     │ chọn xong    │                  │              notifications,
     ▼              ▼                  ▼              logout)
  Overview     JournalDetail      KeywordDetail
  (2 chỉ số +  (bài báo trong     (trend theo năm +
   biểu đồ +    tạp chí)           top tác giả)
   5 bài)         │
     │            │        ↑ mỗi tab một phạm vi RIÊNG, độc lập
     ▼            │
 Publications     │
 (list đầy đủ,    │
  cuộn vô hạn)    │
     │            │
     ▼            ▼
   PublicationDetail
   (meta, tác giả, tóm tắt, link gốc, DOI)
```

### Nguyên tắc điều hướng theo lĩnh vực (quan trọng)

App dùng **cây phân loại có sẵn của OpenAlex** thay vì bắt user tự nghĩ từ khoá.
Đây là bộ **đầy đủ**, không phải danh sách gợi ý — 98,3% bài báo được phân loại:

| Tầng | Số lượng | Hiển thị ở |
|---|---|---|
| Field (lĩnh vực chính) | 26 | Home — lưới card, viết cứng trong `constants.dart` |
| Subfield (lĩnh vực phụ) | 252 | Home — expand tại chỗ, nạp từ API khi bấm |
| Topic (chủ đề hẹp) | 4.516 | Ô tìm kiếm ở cả 3 tab (`/topics`) + tab Keywords |

**Mỗi tab một phạm vi RIÊNG, độc lập nhau.** Home, Journals, Keywords mỗi tab
giữ [`ResearchScope`](../lib/models/research_scope.dart) của mình (`HomeProvider`
/ `JournalsProvider` / `KeywordsProvider`) — chọn lĩnh vực ở tab này **không**
đổi tab kia. Bạn có thể xem Home ở "Software", Journals ở "Deep Learning",
Keywords ở "Blockchain" cùng lúc.

- **Ô tìm kiếm tìm trong CÂY PHÂN LOẠI, không search full-text bài báo.** Gõ
  "blockchain" → [`TaxonomySearchField`](../lib/widgets/taxonomy_search_field.dart)
  gọi `/topics?display_name.search=` → gợi ý các topic kèm breadcrumb nhánh cha
  và số bài. Chọn xong vẫn lọc bằng `filter=primary_topic.id:<id>`.
  - Vì sao không search text thẳng: `search=blockchain` quét full-text toàn
    OpenAlex ra **246.708** bài (gồm bài chỉ nhắc thoáng qua); chọn đúng topic
    rồi `primary_topic.id:T10270` ra **51.340** bài thực sự về blockchain. Tìm
    trong "bản đồ" thay vì "thế giới" giữ số liệu đúng phạm vi.
  - Có debounce 350ms + tối thiểu 3 ký tự để không cạn quota OpenAlex.
- **Mọi** truy vấn dùng `filter=primary_topic.*` chứ **không bao giờ** `search=`
  → số liệu luôn của riêng phạm vi đó. (Đối chiếu: subfield *Software* = **81.212**
  bài `type:article`.)
- **Home**: ô tìm kiếm + lưới 26 lĩnh vực chính → bấm để xổ lĩnh vực phụ → chọn
  xong hiện **thanh chip bộ lọc** (`Bộ lọc` + chip từng cấp có nút `×` + `Xóa
  bộ lọc`, bấm đâu cũng quay về lưới) + **3 tab con**:
  - **Tổng quan** — 4 stat card (Tổng tài liệu, Trích dẫn TB, Năm sôi nổi, Tỷ lệ
    OA), card "Tạp chí xuất bản nhiều nhất" (bấm vào mở `JournalDetailScreen`),
    card + list "Tác giả đóng góp nhiều nhất" (không bấm được — chưa có màn chi
    tiết tác giả), "Phân bố theo chủ đề" (bấm vào mở `KeywordDetailScreen`).
  - **Xu hướng** — biểu đồ xu hướng theo năm (`YearlyTrendChart`).
  - **Bài báo** — danh sách đầy đủ, cuộn vô hạn (không còn nút "Xem tất cả"
    hay màn `PublicationsScreen` riêng — đã gộp thẳng vào tab).

  Gọi **6 API song song/lần chọn** (getWorks, getPublicationsByYear,
  getTopJournals, getTopAuthors, getTopKeywords, getOpenAccessBreakdown) — đánh
  đổi có chủ đích cho nhiều thông tin hơn, cao hơn con số 2 API của bản trước.
- **Journals**: ô tìm kiếm riêng → xếp hạng tạp chí của chủ đề đang chọn.
- **Keywords**: ô tìm kiếm riêng → xếp hạng từ khoá (topic con) của chủ đề đang
  chọn.
- **Profile**: hồ sơ + **Xuất báo cáo PDF cho chủ đề tự chọn** (ô tìm kiếm riêng
  ở thẻ export; `ExportViewModel` tự gọi 5 API gom dữ liệu khi bấm Xuất) + Trung
  tâm thông báo (FCM) + công cụ debug Crashlytics + Đăng xuất.

Chi tiết từng luồng nghiệp vụ (từ Lab 02): xem [docs/flows](./flows).

---

## 4. Chạy kiểm thử tự động (Patrol E2E)

> ⚠️ **Bộ test đang LỖI THỜI so với UI mới** (chưa cập nhật theo yêu cầu — làm
> phần chính trước). Các key/luồng đã đổi:
>
> - Helper `searchTopic()` gõ `home_search_field` → ô này **không còn**. Thay
>   bằng: bấm `field_card_17` → chờ `subfield_1712` → bấm, HOẶC dùng ô tìm kiếm
>   `taxonomy_search_field` (gõ → chờ chip `topic_suggestion_<id>` → bấm). Mốc
>   chờ đổi từ `'Tổng bài báo'` → tên tab `'Tổng quan'` hiện ra (`TabBar` 3 tab:
>   Tổng quan/Xu hướng/Bài báo).
> - TC2/TC3: danh sách bài báo giờ nằm trong tab **Bài báo** ngay tại Home (key
>   `publications_list` vẫn còn, nhưng ở trong `home_screen.dart` — không còn
>   `home_view_all_button` hay `PublicationsScreen` riêng để bấm/push nữa, phải
>   chuyển tab bằng `find.text('Bài báo')` thay vì tap nút rồi chờ push màn mới).
> - Thanh chip bộ lọc có key mới: `home_open_filter_button`,
>   `home_clear_filter_button` — cả hai đều quay về lưới chọn lĩnh vực.
> - TC4/TC5 (Journals) và TC6/TC7/TC12 (Keywords): 2 tab này giờ có ô tìm kiếm
>   riêng (`taxonomy_search_field`), không còn bám theo chủ đề chọn ở Home. Test
>   phải tự chọn chủ đề ngay trong tab.
> - TC9 (export PDF): thẻ export ở Profile giờ có ô chọn chủ đề riêng — phải
>   chọn chủ đề trước khi nút `export_pdf_button` bật.

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
