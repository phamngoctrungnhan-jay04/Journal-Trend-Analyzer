# Journal Trend Analyzer

Ứng dụng Flutter phân tích xu hướng nghiên cứu học thuật, sử dụng OpenAlex API.
Môn PRM393 – Mobile Programming | Lab 2.

---

## Project Structure

```
lib/
├── main.dart                          # Điểm khởi động ứng dụng
│
├── models/                            # TẦNG DỮ LIỆU - Khuôn mẫu dữ liệu
│   ├── work.dart                      # Model bài báo (title, year, citations...)
│   ├── author.dart                    # Model tác giả
│   ├── journal.dart                   # Model tạp chí/journal
│   └── dashboard_stats.dart           # Model tổng hợp cho Dashboard
│
├── services/                          # TẦNG KẾT NỐI - Gọi API
│   └── openalex_service.dart          # Tất cả các hàm gọi OpenAlex API
│
├── providers/                         # TẦNG STATE MANAGEMENT - Quản lý trạng thái
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
│   ├── trend_chart.dart               # Biểu đồ xu hướng theo năm (bar/line chart)
│   ├── journal_chart.dart             # Biểu đồ top journals (horizontal bar)
│   ├── author_list_tile.dart          # Tile hiển thị tác giả + số bài
│   ├── stat_card.dart                 # Card hiển thị 1 chỉ số (dùng trong Dashboard)
│   └── error_widget.dart              # Widget hiển thị lỗi đồng nhất
│
└── utils/                             # TIỆN ÍCH DÙNG CHUNG
    ├── constants.dart                 # Hằng số (base URL, màu sắc theme...)
    └── text_utils.dart                # Hàm xử lý text (decode abstract...)
```

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

### 3. `providers/` — "Não bộ điều phối"

**Vai trò:** Quản lý trạng thái (state) — "đang loading", "có dữ liệu", "có lỗi".

Sử dụng package **Provider** (state management đơn giản, phù hợp cho sinh viên). Provider "giữ" dữ liệu và thông báo cho Widget khi dữ liệu thay đổi — Widget chỉ cần "lắng nghe", không cần tự gọi API.

### 4. `screens/` — "Các phòng của ứng dụng"

**Vai trò:** Mỗi file là 1 màn hình hoàn chỉnh, đúng với yêu cầu 4 màn hình của đề bài.

Screen chỉ lo việc *bố cục* (layout) — nó lấy dữ liệu từ Provider, và hiển thị qua Widgets. Screen không gọi API trực tiếp.

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
[Screen] → gọi → [Provider]
                     ↓
               [Service] → HTTP GET → [OpenAlex API]
                     ↓
               [Model] ← parse JSON ←
                     ↓
[Widget] ← rebuild ← [Provider notify]
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
