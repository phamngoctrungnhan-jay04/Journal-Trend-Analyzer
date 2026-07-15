# 02 — Luồng Xem chi tiết bài báo (Publication Detail)

> FR liên quan: **FR 4.2**
> Xem tổng quan kiến trúc tại [00 — Tổng quan](./00-tong-quan.md)

## Entry point

`PublicationDetailScreen` (`lib/screens/publication_detail_screen.dart`) — không phải là màn hình độc lập có route riêng, mà luôn được `Navigator.push` kèm theo một object `Work` đã có sẵn, từ 3 nơi:

1. Tap 1 `PublicationCard` ở [Search Screen](./01-tim-kiem.md) (`search_screen.dart:234-239`).
2. Tap 1 `PublicationCard` (có rank huy chương) ở tab "Top Papers" trong [Trend Analysis](./03-phan-tich-xu-huong.md) (`trend_analysis_screen.dart:295-301`).
3. Tap card "Bài báo có ảnh hưởng nhất" ở [Dashboard](./04-dashboard.md) (`dashboard_screen.dart:178-185`).

## File chính

| File | Vai trò |
|---|---|
| `lib/screens/publication_detail_screen.dart` | `StatelessWidget` nhận `Work work` qua constructor, tự vẽ toàn bộ UI, **không gọi API** |
| `lib/models/work.dart` | Model `Work` — cung cấp sẵn các field/getter được hiển thị |
| `lib/utils/text_utils.dart` | `formatCount()` để hiển thị số trích dẫn dạng "1.5K" |

## Điểm quan trọng: không có network call mới

Khác với 1 app "chi tiết" điển hình (thường gọi API `GET /works/{id}` để lấy đầy đủ dữ liệu), màn hình này **tái sử dụng luôn object `Work` đã có sẵn trong bộ nhớ** từ danh sách trước đó — không gọi lại API.

- `OpenAlexService.getWorkById()` (`openalex_service.dart:90-98`, comment ghi "FR 4.2 — Chi tiết 1 bài báo (có thêm abstract)") **tồn tại trong service nhưng không được gọi ở bất kỳ đâu trong UI hiện tại**. Đây có vẻ là API dự phòng chưa được nối vào luồng, dùng để lấy thêm dữ liệu chi tiết hơn (ví dụ abstract đầy đủ hơn nếu bị thiếu, related works...).
- Hệ quả: nếu `Work` gốc lấy từ `searchWorks()` không có field `abstract_inverted_index` trong `select` (thực tế `select` của `searchWorks()` **không** yêu cầu field này — xem `openalex_service.dart:74-83`), thì `abstractText` sẽ là `null` và card "Tóm tắt" sẽ **không hiển thị**.

## Các bước / nội dung hiển thị

`build()` (`publication_detail_screen.dart:13-49`) dựng theo thứ tự:

1. **AppBar**: tiêu đề "Chi tiết bài báo" + icon "Mở DOI" ở góc phải (chỉ hiện nếu `work.doiUrl != null`).
2. **Title card** (`_buildTitleCard`, dòng 51-96): badge "Article" + năm xuất bản (góc phải) + tiêu đề bài báo (`AppTextStyles.heading2`) + tên journal in nghiêng (`work.journalName`).
3. **Meta grid** (`_buildMetaGrid`, dòng 98-129): 3 ô ngang nhau —
   - Số trích dẫn (`TextUtils.formatCount(work.citedByCount)`)
   - Số tác giả (`work.authorships.length`)
   - Năm xuất bản (`work.publicationYear` hoặc "N/A")
4. **Authors card** (`_buildAuthorsCard`, dòng 159-215): liệt kê từng tác giả với avatar chữ cái đầu (màu xoay vòng theo `AppColors.chartColors`), badge **"First"** nếu `authorPosition == 'first'`, badge **"Last"** nếu `authorPosition == 'last'`.
5. **Abstract card** (`_buildAbstractCard`, dòng 231-254): chỉ hiển thị nếu `work.abstractText != null` — text đã được giải mã từ `abstract_inverted_index` (OpenAlex trả abstract dưới dạng inverted index để tiết kiệm băng thông; `TextUtils.decodeAbstract()` trong `lib/utils/text_utils.dart:6-25` ráp lại thành câu bình thường bằng cách sort vị trí từ).
6. **DOI card** (`_buildDoiCard`, dòng 256-274): chỉ hiển thị nếu `work.doiUrl != null` — hiển thị URL DOI, tap vào (hoặc bấm icon "Mở DOI" trên AppBar) → `_copyDoi()`.

## Hành vi "Mở DOI" — chỉ copy, không mở trình duyệt

`_copyDoi()` (dòng 276-285):
```dart
Clipboard.setData(ClipboardData(text: work.doiUrl!));
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Đã sao chép DOI vào clipboard')),
);
```
→ **Chỉ copy chuỗi URL vào clipboard**, hiện SnackBar xác nhận. Không dùng `url_launcher` hay bất kỳ cơ chế deep-link nào để mở trình duyệt thật — người dùng phải tự dán link ra ngoài.

## Data flow tóm tắt

```
Work object (đã có từ Search / Top Papers / Dashboard)
        │  Navigator.push(MaterialPageRoute(... PublicationDetailScreen(work: work)))
        ▼
PublicationDetailScreen (StatelessWidget)
        │  đọc trực tiếp field/getter của work — KHÔNG gọi HTTP
        ▼
Hiển thị: title, meta grid, authors, abstract (nếu có), DOI (nếu có)
```

## Output

Trang chi tiết đầy đủ thông tin 1 bài báo: tiêu đề, journal, năm, số trích dẫn, danh sách đầy đủ tác giả (kèm vai trò First/Last), tóm tắt (nếu có dữ liệu), và DOI có thể copy.
