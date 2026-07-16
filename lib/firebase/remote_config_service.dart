import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../utils/constants.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const _maxJournalsKey = 'max_journals_displayed';
  static const _maxKeywordsKey = 'max_keywords_displayed';

  Future<void> init() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Duration.zero để demo thấy hiệu lực ngay sau khi mở lại app,
        // không phải đợi khoảng cache mặc định 12h của Remote Config.
        minimumFetchInterval: Duration.zero,
      ),
    );
    await _remoteConfig.setDefaults({
      _maxJournalsKey: AppConstants.topJournalsCount,
      _maxKeywordsKey: AppConstants.topKeywordsCount,
    });
    await _remoteConfig.fetchAndActivate();
  }

  int get maxJournalsDisplayed => _remoteConfig.getInt(_maxJournalsKey);
  int get maxKeywordsDisplayed => _remoteConfig.getInt(_maxKeywordsKey);
}
