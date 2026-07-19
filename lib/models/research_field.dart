import 'research_scope.dart';

// Lĩnh vực phụ (tầng `subfields` của OpenAlex) — nạp từ API khi user mở 1 lĩnh
// vực chính. Chỉ giữ id + tên; số bài báo để AnalysisProvider lo sau khi chọn.
class Subfield {
  final String id;
  final String displayName;

  const Subfield({required this.id, required this.displayName});

  factory Subfield.fromJson(Map<String, dynamic> json) {
    // OpenAlex trả id dạng URL đầy đủ "https://openalex.org/subfields/1712";
    // filter chỉ nhận phần số nên cắt lấy đoạn cuối.
    final rawId = json['id'] as String? ?? '';
    return Subfield(
      id: rawId.startsWith('https://') ? rawId.split('/').last : rawId,
      displayName: json['display_name'] as String? ?? 'Unknown Subfield',
    );
  }

  ResearchScope toScope(String parentLabel) => ResearchScope.subfield(
    id: id,
    label: displayName,
    parentLabel: parentLabel,
  );
}

// Một gợi ý trả về từ ô tìm kiếm (tầng `topics` — sâu nhất, 4.516 cái). Mang
// theo đường dẫn cha để hiện breadcrumb: user gõ "blockchain" là thấy ngay nó
// nằm ở Computer Science › Information Systems, tức ô tìm kiếm vừa tìm hộ vừa
// dạy cấu trúc cây.
class TopicSuggestion {
  final String id;
  final String displayName;
  final String fieldLabel;
  final String subfieldLabel;
  final int worksCount;

  const TopicSuggestion({
    required this.id,
    required this.displayName,
    required this.fieldLabel,
    required this.subfieldLabel,
    required this.worksCount,
  });

  factory TopicSuggestion.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? '';
    final subfield = json['subfield'] as Map<String, dynamic>? ?? {};
    final field = json['field'] as Map<String, dynamic>? ?? {};
    return TopicSuggestion(
      // OpenAlex trả "https://openalex.org/T10270"; filter chỉ nhận "T10270".
      id: rawId.startsWith('https://') ? rawId.split('/').last : rawId,
      displayName: json['display_name'] as String? ?? 'Unknown Topic',
      fieldLabel: field['display_name'] as String? ?? '',
      subfieldLabel: subfield['display_name'] as String? ?? '',
      worksCount: json['works_count'] as int? ?? 0,
    );
  }

  String get breadcrumb =>
      [fieldLabel, subfieldLabel].where((s) => s.isNotEmpty).join(' › ');

  // parentLabel dùng breadcrumb đầy đủ để màn hình nào cũng biết topic này
  // thuộc nhánh nào mà không phải tra ngược.
  ResearchScope toScope() =>
      ResearchScope.topic(id: id, label: displayName, parentLabel: breadcrumb);
}
