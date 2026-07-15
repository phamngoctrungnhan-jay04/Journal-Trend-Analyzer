# 04 — Luồng Dashboard tổng quan (Research Dashboard)

> FR liên quan: **FR 4.7**
> Xem tổng quan kiến trúc tại [00 — Tổng quan](./00-tong-quan.md)

## Entry point

`DashboardScreen` (`lib/screens/dashboard_screen.dart`) — điều hướng tới từ nút icon `dashboard_rounded` trên AppBar của [Trend Analysis Screen](./03-phan-tich-xu-huong.md) (`trend_analysis_screen.dart:57-64`). Đây là màn hình **cuối cùng** trong chuỗi điều hướng của app, không phải là điểm bắt đầu cho người dùng.

## File chính

| File | Vai trò |
|---|---|
| `lib/screens/dashboard_screen.dart` | UI tổng hợp — **không gọi API mới** |
| `lib/providers/analysis_provider.dart` | Đọc lại `dashboardStats`, `topJournals` đã được set sẵn từ [FLOW 3](./03-phan-tich-xu-huong.md) |
| `lib/models/dashboard_stats.dart` | Model `DashboardStats` — chứa toàn bộ số liệu đã tổng hợp sẵn |
| `lib/widgets/stat_card.dart` | `StatCard` — 4 ô chỉ số ở đầu trang |

## Điểm quan trọng: không có network call mới

`DashboardScreen` **hoàn toàn tái sử dụng dữ liệu đã fetch ở FLOW 3** (`AnalysisProvider.analyze()` đã chạy trước đó khi vào Trend Analysis). Không có `initState`/gọi API riêng — chỉ đọc `Consumer<AnalysisProvider>` và render lại từ state đã có.

- Nếu `provider.dashboardStats == null` (chưa từng phân tích topic nào) → hiện `EmptyResultWidget` "Chưa có dữ liệu. Hãy tìm kiếm một chủ đề trước." — trường hợp này chỉ có thể xảy ra nếu người dùng cố truy cập trực tiếp `DashboardScreen` không qua đường điều hướng bình thường (thực tế route duy nhất tới màn hình này luôn đi qua FLOW 3 nên trạng thái này gần như không xảy ra trong luồng chuẩn).
- Nút "Thử lại" khi lỗi gọi `provider.analyze(provider.currentTopic)` — **đây là lần gọi API duy nhất có thể xảy ra tại màn hình này**, và chỉ khi trạng thái trước đó là lỗi.

## Nội dung hiển thị (`_buildDashboard`, dòng 43-246)

1. **Header gradient** (`_buildTopicHeader`) — nền gradient xanh (`AppColors.primary` → `primaryLight`), hiển thị tên topic đang phân tích.
2. **Hàng 1** — 2 `StatCard`:
   - "Tổng bài báo" = `stats.totalPublications` (định dạng qua `TextUtils.formatCount`).
   - "TB trích dẫn" = `stats.formattedAvgCitation` — **xem cảnh báo về độ chính xác bên dưới**.
3. **Hàng 2** — 2 `StatCard`:
   - "Năm sôi động nhất" = `stats.mostActiveYear` (năm có `count` cao nhất trong `yearlyTrends`), kèm subtitle số bài của năm đó.
   - "Số journals" = `provider.topJournals.length` (số lượng journal có trong kết quả top 10, không phải tổng số journal thực tế của toàn bộ chủ đề).
4. **Card "Top Journal"** — journal có nhiều bài nhất (`topJournals.first`), hiển thị tên + số bài báo.
5. **Card "Top Author"** — tác giả có nhiều bài nhất (`topAuthors.first`), hiển thị avatar chữ cái đầu + tên + số bài báo.
6. **Card "Bài báo có ảnh hưởng nhất"** — `mostInfluentialPaper` = bài đầu tiên trong `topCitedWorks` (đã sort theo `cited_by_count:desc` từ API). Tap vào → `Navigator.push` sang `PublicationDetailScreen` — nối sang [FLOW 2](./02-chi-tiet-bai-bao.md).

## Cách `DashboardStats` được tổng hợp

Toàn bộ số liệu hiển thị ở đây được build **một lần** trong `AnalysisProvider.analyze()` tại [FLOW 3](./03-phan-tich-xu-huong.md), thông qua `DashboardStats.fromAnalysisData()` (`lib/models/dashboard_stats.dart:28-55`):

```dart
factory DashboardStats.fromAnalysisData({
  required String topic,
  required int totalPublications,       // từ getDashboardOverview() → meta.count
  required List<YearlyTrend> yearlyTrends,
  required List<TopJournal> topJournals,
  required List<TopAuthor> topAuthors,
  required List<Work> topCitedWorks,
  required double averageCitationCount, // xem cảnh báo bên dưới
}) {
  // mostActiveYear = năm có count lớn nhất trong yearlyTrends
  // topJournal = topJournals.first (đã sort sẵn theo worksCount desc)
  // topAuthor = topAuthors.first
  // mostInfluentialPaper = topCitedWorks.first
}
```

## ⚠️ Cảnh báo: "TB trích dẫn" là số liệu ước lượng, không chính xác tuyệt đối

`averageCitationCount` **không** phải trung bình trích dẫn trên toàn bộ tập kết quả tìm kiếm của chủ đề (có thể lên tới hàng nghìn/chục nghìn bài). Nó chỉ được tính bằng:

```dart
// analysis_provider.dart:104-111
double avgCitation = 0;
if (_topCitedWorks.isNotEmpty) {
  final total = _topCitedWorks.fold<int>(0, (sum, w) => sum + w.citedByCount);
  avgCitation = total / _topCitedWorks.length;  // chỉ chia cho 10 bài
}
```

→ Đây là **trung bình cộng của chỉ 10 bài được trích dẫn nhiều nhất** (top cited works dùng chung cho tab "Top Papers"), không đại diện cho toàn bộ tập dữ liệu. Số này sẽ luôn cao hơn đáng kể so với trung bình trích dẫn thực tế của cả chủ đề — cần hiểu đây là chỉ số "trung bình của top 10 bài nổi bật nhất", không phải "trung bình toàn ngành".

## Data flow tóm tắt

```
AnalysisProvider.dashboardStats (đã được set từ FLOW 3, không gọi API mới)
        │
        ▼
DashboardScreen đọc Consumer<AnalysisProvider>
        │
        ├── null?           → EmptyResultWidget
        ├── isError?         → AppErrorWidget (nút Thử lại → gọi lại analyze())
        └── có dữ liệu       → _buildDashboard(): render StatCard + các Card insight
                                     │  tap "Bài báo ảnh hưởng nhất"
                                     ▼
                            PublicationDetailScreen (FLOW 2)
```

## Output

Màn hình tổng hợp các chỉ số insight quan trọng nhất về 1 chủ đề nghiên cứu: tổng số bài, trung bình trích dẫn (ước lượng), năm sôi động nhất, số journal, top journal, top tác giả, và bài báo ảnh hưởng nhất — tất cả lấy lại từ dữ liệu đã phân tích ở FLOW 3, không tốn thêm network call.
