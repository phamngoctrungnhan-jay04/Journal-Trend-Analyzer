import 'package:flutter/foundation.dart';

import '../models/research_field.dart';
import '../services/openalex_service.dart';

// Quản lý lưới lĩnh vực ở Home: lĩnh vực nào đang mở, và danh sách lĩnh vực phụ
// của nó.
//
// 26 lĩnh vực CHÍNH không nằm ở đây — chúng viết cứng trong
// AppConstants.researchFields (bộ đầy đủ, gần như bất biến) nên Home mở ra là
// có ngay. Chỉ lĩnh vực PHỤ mới gọi API, và cache lại theo fieldId để mỗi lĩnh
// vực chỉ tốn đúng 1 request mỗi phiên — quan trọng vì quota OpenAlex có hạn.
class TaxonomyProvider extends ChangeNotifier {
  final OpenAlexService _service;

  TaxonomyProvider({OpenAlexService? service})
    : _service = service ?? OpenAlexService();

  // Chỉ mở 1 lĩnh vực tại một thời điểm — mở cái mới thì cái cũ tự đóng, tránh
  // Home bị dài ra vô tận.
  String? _expandedFieldId;
  String? get expandedFieldId => _expandedFieldId;
  bool isExpanded(String fieldId) => _expandedFieldId == fieldId;

  final Map<String, List<Subfield>> _cache = {};
  List<Subfield>? subfieldsOf(String fieldId) => _cache[fieldId];

  final Set<String> _loading = {};
  bool isLoadingSubfields(String fieldId) => _loading.contains(fieldId);

  final Map<String, String> _errors = {};
  String? errorOf(String fieldId) => _errors[fieldId];

  Future<void> toggleField(String fieldId) async {
    // Bấm lại chính lĩnh vực đang mở -> đóng lại.
    if (_expandedFieldId == fieldId) {
      _expandedFieldId = null;
      notifyListeners();
      return;
    }

    _expandedFieldId = fieldId;
    notifyListeners();

    // Đã có trong cache -> hiện ngay, không gọi lại API.
    if (_cache.containsKey(fieldId) || _loading.contains(fieldId)) return;

    await _fetchSubfields(fieldId);
  }

  Future<void> retry(String fieldId) => _fetchSubfields(fieldId);

  Future<void> _fetchSubfields(String fieldId) async {
    _loading.add(fieldId);
    _errors.remove(fieldId);
    notifyListeners();

    try {
      final result = await _service.getSubfields(fieldId: fieldId);
      final resultsJson = result['results'] as List<dynamic>? ?? [];
      _cache[fieldId] = resultsJson
          .whereType<Map<String, dynamic>>()
          .map((j) => Subfield.fromJson(j))
          .where((s) => s.id.isNotEmpty && s.displayName.isNotEmpty)
          .toList();
    } on ApiException catch (e) {
      _errors[fieldId] = e.message;
    } catch (e) {
      // Lỗi ngoài dự kiến (vd parse JSON hỏng). Thiếu nhánh này thì lỗi thoát
      // ra ngoài mà không ai bắt -> vùng expand kẹt ở spinner vĩnh viễn.
      _errors[fieldId] = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
    }

    _loading.remove(fieldId);
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
