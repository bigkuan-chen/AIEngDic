import 'package:shared_preferences/shared_preferences.dart';
import '../domain/settings_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const String _keySettingsProvider = 'settings_provider';
  static const String _keySettingsModel = 'settings_model';
  static const String _keySettingsCustomModel = 'settings_custom_model';
  static const String _keySettingsTheme = 'settings_theme';
  static const String _keySettingsLanguage = 'settings_language';
  static const String _keySettingsLearnerLevel = 'settings_learner_level';
  static const String _keySettingsVariant = 'settings_variant';

  AppSettings loadSettings() {
    try {
      final provider = _prefs.getString(_keySettingsProvider);
      final model = _prefs.getString(_keySettingsModel);
      final customModel = _prefs.getString(_keySettingsCustomModel);
      final theme = _prefs.getString(_keySettingsTheme);
      final language = _prefs.getString(_keySettingsLanguage);
      final learnerLevel = _prefs.getString(_keySettingsLearnerLevel);
      final variant = _prefs.getString(_keySettingsVariant);

      if (provider == null) {
        return AppSettings.defaultSettings();
      }

      return AppSettings(
        provider: provider,
        model: model ?? 'gemini-2.5-flash',
        customModel: customModel,
        theme: theme ?? 'light',
        outputLanguage: language ?? 'zh-TW',
        learnerLevel: learnerLevel ?? 'intermediate',
        englishVariant: variant ?? 'both',
      );
    } catch (e) {
      return AppSettings.defaultSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_keySettingsProvider, settings.provider);
    await _prefs.setString(_keySettingsModel, settings.model);
    if (settings.customModel != null) {
      await _prefs.setString(_keySettingsCustomModel, settings.customModel!);
    } else {
      await _prefs.remove(_keySettingsCustomModel);
    }
    await _prefs.setString(_keySettingsTheme, settings.theme);
    await _prefs.setString(_keySettingsLanguage, settings.outputLanguage);
    await _prefs.setString(_keySettingsLearnerLevel, settings.learnerLevel);
    await _prefs.setString(_keySettingsVariant, settings.englishVariant);
  }

  static const String _keySmartReview = 'smart_review_words';

  List<String> loadSmartReviewWords() {
    return _prefs.getStringList(_keySmartReview) ?? [];
  }

  Future<void> saveSmartReviewWords(List<String> words) async {
    await _prefs.setStringList(_keySmartReview, words);
  }
}

// SharedPreferences needs asynchronous initialization, which we will handle in main.dart
// and inject into the provider.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('settingsRepositoryProvider must be overridden in ProviderScope');
});
