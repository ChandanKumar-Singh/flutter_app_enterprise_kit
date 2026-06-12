// ─── AppEncryptedStorage ──────────────────────────────────────────────────────
// AES-256 GCM encrypted key-value storage.
//
// Architecture:
//   • Key management:  flutter_secure_storage holds the AES encryption key
//   • Data storage:    shared_preferences holds AES-encrypted+base64 values
//   • Cipher:          AES-256 GCM (authenticated encryption, tamper-proof)
//   • API:             mirrors SharedPreferences for easy drop-in use
//
// Use for:
//   - Sensitive business data (balance, PII, documents)
//   - Offline-encrypted cache
//   - Anything beyond what flutter_secure_storage handles
//     (flutter_secure_storage has per-value overhead; this is better for bulk)
//
// Usage:
//   final storage = AppEncryptedStorage.instance;
//   await storage.initialize();
//
//   await storage.setString('user_token', 'eyJ...');
//   final token = await storage.getString('user_token');
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kKeyStorageKey  = 'app_enc_storage_master_key';
const _kPrefixDefault  = 'enc_'; // prefix in SharedPreferences

// ── Encrypted storage ─────────────────────────────────────────────────────────

class AppEncryptedStorage {
  AppEncryptedStorage._({String prefix = _kPrefixDefault})
      : _prefix = prefix;

  static final AppEncryptedStorage instance = AppEncryptedStorage._();

  final String _prefix;
  final _secureStorage = const FlutterSecureStorage();

  enc.Encrypter? _encrypter;
  SharedPreferences? _prefs;
  bool _initialised = false;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialised) return;

    _prefs = await SharedPreferences.getInstance();
    _encrypter = await _loadOrCreateEncrypter();
    _initialised = true;
    debugPrint('[AppEncryptedStorage] Initialised ✓');
  }

  Future<enc.Encrypter> _loadOrCreateEncrypter() async {
    String? keyBase64 = await _secureStorage.read(key: _kKeyStorageKey);

    if (keyBase64 == null) {
      // Generate a new 256-bit AES key
      final keyBytes = _generateRandomBytes(32);
      keyBase64 = base64Encode(keyBytes);
      await _secureStorage.write(key: _kKeyStorageKey, value: keyBase64);
      debugPrint('[AppEncryptedStorage] New key generated ✓');
    }

    final keyBytes = base64Decode(keyBase64);
    final key = enc.Key(Uint8List.fromList(keyBytes));
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
  }

  // ── String ──────────────────────────────────────────────────────────────────

  Future<void> setString(String key, String value) =>
      _set(key, value);

  Future<String?> getString(String key) =>
      _get(key);

  // ── Int ─────────────────────────────────────────────────────────────────────

  Future<void> setInt(String key, int value) =>
      _set(key, value.toString());

  Future<int?> getInt(String key) async {
    final v = await _get(key);
    return v != null ? int.tryParse(v) : null;
  }

  // ── Double ──────────────────────────────────────────────────────────────────

  Future<void> setDouble(String key, double value) =>
      _set(key, value.toString());

  Future<double?> getDouble(String key) async {
    final v = await _get(key);
    return v != null ? double.tryParse(v) : null;
  }

  // ── Bool ────────────────────────────────────────────────────────────────────

  Future<void> setBool(String key, bool value) =>
      _set(key, value ? '1' : '0');

  Future<bool?> getBool(String key) async {
    final v = await _get(key);
    if (v == null) return null;
    return v == '1';
  }

  // ── JSON ────────────────────────────────────────────────────────────────────

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _set(key, jsonEncode(value));

  Future<Map<String, dynamic>?> getJson(String key) async {
    final v = await _get(key);
    if (v == null) return null;
    try {
      return jsonDecode(v) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── List ────────────────────────────────────────────────────────────────────

  Future<void> setStringList(String key, List<String> values) =>
      _set(key, jsonEncode(values));

  Future<List<String>?> getStringList(String key) async {
    final v = await _get(key);
    if (v == null) return null;
    try {
      return (jsonDecode(v) as List<dynamic>).cast<String>();
    } catch (_) {
      return null;
    }
  }

  // ── Remove / Clear ──────────────────────────────────────────────────────────

  Future<void> remove(String key) async {
    _ensureInit();
    await _prefs!.remove('$_prefix$key');
  }

  Future<void> clear() async {
    _ensureInit();
    final keys = _prefs!.getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList();
    for (final k in keys) {
      await _prefs!.remove(k);
    }
  }

  Future<bool> containsKey(String key) async {
    _ensureInit();
    return _prefs!.containsKey('$_prefix$key');
  }

  Set<String> get keys => _prefs!
      .getKeys()
      .where((k) => k.startsWith(_prefix))
      .map((k) => k.substring(_prefix.length))
      .toSet();

  // ── Key rotation ─────────────────────────────────────────────────────────────
  // Re-encrypt all values with a new master key.
  // Call periodically (e.g. on app update) or after a security event.

  Future<void> rotateKey() async {
    _ensureInit();
    // 1. Read all current values
    final allKeys = keys.toList();
    final decrypted = <String, String>{};
    for (final k in allKeys) {
      final v = await getString(k);
      if (v != null) decrypted[k] = v;
    }
    // 2. Generate new key
    await _secureStorage.delete(key: _kKeyStorageKey);
    _encrypter = await _loadOrCreateEncrypter();
    // 3. Re-encrypt all values
    for (final entry in decrypted.entries) {
      await setString(entry.key, entry.value);
    }
    debugPrint('[AppEncryptedStorage] Key rotated ✓ (${allKeys.length} values re-encrypted)');
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  Future<void> _set(String key, String plaintext) async {
    _ensureInit();
    final iv = enc.IV.fromSecureRandom(12); // 96-bit IV for GCM
    final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
    // Store: base64(iv) + '.' + base64(ciphertext)
    final stored = '${base64Encode(iv.bytes)}.${encrypted.base64}';
    await _prefs!.setString('$_prefix$key', stored);
  }

  Future<String?> _get(String key) async {
    _ensureInit();
    final stored = _prefs!.getString('$_prefix$key');
    if (stored == null) return null;

    try {
      final parts = stored.split('.');
      if (parts.length != 2) return null;
      final iv = enc.IV(Uint8List.fromList(base64Decode(parts[0])));
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('[AppEncryptedStorage] Decrypt error for "$key": $e');
      return null;
    }
  }

  void _ensureInit() {
    assert(_initialised, 'Call AppEncryptedStorage.initialize() before use.');
  }

  Uint8List _generateRandomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }
}
