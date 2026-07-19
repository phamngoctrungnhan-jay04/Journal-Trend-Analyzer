import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/remote_config_service.dart';
import '../utils/constants.dart';

// App-level (đăng ký trong MultiProvider) - giá trị áp dụng chung cho
// Journals/Keywords, chỉ cần fetch 1 lần khi app khởi động.
class RemoteConfigProvider extends ChangeNotifier {
  final RemoteConfigService _service;
  final SharedPreferences? _prefsOverride;

  RemoteConfigProvider({RemoteConfigService? service, SharedPreferences? prefs})
    : _service = service ?? RemoteConfigService(),
      _prefsOverride = prefs {
    unawaited(_init());
  }

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  // Key lưu override CỤC BỘ trên máy cho max_papers_displayed — khác với giá
  // trị fetch từ Firebase Remote Config (áp dụng chung mọi user), override
  // này chỉ ảnh hưởng thiết bị hiện tại, cho phép chỉnh trực tiếp trong
  // Profile mà không cần vào Firebase Console.
  static const _maxPapersOverrideKey = 'override_max_papers_displayed';

  // Giá trị mặc định = hằng số cũ, giữ hành vi hiện tại cho tới khi
  // fetch xong.
  int _maxJournalsDisplayed = AppConstants.topJournalsCount;
  int get maxJournalsDisplayed => _maxJournalsDisplayed;

  int _maxKeywordsDisplayed = AppConstants.topKeywordsCount;
  int get maxKeywordsDisplayed => _maxKeywordsDisplayed;

  int _maxPapersFromRemote = AppConstants.journalWorksPerPage;
  int? _maxPapersOverride;

  // Override cục bộ (nếu có) LUÔN thắng giá trị fetch từ Remote Config —
  // đúng ý nghĩa "chỉnh trong app" phải thấy hiệu lực ngay trên máy đó.
  int get maxPapersDisplayed => _maxPapersOverride ?? _maxPapersFromRemote;
  bool get hasMaxPapersOverride => _maxPapersOverride != null;

  Future<void> _init() async {
    final prefs = await _prefs;
    _maxPapersOverride = prefs.getInt(_maxPapersOverrideKey);

    await _service.init();
    _maxJournalsDisplayed = _service.maxJournalsDisplayed;
    _maxKeywordsDisplayed = _service.maxKeywordsDisplayed;
    _maxPapersFromRemote = _service.maxPapersDisplayed;
    notifyListeners();
  }

  Future<void> setMaxPapersDisplayedOverride(int value) async {
    _maxPapersOverride = value;
    notifyListeners();
    final prefs = await _prefs;
    await prefs.setInt(_maxPapersOverrideKey, value);
  }

  Future<void> resetMaxPapersDisplayedOverride() async {
    _maxPapersOverride = null;
    notifyListeners();
    final prefs = await _prefs;
    await prefs.remove(_maxPapersOverrideKey);
  }
}
