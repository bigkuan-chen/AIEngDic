import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/settings_model.dart';
import '../data/settings_repository.dart';
import '../../../core/storage/secure_storage.dart';
import '../../dictionary/data/llm_client.dart';

class SettingsState {
  final AppSettings settings;
  final bool isLoading;
  final bool isTestingConnection;
  final String? testConnectionResult;
  final bool testConnectionSuccess;
  final bool hasGeminiKey;
  final bool hasOpenAIKey;

  SettingsState({
    required this.settings,
    this.isLoading = false,
    this.isTestingConnection = false,
    this.testConnectionResult,
    this.testConnectionSuccess = false,
    this.hasGeminiKey = false,
    this.hasOpenAIKey = false,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    bool? isTestingConnection,
    String? Function()? testConnectionResult,
    bool? testConnectionSuccess,
    bool? hasGeminiKey,
    bool? hasOpenAIKey,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isTestingConnection: isTestingConnection ?? this.isTestingConnection,
      testConnectionResult: testConnectionResult != null ? testConnectionResult() : this.testConnectionResult,
      testConnectionSuccess: testConnectionSuccess ?? this.testConnectionSuccess,
      hasGeminiKey: hasGeminiKey ?? this.hasGeminiKey,
      hasOpenAIKey: hasOpenAIKey ?? this.hasOpenAIKey,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  final SecureStorage _secureStorage;
  final Ref _ref;

  SettingsNotifier(this._repository, this._secureStorage, this._ref)
      : super(SettingsState(settings: AppSettings.defaultSettings())) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final settings = _repository.loadSettings();
    final hasGemini = await _secureStorage.hasApiKey('gemini');
    final hasOpenAI = await _secureStorage.hasApiKey('openai');
    state = SettingsState(
      settings: settings,
      isLoading: false,
      hasGeminiKey: hasGemini,
      hasOpenAIKey: hasOpenAI,
    );
  }

  Future<void> updateProvider(String provider) async {
    String defaultModel = 'gemini-2.5-flash';
    if (provider == 'openai') {
      defaultModel = 'gpt-4o-mini';
    }
    final newSettings = state.settings.copyWith(
      provider: provider,
      model: defaultModel,
      customModel: () => null,
    );
    await _repository.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> updateModel(String model) async {
    final newSettings = state.settings.copyWith(model: model);
    await _repository.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> updateCustomModel(String customModel) async {
    final newSettings = state.settings.copyWith(customModel: () => customModel);
    await _repository.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> updateTheme(String theme) async {
    final newSettings = state.settings.copyWith(theme: theme);
    await _repository.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> updateOutputLanguage(String lang) async {
    final newSettings = state.settings.copyWith(outputLanguage: lang);
    await _repository.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> updateLearnerLevel(String level) async {
    final newSettings = state.settings.copyWith(learnerLevel: level);
    await _repository.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> updateEnglishVariant(String variant) async {
    final newSettings = state.settings.copyWith(englishVariant: variant);
    await _repository.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  Future<void> saveApiKey(String provider, String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) return;
    
    await _secureStorage.writeApiKey(provider, cleanKey);
    final hasGemini = await _secureStorage.hasApiKey('gemini');
    final hasOpenAI = await _secureStorage.hasApiKey('openai');
    state = state.copyWith(
      hasGeminiKey: hasGemini,
      hasOpenAIKey: hasOpenAI,
    );
  }

  Future<void> deleteApiKey(String provider) async {
    await _secureStorage.deleteApiKey(provider);
    final hasGemini = await _secureStorage.hasApiKey('gemini');
    final hasOpenAI = await _secureStorage.hasApiKey('openai');
    state = state.copyWith(
      hasGeminiKey: hasGemini,
      hasOpenAIKey: hasOpenAI,
    );
  }

  Future<void> testConnection(String provider, String apiKey, String modelName) async {
    if (apiKey.trim().isEmpty) {
      state = state.copyWith(
        testConnectionSuccess: false,
        testConnectionResult: () => '請輸入 API Key 後再測試連線。',
      );
      return;
    }

    state = state.copyWith(isTestingConnection: true, testConnectionResult: () => null);

    try {
      final client = _ref.read(llmClientProvider);
      final isValid = await client.validateApiKey(provider, apiKey.trim(), modelName);

      if (isValid) {
        state = state.copyWith(
          isTestingConnection: false,
          testConnectionSuccess: true,
          testConnectionResult: () => '連線測試成功！API Key 有效。',
        );
      } else {
        state = state.copyWith(
          isTestingConnection: false,
          testConnectionSuccess: false,
          testConnectionResult: () => '連線測試失敗。請確認 API Key 是否正確。',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isTestingConnection: false,
        testConnectionSuccess: false,
        testConnectionResult: () => '連線錯誤: ${e.toString()}',
      );
    }
  }

  void clearTestResult() {
    state = state.copyWith(testConnectionResult: () => null);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return SettingsNotifier(repo, secureStorage, ref);
});
