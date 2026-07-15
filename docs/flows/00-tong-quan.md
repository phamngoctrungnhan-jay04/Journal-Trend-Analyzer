# 00 — Tổng quan kiến trúc

> **Ghi chú:** Tài liệu này mô tả kiến trúc **Lab 02**, chốt tại thời điểm
> trước khi tái cấu trúc cho Lab 03 (commit `f6acc61`, merge vào `main` tại
> `fa7c3e4`). Từ nhánh `lab03-dev` trở đi, `lib/providers/` đã đổi tên thành
> `lib/viewmodels/`, có thêm `lib/firebase/`, `lib/models/keyword.dart`,
> `lib/models/user_profile.dart`, `lib/models/model_aliases.dart`
> (`Publication = Work`, `Journal = TopJournal`). Toàn bộ mô tả luồng
> nghiệp vụ (FLOW 1–4) bên dưới và trong các file `01`–`04` vẫn đúng về mặt
> hành vi — chỉ đường dẫn `providers/` cần đọc là `viewmodels/`.

## Ứng dụng là gì

**Journal Trend Analyzer** là ứng dụng **di động (mobile)** viết bằng **Flutter/Dart**, thực hiện đồ án môn *PRM393 – Mobile Programming, Lab 2* (theo mô tả trong `pubspec.yaml` và `README.md`). App cho phép người dùng nhập một chủ đề nghiên cứu (ví dụ "Machine Learning") và xem:

- Danh sách bài báo khoa học liên quan (tìm kiếm)
- Chi tiết từng bài báo
- Phân tích xu hướng xuất bản theo năm, top bài báo được trích dẫn nhiều nhất, top tạp chí, top tác giả
- Dashboard tổng hợp các chỉ số nổi bật nhất cho chủ đề đó

## Tech stack

