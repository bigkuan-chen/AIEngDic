class AppSettings {
  final String provider; // 'gemini' or 'openai'
  final String model; // 'gemini-2.5-flash', 'gpt-4o-mini', etc.
  final String? customModel;
  final String theme; // 'system', 'light', 'dark'
  final String outputLanguage; // 'zh-TW', 'English'
  final String learnerLevel; // 'beginner', 'intermediate', 'advanced'
  final String englishVariant; // 'US', 'UK', 'both'

  const AppSettings({
    required this.provider,
    required this.model,
    this.customModel,
    required this.theme,
    required this.outputLanguage,
    required this.learnerLevel,
    required this.englishVariant,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      provider: 'gemini',
      model: 'gemini-2.5-flash',
      customModel: null,
      theme: 'light',
      outputLanguage: 'zh-TW',
      learnerLevel: 'intermediate',
      englishVariant: 'both',
    );
  }

  String get activeModel {
    if (model == 'custom' && customModel != null && customModel!.isNotEmpty) {
      return customModel!;
    }
    return model;
  }

  AppSettings copyWith({
    String? provider,
    String? model,
    String? Function()? customModel,
    String? theme,
    String? outputLanguage,
    String? learnerLevel,
    String? englishVariant,
  }) {
    return AppSettings(
      provider: provider ?? this.provider,
      model: model ?? this.model,
      customModel: customModel != null ? customModel() : this.customModel,
      theme: theme ?? this.theme,
      outputLanguage: outputLanguage ?? this.outputLanguage,
      learnerLevel: learnerLevel ?? this.learnerLevel,
      englishVariant: englishVariant ?? this.englishVariant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'model': model,
      'customModel': customModel,
      'theme': theme,
      'outputLanguage': outputLanguage,
      'learnerLevel': learnerLevel,
      'englishVariant': englishVariant,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      provider: json['provider'] as String? ?? 'gemini',
      model: json['model'] as String? ?? 'gemini-2.5-flash',
      customModel: json['customModel'] as String?,
      theme: json['theme'] as String? ?? 'system',
      outputLanguage: json['outputLanguage'] as String? ?? 'zh-TW',
      learnerLevel: json['learnerLevel'] as String? ?? 'intermediate',
      englishVariant: json['englishVariant'] as String? ?? 'both',
    );
  }
}
