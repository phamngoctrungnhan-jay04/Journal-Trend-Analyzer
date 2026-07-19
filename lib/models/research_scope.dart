// Phạm vi nghiên cứu đang phân tích — nguồn sự thật cho MỌI truy vấn OpenAlex
// của app. Trước đây vai trò này do một String `topic` đảm nhiệm, nhưng nó phải
// gánh hai việc khác hẳn nhau: vừa là tham số gọi API, vừa là nhãn hiển thị
// (breadcrumb, tiêu đề PDF, tham số Analytics). Khi chuyển sang chọn lĩnh vực
// theo ID của OpenAlex thì hai vai đó tách hẳn: API cần `filter=...id:1712`
// còn người dùng cần thấy chữ "Software". Class này giữ cả hai lại một chỗ.
enum ScopeKind {
  // Lĩnh vực chính (26 cái) — tầng `fields` của OpenAlex.
  field,
  // Lĩnh vực phụ (252 cái) — tầng `subfields`, nằm trong 1 field.
  subfield,
  // Chủ đề hẹp (4.516 cái) — tầng `topics`, tầng sâu nhất. Đây là thứ ô tìm
  // kiếm trả về: gõ "blockchain" -> chọn topic "Blockchain Technology
  // Applications and Security".
  topic,
}

class ResearchScope {
  final ScopeKind kind;

  // ID số của OpenAlex ("17" cho field, "1712" cho subfield). Rỗng với text.
  final String id;

  // Nhãn hiển thị cho người dùng — cũng là giá trị đưa vào DashboardStats.topic
  // (tiêu đề PDF, tên file export, tham số Analytics).
  final String label;

  // Tên lĩnh vực chính cha, chỉ có khi kind == subfield → dựng breadcrumb
  // "Computer Science › Software" mà không phải tra ngược cây.
  final String? parentLabel;

  const ResearchScope._({
    required this.kind,
    required this.id,
    required this.label,
    this.parentLabel,
  });

  const ResearchScope.field({required String id, required String label})
    : this._(kind: ScopeKind.field, id: id, label: label);

  const ResearchScope.subfield({
    required String id,
    required String label,
    required String parentLabel,
  }) : this._(
         kind: ScopeKind.subfield,
         id: id,
         label: label,
         parentLabel: parentLabel,
       );

  const ResearchScope.topic({
    required String id,
    required String label,
    required String parentLabel,
  }) : this._(
         kind: ScopeKind.topic,
         id: id,
         label: label,
         parentLabel: parentLabel,
       );

  // Mảnh filter ghép vào `filter=` của OpenAlex. KHÔNG bao giờ null: mọi phạm
  // vi đều nằm trong cây phân loại, kể cả khi user tìm bằng ô search (ô đó tìm
  // trong cây chứ không search full-text các bài báo).
  //
  // Đây là điểm mấu chốt giữ cho số liệu đúng phạm vi. `search=blockchain`
  // quét full-text toàn OpenAlex ra 246.708 bài — gồm cả bài chỉ nhắc thoáng
  // qua; còn `primary_topic.id:T10270` ra 51.340 bài THỰC SỰ về blockchain.
  //
  // Dùng primary_topic.* (chủ đề CHÍNH của bài) thay vì topics.* (mọi chủ đề
  // liên quan): mỗi bài chỉ thuộc đúng 1 nhánh nên số đếm không bị trùng.
  String get filterFragment => switch (kind) {
    ScopeKind.field => 'primary_topic.field.id:$id',
    ScopeKind.subfield => 'primary_topic.subfield.id:$id',
    ScopeKind.topic => 'primary_topic.id:$id',
  };

  // Nhãn đầy đủ có ngữ cảnh cha, dùng ở subtitle của Journals/Keywords.
  String get fullLabel => parentLabel != null ? '$parentLabel › $label' : label;

  @override
  bool operator ==(Object other) =>
      other is ResearchScope &&
      other.kind == kind &&
      other.id == id &&
      other.label == label;

  @override
  int get hashCode => Object.hash(kind, id, label);
}
