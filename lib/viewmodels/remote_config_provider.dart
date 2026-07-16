import 'dart:async';
import 'package:flutter/foundation.dart';

import '../firebase/remote_config_service.dart';
import '../utils/constants.dart';

// App-level (đăng ký trong MultiProvider) - giá trị áp dụng chung cho
// Journals/Keywords, chỉ cần fetch 1 lần khi app khởi động.
class RemoteConfigProvider extends ChangeNotifier {
  final RemoteConfigService _service;

  RemoteConfigProvider({RemoteConfigService? service})
      : _service = service ?? RemoteConfigService() {
    unawaited(_init());
  }

  // Giá trị mặc định = hằng số cũ, giữ hành vi hiện tại cho tới khi
  // fetch xong.
  int _maxJournalsDisplayed = AppConstants.topJournalsCount;
  int get maxJournalsDisplayed => _maxJournalsDisplayed;

  int _maxKeywordsDisplayed = AppConstants.topKeywordsCount;
  int get maxKeywordsDisplayed => _maxKeywordsDisplayed;

  Future<void> _init() async {
    await _service.init();
    _maxJournalsDisplayed = _service.maxJournalsDisplayed;
    _maxKeywordsDisplayed = _service.maxKeywordsDisplayed;
    notifyListeners();
  }
}
