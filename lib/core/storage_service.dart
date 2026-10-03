import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> saveStringList(String key, List<String> list) async {
    await _prefs.setStringList(key, list);
  }

  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  Future<void> saveJson(String key, dynamic value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  dynamic getJson(String key) {
    final str = _prefs.getString(key);
    if (str != null) {
      try {
        return jsonDecode(str);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }
}
