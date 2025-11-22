import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../common/logging.dart';
import '../common/platforms.dart';
import '../extensions/shared_preferences_x.dart';

class SettingsService {
  SettingsService({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferences _sharedPreferences;
  String? _downloadsDefaultDir;

  String? get downloadsDir =>
      getString(SPKeys.downloads) ?? _downloadsDefaultDir;

  Future<void> init() async =>
      _downloadsDefaultDir ??= await PlatformX.getDownloadsDefaultDir();

  String? getString(String key) {
    try {
      return _sharedPreferences.getString(key);
    } on Exception catch (e, s) {
      printMessageInDebugMode(e, s);
      return null;
    }
  }

  bool? getBool(String key) {
    try {
      return _sharedPreferences.getBool(key);
    } on Exception catch (e, s) {
      printMessageInDebugMode(e, s);
      return null;
    }
  }

  double? getDouble(String key) {
    try {
      return _sharedPreferences.getDouble(key);
    } on Exception catch (e, s) {
      printMessageInDebugMode(e, s);
      return null;
    }
  }

  int? getInt(String key) {
    try {
      return _sharedPreferences.getInt(key);
    } on Exception catch (e, s) {
      printMessageInDebugMode(e, s);
      return null;
    }
  }

  List<String>? getStringList(String key) {
    try {
      return _sharedPreferences.getStringList(key);
    } on Exception catch (e, s) {
      printMessageInDebugMode(e, s);
      return null;
    }
  }

  Future<bool> setValue(String key, dynamic value) {
    try {
      return switch (value) {
        (bool _) => _sharedPreferences.setBool(key, value),
        (String _) => _sharedPreferences.setString(key, value),
        (int _) => _sharedPreferences.setInt(key, value),
        (double _) => _sharedPreferences.setDouble(key, value),
        (List<String> _) => _sharedPreferences.setStringList(key, value),
        _ => Future.error('Unsupported value type: ${value.runtimeType}'),
      };
    } on Exception catch (e, s) {
      printMessageInDebugMode(e, s);
      return Future.error(e, s);
    }
  }
}