| Thành phần | Công nghệ |
|---|---|
| Framework | Flutter (Material 3, `useMaterial3: true`) |
| Ngôn ngữ | Dart SDK `^3.11.4` |
| State management | `provider: ^6.1.2` (kiến trúc `ChangeNotifier`) |
| HTTP client | `http: ^1.2.2` |
| Vẽ biểu đồ | `fl_chart: ^0.70.2` |
| Nguồn dữ liệu | [OpenAlex REST API](https://api.openalex.org) — mở, miễn phí, không cần API key |
| Backend riêng | **Không có** |
| Database / lưu trữ cục bộ | **Không có** (không SQLite/Hive/SharedPreferences) — state chỉ tồn tại trong RAM khi app đang chạy |
| Authentication | **Không có** |

## Kiến trúc 3 tầng

```
┌─────────────┐     đọc/gọi      ┌──────────────┐     gọi HTTP      ┌────────────────┐
│   Screens   │ ───────────────▶ │  Providers   │ ────────────────▶ │ OpenAlexService │
│ (lib/screens)│ ◀─notifyListeners│(ChangeNotifier)│                  │ (lib/services)  │
└─────────────┘                  └──────────────┘                    └────────┬────────┘
      │                                                                        │ HTTP GET
      ▼                                                                        ▼
┌─────────────┐                                                       ┌────────────────┐
│   Widgets    │                                                       │  OpenAlex API   │
│ (lib/widgets)│                                                       │ api.openalex.org│
└─────────────┘                                                       └────────┬────────┘
                                                                                 │ JSON
                                                                                 ▼
                                                                        ┌────────────────┐
                                                                        │     Models      │
                                                                        │  (lib/models)    │
                                                                        │  .fromJson()     │
                                                                        └────────────────┘
```

## Cấu trúc thư mục `lib/`

```
lib/
├── main.dart                              # Entry point, MultiProvider, theme
├── models/
│   ├── work.dart                          # Work, YearlyTrend
│   ├── author.dart                        # Author, Authorship, TopAuthor
│   ├── journal.dart                       # JournalSource, PrimaryLocation, TopJournal
│   └── dashboard_stats.dart               # DashboardStats (tổng hợp)
├── services/
│   └── openalex_service.dart              # OpenAlexService + ApiException (tất cả API call)
├── providers/
│   ├── search_provider.dart               # State cho luồng Search
│   └── analysis_provider.dart             # State cho luồng Trend Analysis + Dashboard
├── screens/
│   ├── search_screen.dart                 # FLOW 1 — màn hình home
│   ├── publication_detail_screen.dart     # FLOW 2
│   ├── trend_analysis_screen.dart         # FLOW 3 — 4 tab (chứa cả code vẽ chart inline)
│   └── dashboard_screen.dart              # FLOW 4
├── widgets/                                # Component tái sử dụng (xem bảng bên dưới)
└── utils/
    ├── constants.dart                     # AppConstants, AppColors, AppTextStyles
    └── text_utils.dart                    # decodeAbstract, truncate, formatCount, cleanX
```

> **Lưu ý lệch giữa README và code thật (tại thời điểm Lab 02):** `README.md` khi đó mô tả có `widgets/trend_chart.dart` và `widgets/journal_chart.dart` riêng biệt, nhưng thực tế **các file này không tồn tại**. Toàn bộ logic vẽ 2 biểu đồ (`BarChart` của `fl_chart`) được viết **inline trực tiếp** trong `lib/screens/trend_analysis_screen.dart`, ở 2 private widget `_TrendChartTab` và `_TopJournalsTab`. Điều này **vẫn đúng** ở nhánh `lab03-dev` — 2 file chart riêng chưa được tách ra.

### Cấu trúc hiện tại trên nhánh `lab03-dev` (sau Stage 0)

```
lib/
├── main.dart
├── models/
│   ├── work.dart, author.dart, journal.dart, dashboard_stats.dart   # giữ nguyên như Lab 02
│   ├── model_aliases.dart                 # typedef Publication = Work; typedef Journal = TopJournal;
│   ├── keyword.dart                       # [MỚI] skeleton, hoàn thiện ở Stage 2
│   └── user_profile.dart                  # [MỚI] skeleton, hoàn thiện ở Stage 1
├── services/
│   └── openalex_service.dart              # không đổi
├── firebase/
│   └── README.md                          # [MỚI] placeholder, chưa có service thật
├── viewmodels/                            # đổi tên từ providers/, nội dung KHÔNG đổi
│   ├── search_provider.dart
│   └── analysis_provider.dart
├── screens/                                # không đổi ở Stage 0 (sẽ tách 4 tab ở Stage 2)
├── widgets/                                # không đổi
└── utils/                                  # không đổi
```

## Component/Service dùng chung (Shared)

| File | Vai trò |
|---|---|
| `lib/services/openalex_service.dart` | Dùng chung bởi `SearchProvider` và `AnalysisProvider`, mỗi provider tự khởi tạo instance riêng (constructor cho phép inject để test) |
| `lib/utils/constants.dart` | `AppColors`, `AppTextStyles`, `AppConstants` (base URL, pagination, suggested topics, chart colors) — import ở hầu hết mọi screen/widget |
| `lib/utils/text_utils.dart` | `decodeAbstract` (giải mã abstract từ inverted index của OpenAlex), `truncate`, `formatCount` (1.5K/2M), `cleanJournalName`, `cleanAuthorName` |
| `lib/widgets/publication_card.dart` (`PublicationCard`) | Dùng ở Search (FLOW 1) và Top Papers tab (FLOW 3) |
| `lib/widgets/error_widget.dart` (`AppErrorWidget`, `EmptyResultWidget`) | Dùng ở cả 4 screens cho trạng thái lỗi/rỗng |
| `lib/widgets/loading_widget.dart` (`LoadingWidget`, `SkeletonCard`) | Dùng ở Search, Trend Analysis, Dashboard |
| `lib/widgets/stat_card.dart` (`StatCard`) | Chỉ dùng trong Dashboard |
| `lib/widgets/author_list_tile.dart` (`AuthorListTile`) | Chỉ dùng trong Top Authors tab |
| `lib/models/work.dart`, `author.dart`, `journal.dart`, `dashboard_stats.dart` | Model layer dùng chung xuyên suốt app |

## Nguồn dữ liệu — OpenAlex API

Không có backend riêng: mọi dữ liệu lấy trực tiếp từ `https://api.openalex.org/works` qua `lib/services/openalex_service.dart`.

- Mọi request đều gắn thêm `mailto=phamngoctrungnhan0901@gmail.com` (`openalex_service.dart:25`) để vào "polite pool" của OpenAlex (ưu tiên rate-limit cao hơn).
- Timeout: 15 giây mỗi request.
- Xử lý lỗi qua `ApiException` (`openalex_service.dart:6-14`): phân biệt riêng lỗi 429 ("Quá nhiều yêu cầu..."), lỗi HTTP khác ("Lỗi máy chủ (code)..."), lỗi mạng ("Không thể kết nối...").
- 6 hàm API đang thực sự được dùng: `searchWorks`, `getPublicationsByYear`, `getTopCitedWorks`, `getTopJournals`, `getTopAuthors`, `getDashboardOverview`. Hàm thứ 7, `getWorkById()`, **tồn tại trong service nhưng chưa được gọi ở bất kỳ đâu trong UI hiện tại** (xem chi tiết ở [02 — Chi tiết bài báo](./02-chi-tiet-bai-bao.md)).

## Điểm cần lưu ý chung khi đọc code

1. **Không có persistence** — kết quả search, kết quả phân tích sẽ mất khi thoát app hoặc khi Provider bị dispose; không cache, không lưu lịch sử tìm kiếm.
2. **Trung bình citation ở Dashboard** không phải trung bình thực trên toàn bộ tập kết quả tìm kiếm mà chỉ **ước lượng từ top 10 bài được trích dẫn nhiều nhất** — xem chi tiết ở [04 — Dashboard](./04-dashboard.md).
3. `test/widget_test.dart` vẫn là test mặc định `Counter increments smoke test` do Flutter tạo sẵn, **chưa được cập nhật** cho app thực tế → sẽ fail nếu chạy `flutter test`.
4. Repo hiện có 2 commit: `f67bf7a` (khởi tạo scaffold) và `f6acc61` "Fix UI: chip gợi ý và nhãn trục năm trên biểu đồ" (branch hiện tại `fix/ui-chip-and-chart-labels`) — xem chi tiết fix ở [03 — Phân tích xu hướng](./03-phan-tich-xu-huong.md).
