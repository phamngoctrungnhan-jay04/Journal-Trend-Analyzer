# 03 — Luồng Phân tích xu hướng nghiên cứu (Trend Analysis)

> FR liên quan: **FR 4.3 – FR 4.6**
> Xem tổng quan kiến trúc tại [00 — Tổng quan](./00-tong-quan.md)

## Entry point

`TrendAnalysisScreen(topic: String)` (`lib/screens/trend_analysis_screen.dart`) — điều hướng tới từ:
- Nút "Phân tích" / "Xem phân tích" ở [Search Screen](./01-tim-kiem.md) (`search_screen.dart:51-59`).
- Nút back từ [Dashboard Screen](./04-dashboard.md).

## File chính

| File | Vai trò |
|---|---|
| `lib/screens/trend_analysis_screen.dart` (570 dòng) | `TrendAnalysisScreen` + 4 private tab widget (`_TrendChartTab`, `_TopPapersTab`, `_TopJournalsTab`, `_TopAuthorsTab`) — **chứa cả code vẽ chart inline** |
| `lib/providers/analysis_provider.dart` | `AnalysisProvider.analyze(topic)` — gọi 5 API song song |
| `lib/services/openalex_service.dart` | 5 hàm: `getPublicationsByYear`, `getTopCitedWorks`, `getTopJournals`, `getTopAuthors`, `getDashboardOverview` |
| `lib/models/work.dart`, `journal.dart`, `author.dart`, `dashboard_stats.dart` | Model parse dữ liệu trả về |
| `package:fl_chart` | `BarChart`, `BarChartData`, `BarChartGroupData` — vẽ 2 biểu đồ |

## Bước khởi tạo

`initState()` (`trend_analysis_screen.dart:30-40`):
```dart
_tabController = TabController(length: 4, vsync: this);
WidgetsBinding.instance.addPostFrameCallback((_) {
  final provider = context.read<AnalysisProvider>();
  if (provider.currentTopic != widget.topic || provider.isInitial) {
    provider.analyze(widget.topic);
  }
});
```
→ Chỉ gọi lại API `analyze()` nếu **chưa từng phân tích** hoặc **topic khác với lần trước** — tránh gọi API thừa khi quay lại màn hình với cùng 1 topic (ví dụ khi back từ Dashboard).

## `AnalysisProvider.analyze(topic)` — gọi 5 API song song

`analysis_provider.dart:49-132`:

1. Set `_currentTopic`, xóa dữ liệu cũ (`_clearData()`), set state `loading`.
2. Gọi **5 API cùng lúc bằng `Future.wait`** (dòng 60-66) để tối ưu thời gian tải thay vì gọi tuần tự:
   ```dart
   final results = await Future.wait([
     _service.getPublicationsByYear(query: trimmed),   // index 0
     _service.getTopCitedWorks(query: trimmed),        // index 1
     _service.getTopJournals(query: trimmed),          // index 2
     _service.getTopAuthors(query: trimmed),           // index 3
     _service.getDashboardOverview(query: trimmed),    // index 4
   ]);
   ```
3. Parse từng kết quả:
   - `results[0]['group_by']` → `List<YearlyTrend>`, lọc năm trong khoảng `1990..DateTime.now().year`, sort tăng dần theo năm.
   - `results[1]['results']` → `List<Work>` (top cited works).
   - `results[2]['group_by']` → `List<TopJournal>`, lọc bỏ entry rỗng tên/id.
   - `results[3]['group_by']` → `List<TopAuthor>`, lọc bỏ entry rỗng tên/id.
   - `results[4]['meta']['count']` → `totalCount` (tổng số bài báo khớp topic).
4. Tính **average citation ước lượng**: trung bình cộng `citedByCount` của `topCitedWorks` (chỉ 10 bài, **không phải trung bình toàn bộ tập dữ liệu** — xem thêm ở [04 — Dashboard](./04-dashboard.md)).
5. Build `DashboardStats.fromAnalysisData(...)` — tổng hợp dữ liệu dùng chung cho cả 4 tab và Dashboard.
6. Set state `success`, hoặc `error` nếu `ApiException`/exception khác được ném ra.

## Giao diện: AppBar + 4 tab

```dart
TabController(length: 4, vsync: this);
tabs: ['Xu hướng', 'Top Papers', 'Journals', 'Authors']
```
AppBar có icon **Dashboard** (`dashboard_rounded`) ở góc phải → `Navigator.push` sang `DashboardScreen()` — nối sang [FLOW 4](./04-dashboard.md).

`Consumer<AnalysisProvider>` quyết định nội dung body:
- `isLoading` → `LoadingWidget(message: 'Đang phân tích dữ liệu...')`
- `isError` → `AppErrorWidget` với nút "Thử lại" gọi lại `provider.analyze(widget.topic)`
- `isInitial` → `LoadingWidget(message: 'Đang chuẩn bị...')`
- Ngược lại → `TabBarView` với 4 tab dưới đây.

### Tab 1 — "Xu hướng" (`_TrendChartTab`, FR 4.3, dòng 112-261)

- Vẽ `BarChart` (`fl_chart`) số bài báo theo năm, đọc từ `provider.yearlyTrends`.
- `maxY = maxCount * 1.2` để chừa khoảng trống phía trên.
- `BarTouchTooltipData`: chạm vào cột hiện tooltip `"{year}\n{count} bài"`.
- Card "Năm xuất bản nhiều nhất" (`_buildPeakYearCard`) bên dưới chart, tính bằng `reduce` tìm `count` lớn nhất.
- **Chi tiết fix nhãn trục X** — xem mục riêng bên dưới.

