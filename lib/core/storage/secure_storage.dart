import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _geminiKey = 'llm_api_key_gemini';
  static const String _openaiKey = 'llm_api_key_openai';

  String _getKeyForProvider(String provider) {
    final cleanProvider = provider.trim().toLowerCase();
    if (cleanProvider == 'gemini') {
      return _geminiKey;
    } else if (cleanProvider == 'openai') {
      return _openaiKey;
    } else {
      throw ArgumentError('Unsupported LLM provider: $provider');
    }
  }

  /// Reads API key for the given provider.
  Future<String?> readApiKey(String provider) async {
    try {
      final key = _getKeyForProvider(provider);
      return await _storage.read(key: key);
    } catch (e) {
      // Secure storage can occasionally fail on certain Android setups
      return null;
    }
  }

  /// Writes API key for the given provider.
  Future<void> writeApiKey(String provider, String apiKey) async {
    final key = _getKeyForProvider(provider);
    await _storage.write(key: key, value: apiKey.trim());
  }

  /// Deletes API key for the given provider.
  Future<void> deleteApiKey(String provider) async {
    final key = _getKeyForProvider(provider);
    await _storage.delete(key: key);
  }

  /// Checks if an API key exists for a provider.
  Future<bool> hasApiKey(String provider) async {
    final key = await readApiKey(provider);
    return key != null && key.isNotEmpty;
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});
