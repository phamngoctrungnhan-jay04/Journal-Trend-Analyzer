// Nguồn xuất bản (journal/conference) trong primary_location của 1 Work
class JournalSource {
  final String id;
  final String displayName;
  final bool isOa; // open access hay không

  const JournalSource({
    required this.id,
    required this.displayName,
    this.isOa = false,
  });

  factory JournalSource.fromJson(Map<String, dynamic> json) {
    return JournalSource(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Unknown Journal',
      isOa: json['is_oa'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'is_oa': isOa,
  };
}

// primary_location của 1 Work — chứa thông tin nguồn đăng
class PrimaryLocation {
  final JournalSource? source;
  final String? landingPageUrl; // "link gốc" - trang bài báo tại nhà xuất bản
  final String? pdfUrl;

  const PrimaryLocation({this.source, this.landingPageUrl, this.pdfUrl});

  factory PrimaryLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PrimaryLocation();
    final sourceJson = json['source'] as Map<String, dynamic>?;
    return PrimaryLocation(
      source: sourceJson != null ? JournalSource.fromJson(sourceJson) : null,
      landingPageUrl: json['landing_page_url'] as String?,
      pdfUrl: json['pdf_url'] as String?,
    );
  }

  String get journalName => source?.displayName ?? 'Unknown Journal';

  Map<String, dynamic> toJson() => {
    if (source != null) 'source': source!.toJson(),
    if (landingPageUrl != null) 'landing_page_url': landingPageUrl,
    if (pdfUrl != null) 'pdf_url': pdfUrl,
  };
}

// Dùng cho màn hình Top Research Journals (FR 4.5)
// group_by trả về: {key: "sourceId", key_display_name: "Tên Journal", count: 120}
class TopJournal {
  final String id;
  final String displayName;
  final int worksCount;

  const TopJournal({
    required this.id,
    required this.displayName,
    required this.worksCount,
  });

  factory TopJournal.fromGroupByJson(Map<String, dynamic> json) {
    return TopJournal(
      id: json['key'] as String? ?? '',
      displayName: json['key_display_name'] as String? ?? 'Unknown Journal',
      worksCount: json['count'] as int? ?? 0,
    );
  }
}

// Kết quả từ ô tìm kiếm journal trực tiếp (JournalSearchField, /sources) —
// khác TopJournal (đó là xếp hạng journal THEO 1 LĨNH VỰC, cái này tìm
// journal không cần chọn lĩnh vực trước).
class JournalSuggestion {
  final String id;
  final String displayName;
  final int worksCount;
  final String publisherName;

  const JournalSuggestion({
    required this.id,
    required this.displayName,
    required this.worksCount,
    required this.publisherName,
  });

  factory JournalSuggestion.fromJson(Map<String, dynamic> json) {
    // OpenAlex trả id dạng URL đầy đủ "https://openalex.org/S137773608";
    // JournalDetailScreen/getWorksByJournal chỉ cần phần cuối.
    final rawId = json['id'] as String? ?? '';
    return JournalSuggestion(
      id: rawId.startsWith('https://') ? rawId.split('/').last : rawId,
      displayName: json['display_name'] as String? ?? 'Unknown Journal',
      worksCount: json['works_count'] as int? ?? 0,
      publisherName: json['host_organization_name'] as String? ?? '',
    );
  }

  // JournalDetailScreen nhận TopJournal (dùng chung với luồng "xếp hạng theo
  // lĩnh vực" cũ) — quy về cùng 1 shape để màn chi tiết không cần biết journal
  // đến từ tìm kiếm trực tiếp hay từ FR 4.5.
  TopJournal toTopJournal() =>
      TopJournal(id: id, displayName: displayName, worksCount: worksCount);
}

// Metadata đầy đủ của 1 journal từ /sources/{id} — dùng làm header thống kê
// cho JournalDetailScreen: publisher, h-index, năm hoạt động, OA, homepage.
class JournalDetail {
  final String id;
  final String displayName;
  final String publisherName;
  final int worksCount;
  final int citedByCount;
  final int? hIndex;
  final bool isOa;
  final int? firstPublicationYear;
  final int? lastPublicationYear;
  final String? homepageUrl;

  const JournalDetail({
    required this.id,
    required this.displayName,
    required this.publisherName,
    required this.worksCount,
    required this.citedByCount,
    this.hIndex,
    this.isOa = false,
    this.firstPublicationYear,
    this.lastPublicationYear,
    this.homepageUrl,
  });

  factory JournalDetail.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? '';
    final summaryStats = json['summary_stats'] as Map<String, dynamic>? ?? {};
    return JournalDetail(
      id: rawId.startsWith('https://') ? rawId.split('/').last : rawId,
      displayName: json['display_name'] as String? ?? 'Unknown Journal',
      publisherName: json['host_organization_name'] as String? ?? '',
      worksCount: json['works_count'] as int? ?? 0,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      hIndex: summaryStats['h_index'] as int?,
      isOa: json['is_oa'] as bool? ?? false,
      firstPublicationYear: json['first_publication_year'] as int?,
      lastPublicationYear: json['last_publication_year'] as int?,
      homepageUrl: json['homepage_url'] as String?,
    );
  }
}

// 1 mục trong group_by=biblio.volume của getRecentVolumes — {key: "634",
// count: 319}.
class JournalVolume {
  final String volume;
  final int worksCount;

  const JournalVolume({required this.volume, required this.worksCount});

  factory JournalVolume.fromGroupByJson(Map<String, dynamic> json) {
    return JournalVolume(
      volume: json['key'] as String? ?? '',
      worksCount: json['count'] as int? ?? 0,
    );
  }

  // Đa số volume là số, nhưng vài journal đánh số kiểu "Suppl 1" — không
  // parse được thì trả null để nơi sắp xếp đẩy xuống cuối thay vì crash.
  int? get numericVolume => int.tryParse(volume);
}
