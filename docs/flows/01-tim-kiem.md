# 01 — Luồng Tìm kiếm bài báo (Search)

> FR liên quan: **FR 4.1**
> Xem tổng quan kiến trúc tại [00 — Tổng quan](./00-tong-quan.md)

## Entry point

`SearchScreen` (`lib/screens/search_screen.dart`) — đây là màn hình **home** của app, khai báo tại `lib/main.dart:27` (`home: const SearchScreen()`).

## Các file tham gia

| File | Vai trò |
|---|---|
| `lib/screens/search_screen.dart` | Toàn bộ UI: ô nhập từ khóa, chip gợi ý, danh sách kết quả, infinite scroll |
| `lib/providers/search_provider.dart` | State management: `SearchState { initial, loading, success, error }` |
| `lib/services/openalex_service.dart` (`searchWorks()`, dòng 63-87) | Gọi HTTP GET OpenAlex |
| `lib/models/work.dart` (`Work.fromJson`) | Parse JSON response thành object `Work` |
| `lib/widgets/publication_card.dart` (`PublicationCard`) | Hiển thị từng kết quả dạng card |
| `lib/widgets/loading_widget.dart` (`SkeletonCard`) | Hiệu ứng skeleton khi đang tải |
| `lib/widgets/error_widget.dart` (`AppErrorWidget`, `EmptyResultWidget`) | Trạng thái lỗi / không có kết quả |
| `lib/utils/constants.dart` (`AppConstants.suggestedTopics`) | 8 chip chủ đề gợi ý |

## Các bước người dùng thực hiện

1. Mở app → `SearchProvider` ở trạng thái `initial` → hiển thị màn hình chào (icon kính hiển vi mờ + text "Khám phá xu hướng nghiên cứu" / "Nhập chủ đề hoặc chọn gợi ý phía trên") — `search_screen.dart:182-207`.
2. Người dùng gõ từ khóa vào `TextField` hoặc bấm 1 trong 8 **chip gợi ý** (`AppConstants.suggestedTopics`, `constants.dart:25-34`):
   `Artificial Intelligence`, `Software Engineering`, `Data Science`, `Cybersecurity`, `Internet of Things`, `Blockchain`, `Machine Learning`, `Deep Learning`.
   Bấm chip sẽ tự điền text và gọi search ngay (`search_screen.dart:146-149`).
3. Submit bằng nút **"Tìm"** hoặc nhấn Enter (`onSubmitted`) → gọi `_search()` → ẩn bàn phím (`FocusScope.unfocus()`) → `context.read<SearchProvider>().search(query)`.
4. `SearchProvider.search()` (`search_provider.dart:47-59`):
   - Bỏ qua nếu query rỗng sau khi `trim()`.
   - Reset toàn bộ state cũ: `_works = []`, `_currentPage = 1`, `_hasMore = true`, `_errorMessage = null`.
   - Set state `loading` → `notifyListeners()` → UI hiện 6 `SkeletonCard` (`_buildLoadingState`, `search_screen.dart:209-214`).
   - Gọi `_fetchWorks()`.
5. `_fetchWorks()` (`search_provider.dart:69-104`) gọi `OpenAlexService.searchWorks()`:
   - HTTP GET `/works?search={query}&filter=type:article&sort=cited_by_count:desc&per_page=50&page={page}&select=id,title,publication_year,cited_by_count,authorships,primary_location,doi,type`.
   - Parse `meta.count` → `_totalResults`.
   - Parse `results[]` → `List<Work>` qua `Work.fromJson()`, **lọc bỏ** work có `title == 'Untitled'` hoặc rỗng (dòng 84).
   - Nối vào danh sách cũ: `_works = [..._works, ...newWorks]`.
   - Xác định còn trang tiếp theo không: `_hasMore = newWorks.length >= 50`.
   - Set state `success` → `notifyListeners()`.
6. UI (`Consumer<SearchProvider>` trong `_buildBody()`) hiển thị theo state:
   - `isInitial` → màn hình chào.
   - `isLoading` (loading và chưa có work nào) → 6 `SkeletonCard`.
   - `isError` → `AppErrorWidget` với nút "Thử lại" gọi lại `provider.search(provider.currentQuery)`.
   - `works.isEmpty` (thành công nhưng 0 kết quả) → `EmptyResultWidget` "Không tìm thấy bài báo nào cho ...".
   - Ngược lại → `_buildResultsList()`: header "Tìm thấy X bài báo cho ..." + `ListView` các `PublicationCard`.
7. **Infinite scroll**: `ScrollController` lắng nghe `_onScroll()` (`search_screen.dart:38-43`) — khi cách đáy danh sách ≤ 300px thì gọi `provider.loadMore()`.
   - `loadMore()` (`search_provider.dart:62-67`): bỏ qua nếu `!hasMore` hoặc đang loading; tăng `_currentPage`, set `loading`, gọi lại `_fetchWorks()`.
   - Khi đang load more mà lỗi: giữ nguyên kết quả cũ, lùi lại `_currentPage`, tắt `_hasMore`, set state về `success` (không hiện toàn màn hình lỗi) — `search_provider.dart:97-102`.
8. Tap vào 1 `PublicationCard` → điều hướng `Navigator.push` sang `PublicationDetailScreen(work: work)` — nối sang [FLOW 2](./02-chi-tiet-bai-bao.md).
9. Có 2 điểm điều hướng sang phân tích xu hướng — nối sang [FLOW 3](./03-phan-tich-xu-huong.md):
   - Nút **"Phân tích"** trên AppBar (chỉ hiện khi `isSuccess && currentQuery.isNotEmpty`, `search_screen.dart:67-81`).
   - Nút **"Xem phân tích"** trong header kết quả (`_buildResultsHeader`, dòng 260-268).
   - Cả 2 đều gọi `_navigateToAnalysis(topic)` (dòng 51-59): gọi trước `context.read<AnalysisProvider>().analyze(topic)` rồi mới `Navigator.push` sang `TrendAnalysisScreen(topic: topic)`.

## Data flow tóm tắt

```
User input / chip tap
        │
        ▼
SearchProvider.search(query)
        │  set state=loading, reset list
        ▼
OpenAlexService.searchWorks(query, page, perPage=50)
        │  HTTP GET /works?search=...&filter=type:article
        │           &sort=cited_by_count:desc&per_page=50&page=N
        ▼
JSON response { meta: {count}, results: [...] }
        │
        ▼
results[].map(Work.fromJson) → lọc Untitled/rỗng → List<Work>
        │
        ▼
_works = [..._works, ...newWorks]; set state=success
        │  notifyListeners()
        ▼
Consumer<SearchProvider> rebuild → ListView<PublicationCard>
```

## State enum

`SearchState { initial, loading, success, error }` (`search_provider.dart:6`)

Các getter tiện ích: `isInitial`, `isLoading` (loading **và** `_works` rỗng — để phân biệt lần tải đầu với load-more), `isSuccess`, `isError`, `isLoadingMore`, `hasMore`.

## Output

Danh sách bài báo hiển thị dạng card (`PublicationCard`), có infinite scroll để tải thêm, hiển thị tổng số kết quả tìm được. Từ đây người dùng có thể đi tiếp sang xem chi tiết 1 bài báo hoặc xem phân tích xu hướng toàn bộ chủ đề.
