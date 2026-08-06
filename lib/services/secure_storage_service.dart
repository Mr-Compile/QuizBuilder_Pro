import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for sensitive app data such as API keys.
///
/// Uses the platform's secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences
/// - Windows/macOS/Linux: OS-specific secure credential stores
class SecureStorageService {
  static const _apiKeyKey = 'groq_api_key';
  static const _apiKeyIdKey = 'groq_api_key_id';

  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  /// Stores the Groq API key securely.
  Future<void> saveApiKey(String? apiKey, {String? keyId}) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      await deleteApiKey();
      if (keyId != null) await _storage.delete(key: _apiKeyIdKey);
      return;
    }

    final trimmed = apiKey.trim();
    await _storage.write(key: _apiKeyKey, value: trimmed, aOptions: _androidOptions);
    if (keyId != null) {
      await _storage.write(key: _apiKeyIdKey, value: keyId, aOptions: _androidOptions);
    }
  }

  /// Returns the stored Groq API key, or null if not set.
  Future<String?> getApiKey() async {
    return _storage.read(key: _apiKeyKey, aOptions: _androidOptions);
  }

  /// Returns a masked representation of the last part of the API key for UI display.
  Future<String?> getMaskedApiKey() async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) return null;
    if (key.length <= 8) return '•'.padRight(key.length, '•');
    return '${key.substring(0, 4)}${'•'.padRight(key.length - 8, '•')}${key.substring(key.length - 4)}';
  }

  /// Removes the stored API key.
  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey, aOptions: _androidOptions);
    await _storage.delete(key: _apiKeyIdKey, aOptions: _androidOptions);
  }

  /// Returns true if an API key is stored.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  AndroidOptions get _androidOptions => const AndroidOptions();
}