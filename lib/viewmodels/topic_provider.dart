import 'package:flutter/foundation.dart';

// Nguồn sự thật cho "chủ đề đang phân tích" ở cấp app + lịch sử chủ đề gần đây.
// Bất kỳ tab nào (Home, Keywords) đều có thể chọn chủ đề qua đây; các tab chỉ
// hiển thị (Journals) sẽ phản chiếu theo chủ đề đang chọn. Provider này CHỈ giữ
// trạng thái điều hướng chủ đề — việc nạp dữ liệu do SearchProvider/
// AnalysisProvider lo, được kích hoạt bởi action selectTopic() ở tầng UI.
class TopicProvider extends ChangeNotifier {
  static const _maxRecent = 8;

  String _selectedTopic = '';
  String get selectedTopic => _selectedTopic;
  bool get hasTopic => _selectedTopic.isNotEmpty;

  // Chủ đề đã chọn gần đây (mới nhất ở đầu) — hiển thị dạng chip ở Home để user
  // xem lại "những chủ đề mình đã chọn" và chọn lại nhanh.
  final List<String> _recentTopics = [];
  List<String> get recentTopics => List.unmodifiable(_recentTopics);

  void select(String topic) {
    final t = topic.trim();
    if (t.isEmpty) return;
    _selectedTopic = t;
    // Đưa lên đầu, bỏ trùng (không phân biệt hoa/thường), giới hạn số lượng.
    _recentTopics.removeWhere((e) => e.toLowerCase() == t.toLowerCase());
    _recentTopics.insert(0, t);
    if (_recentTopics.length > _maxRecent) {
      _recentTopics.removeRange(_maxRecent, _recentTopics.length);
    }
    notifyListeners();
  }
}
