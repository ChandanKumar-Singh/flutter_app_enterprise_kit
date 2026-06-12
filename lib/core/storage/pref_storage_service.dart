import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefStorageService {
  PrefStorageService._();
  static final PrefStorageService instance = PrefStorageService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  SharedPreferences get prefs {
    assert(_initialized, 'Call PrefStorageService.instance.init() first');
    return _prefs;
  }

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setDouble(String key, double value) => _prefs.setDouble(key, value);
  double? getDouble(String key) => _prefs.getDouble(key);

  Future<bool> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));
  Map<String, dynamic>? getJson(String key) {
    final s = _prefs.getString(key);
    return s != null ? jsonDecode(s) as Map<String, dynamic> : null;
  }

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
  bool containsKey(String key) => _prefs.containsKey(key);
}
