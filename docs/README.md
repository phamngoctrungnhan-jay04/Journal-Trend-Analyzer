# Tài liệu dự án — Journal Trend Analyzer

Bộ tài liệu này mô tả kiến trúc và từng luồng nghiệp vụ (business flow) của ứng dụng, viết dựa trên việc đọc trực tiếp source code tại nhánh `fix/ui-chip-and-chart-labels` (ngày viết: 2026-07-15).

## Mục lục

0. [Hướng dẫn chạy project & Luồng sử dụng](./huong-dan-chay.md) — cài đặt, chạy app, chạy Patrol test, navigation flow (Lab 03)
1. [00 — Tổng quan kiến trúc](./flows/00-tong-quan.md)
2. [01 — Luồng Tìm kiếm bài báo (Search)](./flows/01-tim-kiem.md) — FR 4.1
3. [02 — Luồng Xem chi tiết bài báo (Publication Detail)](./flows/02-chi-tiet-bai-bao.md) — FR 4.2
4. [03 — Luồng Phân tích xu hướng nghiên cứu (Trend Analysis)](./flows/03-phan-tich-xu-huong.md) — FR 4.3–4.6
5. [04 — Luồng Dashboard tổng quan (Research Dashboard)](./flows/04-dashboard.md) — FR 4.7

## Bản đồ điều hướng giữa các màn hình

```
SearchScreen (home)
   │  tap card                      │ nút "Phân tích" / "Xem phân tích"
   ▼                                 ▼
PublicationDetailScreen      TrendAnalysisScreen (4 tab, chọn topic)
   ▲                                 │  nút icon Dashboard (AppBar)
   │  tap "Bài báo ảnh hưởng nhất"   ▼
   └──────────────────────  DashboardScreen
```

## Quy ước chung dùng trong toàn bộ tài liệu

- **FR** = Functional Requirement, đánh số theo comment có sẵn trong `lib/services/openalex_service.dart`.
- Đường dẫn file luôn ghi tương đối từ gốc repo, kèm số dòng tại thời điểm viết tài liệu — số dòng có thể lệch nếu code thay đổi sau này.
- Ứng dụng **không có backend riêng, không có database, không có đăng nhập** — mọi dữ liệu lấy trực tiếp từ [OpenAlex API](https://api.openalex.org) công khai và chỉ tồn tại trong bộ nhớ phiên (session), mất khi tắt app.
