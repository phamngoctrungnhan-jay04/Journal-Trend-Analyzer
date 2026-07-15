import 'author.dart';
import 'journal.dart';
import '../utils/text_utils.dart';

// Model chính đại diện cho 1 bài báo khoa học từ OpenAlex
class Work {
  final String id;
  final String title;
  final int? publicationYear;
  final int citedByCount;
  final List<Authorship> authorships;
  final PrimaryLocation primaryLocation;
  final String? doi;
  final String? abstractText; // đã được decode từ inverted index

  const Work({
    required this.id,
    required this.title,
    this.publicationYear,
    required this.citedByCount,
    required this.authorships,
    required this.primaryLocation,
    this.doi,
    this.abstractText,
  });

  factory Work.fromJson(Map<String, dynamic> json) {
    // Parse authorships: List<dynamic> → List<Authorship>
    final authorshipsJson = json['authorships'] as List<dynamic>? ?? [];
    final authorships = authorshipsJson
        .whereType<Map<String, dynamic>>()
        .map((a) => Authorship.fromJson(a))
        .toList();

    // Parse abstract từ inverted index (nếu có)
    final invertedIndex =
        json['abstract_inverted_index'] as Map<String, dynamic>?;
    final abstractText = TextUtils.decodeAbstract(invertedIndex);

    return Work(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      publicationYear: json['publication_year'] as int?,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      authorships: authorships,
      primaryLocation: PrimaryLocation.fromJson(
        json['primary_location'] as Map<String, dynamic>?,
      ),
      doi: json['doi'] as String?,
      abstractText: abstractText,
    );
  }

  // Tên tác giả đầu tiên (dùng hiển thị nhanh trong card)
  String get firstAuthorName {
    if (authorships.isEmpty) return 'Unknown Author';
    return authorships.first.author.displayName;
  }

  // Danh sách tất cả tên tác giả
  List<String> get authorNames =>
      authorships.map((a) => a.author.displayName).toList();

  // Tên journal rút gọn để hiển thị
  String get journalName => primaryLocation.journalName;

  // URL DOI đầy đủ
  String? get doiUrl {
    if (doi == null) return null;
    if (doi!.startsWith('http')) return doi;
    return 'https://doi.org/$doi';
  }

  // "Link gốc" - trang bài báo tại nhà xuất bản (khác DOI resolver ở nhiều
  // trường hợp). Fallback sang doiUrl nếu OpenAlex không trả landing_page_url.
  String? get landingPageUrl => primaryLocation.landingPageUrl ?? doiUrl;
}

// Dùng cho FR 4.3 - Trend by Year
// group_by publication_year trả về: {key: "2023", count: 150}
class YearlyTrend {
  final int year;
  final int count;

  const YearlyTrend({required this.year, required this.count});

  factory YearlyTrend.fromGroupByJson(Map<String, dynamic> json) {
    return YearlyTrend(
      year: int.tryParse(json['key'] as String? ?? '0') ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }
}
