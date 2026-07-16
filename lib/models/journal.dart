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
