// Đại diện cho 1 tác giả trong OpenAlex
class Author {
  final String id;
  final String displayName;

  const Author({
    required this.id,
    required this.displayName,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Unknown Author',
    );
  }
}

// Đại diện cho 1 mục trong danh sách authorships của 1 Work
// (1 authorship = 1 tác giả + vị trí của họ trong bài báo)
class Authorship {
  final Author author;
  final String? authorPosition; // "first", "middle", "last"

  const Authorship({
    required this.author,
    this.authorPosition,
  });

  factory Authorship.fromJson(Map<String, dynamic> json) {
    return Authorship(
      author: Author.fromJson(
        json['author'] as Map<String, dynamic>? ?? {},
      ),
      authorPosition: json['author_position'] as String?,
    );
  }
}

// Dùng cho màn hình Top Contributing Authors (FR 4.6)
// group_by trả về: {key: "authorId", key_display_name: "Tên", count: 42}
class TopAuthor {
  final String id;
  final String displayName;
  final int worksCount;

  const TopAuthor({
    required this.id,
    required this.displayName,
    required this.worksCount,
  });

  factory TopAuthor.fromGroupByJson(Map<String, dynamic> json) {
    return TopAuthor(
      id: json['key'] as String? ?? '',
      displayName: json['key_display_name'] as String? ?? 'Unknown Author',
      worksCount: json['count'] as int? ?? 0,
    );
  }
}