### Tab 2 — "Top Papers" (`_TopPapersTab`, FR 4.4, dòng 265-309)

- `ListView` các `PublicationCard`, đọc từ `provider.topCitedWorks` (đã sort sẵn theo `cited_by_count:desc` từ API).
- Mỗi card nhận `rank: index + 1` → `PublicationCard` tự hiển thị huy chương vàng/bạc/đồng cho hạng 1-2-3.
- Tap vào 1 card → `Navigator.push` sang `PublicationDetailScreen` — nối sang [FLOW 2](./02-chi-tiet-bai-bao.md).

### Tab 3 — "Journals" (`_TopJournalsTab`, FR 4.5, dòng 313-496)

- Horizontal `BarChart`: trục Y (trái) là tên journal (rút gọn 16 ký tự qua `TextUtils.truncate`), trục X (dưới) là số bài báo.
- Mỗi bar tô màu khác nhau, lấy từ `AppColors.chartColors[index % 10]` (10 màu định nghĩa sẵn ở `constants.dart:58-69`).
- Chiều cao chart co giãn: `(journals.length * 48).clamp(200, 400)`.
- Bên dưới chart là danh sách chi tiết (`_buildJournalListItem`) — mỗi dòng có `LinearProgressIndicator` thể hiện tỷ lệ `worksCount / maxCount` (maxCount = journal hạng 1) thay vì đọc lại chart.

### Tab 4 — "Authors" (`_TopAuthorsTab`, FR 4.6, dòng 500-535)

- `ListView` dùng widget `AuthorListTile` (`lib/widgets/author_list_tile.dart`), mỗi dòng có progress bar minh họa hạng.
- Lưu ý: progress bar này là **công thức ước lượng theo hạng**, không phải % chính xác vì OpenAlex `group_by` không trả tỷ lệ phần trăm sẵn.

## Fix nhãn trục năm trên biểu đồ (commit `f6acc61`)

Đây là fix gần nhất trên branch hiện tại (`fix/ui-chip-and-chart-labels`), nằm trong `getTitlesWidget` của `bottomTitles` ở Tab 1 (`trend_analysis_screen.dart:161-184`):

**Trước đây**: dùng `interval: (trends.length / 6).ceilToDouble()` — nhưng cách tính interval của `fl_chart` áp theo giá trị trục, không đảm bảo số lượng nhãn hiển thị thực tế cách đều nhau → nhãn năm bị **chồng chữ lên nhau** khi có nhiều năm.

**Sau khi fix**: đặt `interval: 1` (cho phép mọi index được xét), rồi **tự lọc thủ công** ngay trong `getTitlesWidget`:
```dart
final step = (trends.length / 7).ceil();
final isLast = idx == trends.length - 1;
if (idx % step != 0 && !isLast) {
  return const SizedBox.shrink();
}
```
- Chỉ vẽ nhãn khi `idx % step == 0` → tối đa **~7 nhãn cách đều nhau**, không chồng chữ.
- **Luôn ép hiển thị nhãn của năm cuối cùng** (`isLast`) dù nó không rơi đúng vào step — đảm bảo người dùng luôn thấy năm mới nhất trong dữ liệu.
- Format hiển thị rút gọn 2 số cuối: `"'${year.toString().substring(2)}"` (ví dụ `2023` → `'23`).

Commit này cũng sửa 1 lỗi UI không liên quan chart: chip gợi ý topic ở Search Screen trước đó có **chữ trắng trên nền trắng** (không đọc được) → đổi sang nền trắng + chữ xanh `AppColors.primary` (`search_screen.dart:138-148`).

## Data flow tổng thể

```
TrendAnalysisScreen.initState()
        │  nếu topic mới hoặc chưa phân tích
        ▼
AnalysisProvider.analyze(topic)
        │  Future.wait([5 API calls song song])
        ▼
  ┌─────────────────┬──────────────────┬─────────────────┬──────────────────┬────────────────────┐
  │ getPublicationsByYear │ getTopCitedWorks │ getTopJournals │ getTopAuthors │ getDashboardOverview │
  │ group_by=publication_year │ sort=cited_by_count:desc │ group_by=primary_location.source.id │ group_by=authorships.author.id │ per_page=1 (chỉ lấy meta.count) │
  └─────────────────┴──────────────────┴─────────────────┴──────────────────┴────────────────────┘
        │
        ▼
Parse → yearlyTrends, topCitedWorks, topJournals, topAuthors, totalCount
        │
        ▼
DashboardStats.fromAnalysisData(...) — tổng hợp, dùng chung cho 4 tab + Dashboard
        │  set state=success, notifyListeners()
        ▼
TabBarView: 4 tab tự đọc lại provider.yearlyTrends / topCitedWorks / topJournals / topAuthors
```

## Output

4 tab dữ liệu trực quan hóa xu hướng nghiên cứu theo chủ đề: biểu đồ số bài theo năm, top 10 bài trích dẫn nhiều nhất, top 10 tạp chí, top 10 tác giả. Toàn bộ dữ liệu này được tái sử dụng ở [FLOW 4 — Dashboard](./04-dashboard.md) mà không cần gọi lại API.
