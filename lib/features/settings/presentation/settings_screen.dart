import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_notifier.dart';
import '../../../core/storage/secure_storage.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _customModelController = TextEditingController();
  
  bool _obscureApiKey = true;
  bool _isEditingKey = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsNotifierProvider);
    final settings = state.settings;
    final hasKey = settings.provider == 'gemini' ? state.hasGeminiKey : state.hasOpenAIKey;

    // Load custom model name if it exists in the controller initially
    if (_customModelController.text.isEmpty && settings.customModel != null) {
      _customModelController.text = settings.customModel!;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('模型設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('LLM 供應商設定'),
                    const SizedBox(height: 12),
                    
                    // Provider Dropdown
                    DropdownButtonFormField<String>(
                      value: settings.provider,
                      decoration: const InputDecoration(
                        labelText: 'LLM 供應商',
                        prefixIcon: Icon(Icons.hub_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'gemini', child: Text('Google Gemini')),
                        DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsNotifierProvider.notifier).updateProvider(val);
                          setState(() {
                            _isEditingKey = false;
                            _apiKeyController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Model Dropdown
                    DropdownButtonFormField<String>(
                      value: settings.model,
                      decoration: const InputDecoration(
                        labelText: '模型',
                        prefixIcon: Icon(Icons.smart_toy_outlined),
                      ),
                      items: settings.provider == 'gemini'
                          ? const [
                              DropdownMenuItem(value: 'gemini-2.5-flash', child: Text('Gemini 2.5 Flash (推薦)')),
                              DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('Gemini 1.5 Pro')),
                              DropdownMenuItem(value: 'custom', child: Text('自訂模型名稱')),
                            ]
                          : const [
                              DropdownMenuItem(value: 'gpt-4o-mini', child: Text('GPT-4o Mini (推薦)')),
                              DropdownMenuItem(value: 'gpt-4o', child: Text('GPT-4o')),
                              DropdownMenuItem(value: 'custom', child: Text('自訂模型名稱')),
                            ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsNotifierProvider.notifier).updateModel(val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Custom Model Name Input
                    if (settings.model == 'custom') ...[
                      TextFormField(
                        controller: _customModelController,
                        decoration: const InputDecoration(
                          labelText: '自訂模型名稱',
                          hintText: '例如: gemini-2.0-flash-exp',
                          prefixIcon: Icon(Icons.settings_suggest_outlined),
                        ),
                        validator: (value) {
                          if (settings.model == 'custom' && (value == null || value.trim().isEmpty)) {
                            return '請輸入自訂模型名稱';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          ref.read(settingsNotifierProvider.notifier).updateCustomModel(val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // API Key Section
                    if (hasKey && !_isEditingKey) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.vpn_key, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'API Key 已儲存',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    settings.provider == 'gemini' 
                                        ? 'AIza••••••••••••••••' 
                                        : 'sk-••••••••••••••••',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditingKey = true;
                                  _apiKeyController.clear();
                                });
                              },
                              child: const Text('修改'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _showDeleteKeyConfirmation(context, settings.provider),
                              tooltip: '刪除 API Key',
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _apiKeyController,
                        obscureText: _obscureApiKey,
                        enableSuggestions: false,
                        autocorrect: false,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          hintText: settings.provider == 'gemini' 
                              ? '輸入 Gemini API Key' 
                              : '輸入 OpenAI API Key',
                          prefixIcon: const Icon(Icons.key),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                          ),
                        ),
                        validator: (value) {
                          if (!hasKey && (value == null || value.trim().isEmpty)) {
                            return '請輸入 API Key';
                          }
                          return null;
                        },
                      ),
                      if (_isEditingKey) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditingKey = false;
                                  _apiKeyController.clear();
                                });
                              },
                              child: const Text('取消修改'),
                            ),
                          ],
                        ),
                      ]
                    ],
                    const SizedBox(height: 20),

                    // Test Connection and Action buttons
                    if (!hasKey || _isEditingKey) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: state.isTestingConnection
                                  ? null
                                  : () {
                                      ref.read(settingsNotifierProvider.notifier).testConnection(
                                            settings.provider,
                                            _apiKeyController.text,
                                            settings.activeModel,
                                          );
                                    },
                              icon: state.isTestingConnection
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.speed),
                              label: const Text('測試連線'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  if (_apiKeyController.text.isNotEmpty) {
                                    await ref.read(settingsNotifierProvider.notifier).saveApiKey(
                                          settings.provider,
                                          _apiKeyController.text,
                                        );
                                  }
                                  setState(() {
                                    _isEditingKey = false;
                                  });
                                  ref.read(settingsNotifierProvider.notifier).clearTestResult();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('設定已成功儲存')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.save),
                              label: const Text('儲存設定'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Connection test output
                    if (state.testConnectionResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: state.testConnectionSuccess
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: state.testConnectionSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          state.testConnectionResult!,
                          style: TextStyle(
                            color: state.testConnectionSuccess ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    _buildSectionTitle('字典偏好與個人化'),
                    const SizedBox(height: 12),

                    // Language Dropdown
                    DropdownButtonFormField<String>(
                      value: settings.outputLanguage,
                      decoration: const InputDecoration(
                        labelText: '翻譯解釋語言',
                        prefixIcon: Icon(Icons.translate),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'zh-TW', child: Text('繁體中文 (Traditional Chinese)')),
                        DropdownMenuItem(value: 'English', child: Text('英文 (English)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsNotifierProvider.notifier).updateOutputLanguage(val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Learner level
                    DropdownButtonFormField<String>(
                      value: settings.learnerLevel,
                      decoration: const InputDecoration(
                        labelText: '英語學習程度',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'beginner', child: Text('初級 (Beginner)')),
                        DropdownMenuItem(value: 'intermediate', child: Text('中級 (Intermediate)')),
                        DropdownMenuItem(value: 'advanced', child: Text('高級 (Advanced)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsNotifierProvider.notifier).updateLearnerLevel(val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Accent / Accent Variant
                    DropdownButtonFormField<String>(
                      value: settings.englishVariant,
                      decoration: const InputDecoration(
                        labelText: '英語發音/拼寫偏好',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'US', child: Text('美式 (US)')),
                        DropdownMenuItem(value: 'UK', child: Text('英式 (UK)')),
                        DropdownMenuItem(value: 'both', child: Text('美式與英式雙向顯示')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsNotifierProvider.notifier).updateEnglishVariant(val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // App Theme Settings
                    DropdownButtonFormField<String>(
                      value: settings.theme,
                      decoration: const InputDecoration(
                        labelText: '佈景主題',
                        prefixIcon: Icon(Icons.palette_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('跟隨系統')),
                        DropdownMenuItem(value: 'light', child: Text('淺色模式')),
                        DropdownMenuItem(value: 'dark', child: Text('深色模式')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsNotifierProvider.notifier).updateTheme(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showDeleteKeyConfirmation(BuildContext context, String provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除 API Key'),
        content: Text('確定要刪除已儲存的 ${provider == 'gemini' ? 'Gemini' : 'OpenAI'} API Key 嗎？\n這將使您無法執行新的 LLM 字典查詢。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              ref.read(settingsNotifierProvider.notifier).deleteApiKey(provider);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API Key 已刪除')),
              );
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }
}
