// Entity Keyword của Lab 03 — dùng field `topics` của OpenAlex (không dùng
// `concepts`, đã bị OpenAlex deprecate). group_by=topics.id trả về cùng
// hình dạng {key, key_display_name, count} như primary_location.source.id
// và authorships.author.id đã dùng cho Journal/Author.
class Keyword {
  final String id;
  final String displayName;
  final int worksCount;

  const Keyword({
    required this.id,
    required this.displayName,
    required this.worksCount,
  });

  factory Keyword.fromGroupByJson(Map<String, dynamic> json) {
    return Keyword(
      id: json['key'] as String? ?? '',
      displayName: json['key_display_name'] as String? ?? 'Unknown Keyword',
      worksCount: json['count'] as int? ?? 0,
    );
  }
}
