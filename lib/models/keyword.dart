// Skeleton cho Stage 0 — entity mới của Lab 03, chưa có ở Lab 02.
//
// TODO (Stage 2): xác nhận field OpenAlex phù hợp (concepts hay topics)
// trước khi hoàn thiện factory fromJson/fromGroupByJson, vì hiện tại app
// chỉ tìm kiếm bằng chuỗi "topic" tự do, chưa có entity Keyword có tracking
// riêng (trending, trend theo thời gian, rank tác giả theo keyword).
class Keyword {
  final String id;
  final String displayName;
  final int worksCount;

  const Keyword({
    required this.id,
    required this.displayName,
    required this.worksCount,
  });
}
