import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work.dart';

// Bọc shared_preferences để lưu danh sách bài báo đã bookmark cục bộ trên
// máy — key riêng theo uid để mỗi user đăng nhập có 1 danh sách khác nhau
// trên cùng thiết bị.
class BookmarkService {
  final SharedPreferences? _prefsOverride;

  BookmarkService({SharedPreferences? prefs}) : _prefsOverride = prefs;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  String _keyFor(String uid) => 'bookmarks_$uid';

  Future<List<Work>> load(String uid) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyFor(uid));
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((j) => Work.fromJson(j))
          .toList();
    } catch (e) {
      // Dữ liệu lưu cục bộ hỏng (vd đổi shape ở bản cập nhật trước) không nên
      // làm cả app crash — coi như chưa có bookmark nào, ghi đè ở lần save kế.
      return [];
    }
  }

  Future<void> save(String uid, List<Work> works) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(works.map((w) => w.toJson()).toList());
    await prefs.setString(_keyFor(uid), encoded);
  }
}
