import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xdg_directories/xdg_directories.dart';

import '../app/app_config.dart';
import '../common/platforms.dart';
import '../extensions/shared_preferences_x.dart';

class SettingsService {
  SettingsService({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  Future<void> init() async {
    _downloadsDefaultDir = await getDownloadsDefaultDir();
  }

  final SharedPreferences _sharedPreferences;
  final _propertiesChangedController = StreamController<bool>.broadcast();
  Stream<bool> get propertiesChanged => _propertiesChangedController.stream;
  bool notify(bool saved) {
    if (saved) _propertiesChangedController.add(true);
    return saved;
  }

  bool? getBool(String key) => _sharedPreferences.getBool(key);
  Future<void> setBool(String key, bool value) =>
      _sharedPreferences.setBool(key, value).then(notify);

  String? getString(String key) => _sharedPreferences.getString(key);
  Future<void> setString(String key, String value) =>
      _sharedPreferences.setString(key, value).then(notify);

  int? getInt(String key) => _sharedPreferences.getInt(key);
  Future<void> setInt(String key, int value) =>
      _sharedPreferences.setInt(key, value).then(notify);

  String? getDownloadsDir() =>
      getString(SPKeys.downloads) ?? _downloadsDefaultDir;

  String? _downloadsDefaultDir;
  Future<String?> getDownloadsDefaultDir() async {
    String? path;
    if (Platforms.isLinux) {
      path = getUserDirectory('DOWNLOAD')?.path;
    } else if (Platforms.isMacOS || Platforms.isIOS || Platforms.isWindows) {
      path = (await getDownloadsDirectory())?.path;
    } else if (Platforms.isAndroid) {
      final androidDir = Directory('/storage/emulated/0/Download');
      if (androidDir.existsSync()) {
        path = androidDir.path;
      }
    }
    if (path != null) {
      return p.join(path, AppConfig.appName);
    }
    return null;
  }

  Future<void> dispose() async => _propertiesChangedController.close();
}
