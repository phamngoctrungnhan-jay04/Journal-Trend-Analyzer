# Journal Trend Analyzer

Ứng dụng Flutter phân tích xu hướng nghiên cứu học thuật, sử dụng OpenAlex API.
Môn PRM393 – Mobile Programming.

> **Lab 03 phát triển tiếp từ Lab 02** trên cùng repo này. Lịch sử commit
> trước `f6acc61` ("Fix UI: chip gợi ý và nhãn trục năm trên biểu đồ",
> merge vào `main` tại `fa7c3e4`) thuộc về Lab 02. Nhánh `lab03-dev` là nơi
> tái cấu trúc và bổ sung Firebase cho Lab 03. Xem chi tiết từng luồng
> nghiệp vụ Lab 02 tại [`docs/`](./docs/README.md).

---

## Project Structure (Lab 03, nhánh `lab03-dev`)

```
lib/
├── main.dart                          # Điểm khởi động ứng dụng
│
├── models/                            # TẦNG DỮ LIỆU - Khuôn mẫu dữ liệu
│   ├── work.dart                      # Model bài báo (title, year, citations...)
│   ├── author.dart                    # Model tác giả (Author, Authorship, TopAuthor)
│   ├── journal.dart                   # Model tạp chí/journal (JournalSource, TopJournal)
│   ├── dashboard_stats.dart           # Model tổng hợp cho Dashboard
│   ├── model_aliases.dart             # typedef Publication=Work, Journal=TopJournal
│   ├── keyword.dart                   # [MỚI] entity Keyword (skeleton, hoàn thiện ở Stage 2)
│   └── user_profile.dart              # [MỚI] entity UserProfile (skeleton, hoàn thiện ở Stage 1)
│
├── services/                          # TẦNG KẾT NỐI - Gọi API (nguồn dữ liệu ngoài Firebase)
│   └── openalex_service.dart          # Tất cả các hàm gọi OpenAlex API
│
├── firebase/                          # [MỚI] TẦNG FIREBASE - chưa có service nào ở Stage 0
│   └── README.md                      # Danh sách service dự kiến + stage triển khai
│
├── viewmodels/                        # TẦNG STATE MANAGEMENT (đổi tên từ providers/ ở Lab 02)
│   ├── search_provider.dart           # State cho màn hình Search
│   └── analysis_provider.dart         # State cho Trend Analysis & Dashboard
│
├── screens/                           # TẦNG GIAO DIỆN - Các màn hình chính
│   ├── search_screen.dart             # Màn hình tìm kiếm (FR 4.1)
│   ├── publication_detail_screen.dart # Màn hình chi tiết bài báo (FR 4.2)
│   ├── trend_analysis_screen.dart     # Màn hình phân tích xu hướng (FR 4.3-4.6)
│   └── dashboard_screen.dart          # Màn hình dashboard (FR 4.7)
│
├── widgets/                           # TẦNG WIDGET TÁI SỬ DỤNG
│   ├── publication_card.dart          # Card hiển thị 1 bài báo trong danh sách
│   ├── author_list_tile.dart          # Tile hiển thị tác giả + số bài
│   ├── stat_card.dart                 # Card hiển thị 1 chỉ số (dùng trong Dashboard)
│   ├── loading_widget.dart            # LoadingWidget + SkeletonCard
│   └── error_widget.dart              # AppErrorWidget + EmptyResultWidget
│
└── utils/                             # TIỆN ÍCH DÙNG CHUNG
    ├── constants.dart                 # Hằng số (base URL, màu sắc theme...)
    └── text_utils.dart                # Hàm xử lý text (decode abstract...)
```

> Ở Lab 02, 2 biểu đồ (trend theo năm + top journals) không nằm ở file
> widget riêng — chúng được vẽ **inline** ngay trong
> `trend_analysis_screen.dart` (`fl_chart`). Danh sách trên phản ánh đúng
> code thật, không phải bản mô tả lý tưởng.

---

## Giải thích từng tầng

### 1. `models/` — "Khuôn mẫu dữ liệu"

**Vai trò:** Định nghĩa *hình dạng* của dữ liệu JSON từ API.

Khi OpenAlex trả về JSON như:
```json
{ "title": "Deep Learning", "publication_year": 2023, "cited_by_count": 150 }
```
Model `Work` sẽ "dịch" JSON đó thành object Dart mà Flutter có thể dùng an toàn. Nếu không có Model, bạn sẽ phải dùng `json['title']` khắp nơi — rất dễ typo và không có gợi ý code.

### 2. `services/` — "Người đưa thư đến API"

**Vai trò:** Chứa toàn bộ logic gọi HTTP, không có gì khác.

Tất cả URL, query params của OpenAlex chỉ được viết **một lần duy nhất** ở đây. Nếu API thay đổi, bạn chỉ cần sửa 1 file này — không phải lùng sục khắp project.

### 3. `viewmodels/` — "Não bộ điều phối"

**Vai trò:** Quản lý trạng thái (state) — "đang loading", "có dữ liệu", "có lỗi".

Sử dụng package **Provider** (state management đơn giản, phù hợp cho sinh viên). Provider "giữ" dữ liệu và thông báo cho Widget khi dữ liệu thay đổi — Widget chỉ cần "lắng nghe", không cần tự gọi API.

### 4. `screens/` — "Các phòng của ứng dụng"

**Vai trò:** Mỗi file là 1 màn hình hoàn chỉnh — 4 màn hình của Lab 02 (Search,
Publication Detail, Trend Analysis, Dashboard). Lab 03 sẽ tách `trend_analysis_screen.dart`
thành các màn hình riêng (Journals, Journal Detail, Keywords, Keyword Detail)
và bổ sung Login/Profile — xem kế hoạch ở Stage 2 trong `docs/`.

Screen chỉ lo việc *bố cục* (layout) — nó lấy dữ liệu từ ViewModel, và hiển thị qua Widgets. Screen không gọi API trực tiếp.

### 5. `widgets/` — "Viên gạch tái sử dụng"

**Vai trò:** Các component nhỏ dùng đi dùng lại nhiều lần.

Ví dụ: `PublicationCard` được dùng cả ở Search Screen lẫn Trend Screen — viết 1 lần, dùng mọi nơi.

### 6. `utils/` — "Hộp công cụ"

**Vai trò:** Hằng số và hàm tiện ích thuần túy, không có UI, không có state.

---

## Tóm tắt luồng dữ liệu (Data Flow)

```
[User nhập keyword]
      ↓
[Screen] → gọi → [ViewModel]
                     ↓
               [Service] → HTTP GET → [OpenAlex API]
                     ↓
               [Model] ← parse JSON ←
                     ↓
[Widget] ← rebuild ← [ViewModel notify]
```

Kiến trúc **3 tầng (Presentation → Business Logic → Data)** — đáp ứng yêu cầu đề bài:
> *"separation of concerns between user interface, business logic, and data access layers"*

---

## Packages sử dụng

| Package | Mục đích |
|---|---|
| `http` | Gọi REST API |
| `provider` | State Management |
| `fl_chart` | Vẽ biểu đồ (bar, line, pie) |

---

## OpenAlex API

- **Base URL:** `https://api.openalex.org`
- **Endpoint chính:** `/works`
- **Tham số:** `search`, `filter`, `sort`, `group_by`, `per_page`, `select`
- **Các field dùng:** `title`, `publication_year`, `cited_by_count`, `authorships`, `primary_location`, `doi`, `abstract_inverted_index`
- **Không cần API key** cho mức sử dụng cơ bản
