import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/dictionary_model.dart';
import '../data/llm_client.dart';
import '../../settings/presentation/settings_notifier.dart';
import '../../../core/storage/secure_storage.dart';
import '../../favorites/presentation/favorites_notifier.dart';

class DictionaryState {
  final DictionaryEntry? entry;
  final bool isLoading;
  final String? errorMessage;
  final bool isFavorited;

  DictionaryState({
    this.entry,
    this.isLoading = false,
    this.errorMessage,
    this.isFavorited = false,
  });

  DictionaryState copyWith({
    DictionaryEntry? Function()? entry,
    bool? isLoading,
    String? Function()? errorMessage,
    bool? isFavorited,
  }) {
    return DictionaryState(
      entry: entry != null ? entry() : this.entry,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}

class DictionaryNotifier extends StateNotifier<DictionaryState> {
  final Ref _ref;
  final LLMClient _client;
  final SecureStorage _secureStorage;

  DictionaryNotifier(this._ref, this._client, this._secureStorage)
      : super(DictionaryState()) {
    // Listen to favorites updates to keep the toggle sync'd
    _ref.listen(favoritesNotifierProvider, (previous, next) {
      _updateFavoriteStatus(next);
    });
  }

  void _updateFavoriteStatus(List<dynamic> favoritesList) {
    if (state.entry == null) return;
    
    final normalized = state.entry!.normalizedWord;
    final isFav = favoritesList.any((fav) {
      // Duck typing since favoritesNotifier may load later
      try {
        return fav.normalizedWord == normalized;
      } catch (_) {
        return false;
      }
    });

    state = state.copyWith(isFavorited: isFav);
  }

  /// Triggers a lookup for a word or phrase
  Future<void> lookupWord(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      entry: () => null,
    );

    try {
      final settingsState = _ref.read(settingsNotifierProvider);
      final provider = settingsState.settings.provider;

      // 1. Resolve API Key: Try Secure Storage first, then fallback to environment variables
      String? apiKey = await _secureStorage.readApiKey(provider);

      if (apiKey == null || apiKey.isEmpty) {
        // Fallback to environment variables
        if (provider == 'gemini') {
          apiKey = const String.fromEnvironment('GEMINI_API_KEY');
          if (apiKey.isEmpty && !kIsWeb) {
            apiKey = Platform.environment['GEMINI_API_KEY'];
          }
        } else if (provider == 'openai') {
          apiKey = const String.fromEnvironment('OPENAI_API_KEY');
          if (apiKey.isEmpty && !kIsWeb) {
            apiKey = Platform.environment['OPENAI_API_KEY'];
          }
        }
      }

      if (apiKey == null || apiKey.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: () => '尚未設定 API Key！請先點擊右上角設定圖示輸入金鑰，或在環境中配置 API_KEY。',
        );
        return;
      }

      // 2. Perform API Query
      final entry = await _client.lookupDictionary(
        query: cleanQuery,
        apiKey: apiKey,
        settings: settingsState.settings,
      );

      // 3. Check favorited status
      final favoritesList = _ref.read(favoritesNotifierProvider);
      final isFav = favoritesList.any((fav) => fav.normalizedWord == entry.normalizedWord);

      state = state.copyWith(
        isLoading: false,
        entry: () => entry,
        isFavorited: isFav,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Toggles favorite status of the current entry
  Future<void> toggleFavorite() async {
    final entry = state.entry;
    if (entry == null) return;

    final notifier = _ref.read(favoritesNotifierProvider.notifier);
    if (state.isFavorited) {
      await notifier.removeFavorite(entry.normalizedWord);
      state = state.copyWith(isFavorited: false);
    } else {
      await notifier.addFavorite(entry);
      state = state.copyWith(isFavorited: true);
    }
  }

  /// Explicitly sets a cached entry when tapped from favorites screen
  void showCachedEntry(DictionaryEntry entry) {
    final favoritesList = _ref.read(favoritesNotifierProvider);
    final isFav = favoritesList.any((fav) => fav.normalizedWord == entry.normalizedWord);

    state = DictionaryState(
      entry: entry,
      isLoading: false,
      errorMessage: null,
      isFavorited: isFav,
    );
  }
}

final dictionaryNotifierProvider =
    StateNotifierProvider<DictionaryNotifier, DictionaryState>((ref) {
  final client = ref.watch(llmClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return DictionaryNotifier(ref, client, secureStorage);
});
