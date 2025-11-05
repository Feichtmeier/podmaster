import 'dart:async';

import 'package:safe_change_notifier/safe_change_notifier.dart';

import 'settings_service.dart';

class SettingsManager extends SafeChangeNotifier {
  SettingsManager({required SettingsService service}) : _service = service {
    _propertiesChangedSub ??= _service.propertiesChanged.listen(
      (_) => notifyListeners(),
    );
  }
  final SettingsService _service;
  StreamSubscription<bool>? _propertiesChangedSub;

  bool? getBool(String key) => _service.getBool(key);
  Future<void> setBool(String key, bool value) => _service.setBool(key, value);

  String? getString(String key) => _service.getString(key);
  Future<void> setString(String key, String value) =>
      _service.setString(key, value);

  int? getInt(String key) => _service.getInt(key);
  Future<void> setInt(String key, int value) => _service.setInt(key, value);

  String? get downloadsDir => _service.getDownloadsDir();

  @override
  void dispose() {
    _propertiesChangedSub?.cancel();
    super.dispose();
  }
}
