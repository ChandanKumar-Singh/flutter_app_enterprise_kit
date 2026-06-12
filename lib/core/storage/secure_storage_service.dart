import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class StorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userId = 'user_id';
  static const biometricEnabled = 'biometric_enabled';
  static const themeMode = 'theme_mode';
  static const locale = 'locale';
  static const onboardingDone = 'onboarding_done';
}

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> deleteAll() => _storage.deleteAll();
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
  Future<Map<String, String>> readAll() => _storage.readAll();
}
