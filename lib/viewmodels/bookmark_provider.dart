import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../services/bookmark_service.dart';

// State bookmark toàn app (đăng ký ở MultiProvider, không phải scoped riêng
// 1 màn) — icon bookmark ở màn chi tiết bài báo VÀ danh sách ở Profile đều
// đọc chung 1 nguồn, tự đồng bộ qua notifyListeners().
class BookmarkProvider extends ChangeNotifier {
  final BookmarkService _service;

  BookmarkProvider({BookmarkService? service})
    : _service = service ?? BookmarkService();

  String? _uid;
  List<Work> _bookmarks = [];
  List<Work> get bookmarks => _bookmarks;

  Future<void> loadForUser(String uid) async {
    _uid = uid;
    _bookmarks = await _service.load(uid);
    notifyListeners();
  }

  bool isBookmarked(String workId) => _bookmarks.any((w) => w.id == workId);

  Future<void> toggle(Work work) async {
    final uid = _uid;
    if (uid == null) return;

    if (isBookmarked(work.id)) {
      _bookmarks = _bookmarks.where((w) => w.id != work.id).toList();
    } else {
      _bookmarks = [work, ..._bookmarks];
    }
    notifyListeners();
    await _service.save(uid, _bookmarks);
  }

  Future<void> remove(String workId) async {
    final uid = _uid;
    if (uid == null) return;

    _bookmarks = _bookmarks.where((w) => w.id != workId).toList();
    notifyListeners();
    await _service.save(uid, _bookmarks);
  }
}
