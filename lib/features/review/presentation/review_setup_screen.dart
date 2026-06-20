import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../favorites/presentation/favorites_notifier.dart';
import 'review_notifier.dart';

class ReviewSetupScreen extends ConsumerStatefulWidget {
  const ReviewSetupScreen({super.key});

  @override
  ConsumerState<ReviewSetupScreen> createState() => _ReviewSetupScreenState();
}

class _ReviewSetupScreenState extends ConsumerState<ReviewSetupScreen> {
  int _selectedCount = 10;
  String _selectedMode = 'smart';
  
  final Map<String, bool> _enabledTypes = {
    'en_to_zh': true,
    'zh_to_en': true,
    'context_choice': true,
    'similar_word_choice': true,
  };

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesNotifierProvider);
    final reviewState = ref.watch(reviewNotifierProvider);
    final count = favoritesState.length;

    // Check if at least one question type is enabled
    final canStart = count > 0 && _enabledTypes.values.any((val) => val);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智慧複習設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word count card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '我的單字庫庫存',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '我的單字：$count 個',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (count == 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '尚未加入任何單字，請先將單字加入我的單字以開始複習。',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            _buildSectionTitle('本次複習題數'),
            const SizedBox(height: 12),
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 5, label: Text('5 題')),
                  ButtonSegment<int>(value: 10, label: Text('10 題')),
                  ButtonSegment<int>(value: 15, label: Text('15 題')),
                  ButtonSegment<int>(value: 20, label: Text('20 題')),
                ],
                selected: {_selectedCount},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedCount = newSelection.first;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('複習模式'),
            const SizedBox(height: 12),
            _buildModeOption(
              mode: 'smart',
              title: '智慧選題',
              description: '優先抽選較久未複習、答錯較多及不熟悉單字',
              icon: Icons.psychology_outlined,
            ),
            const SizedBox(height: 8),
            _buildModeOption(
              mode: 'random',
              title: '隨機複習',
              description: '從我的單字隨機選取，但仍避免近期重複',
              icon: Icons.shuffle_outlined,
            ),
            const SizedBox(height: 8),
            _buildModeOption(
              mode: 'difficult',
              title: '加強弱項',
              description: '優先選擇錯誤率較高的單字',
              icon: Icons.trending_down_outlined,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('題型設定'),
            const SizedBox(height: 8),
            _buildTypeCheckbox(
              key: 'en_to_zh',
              title: '英文選中文',
              subtitle: '簡單 - 請選出最適合的中文意思',
            ),
            _buildTypeCheckbox(
              key: 'zh_to_en',
              title: '中文選英文',
              subtitle: '中等 - 請選出最適合的英文單字',
            ),
            _buildTypeCheckbox(
              key: 'context_choice',
              title: '情境選字',
              subtitle: '中等 - 哪個單字最適合填入句子？',
            ),
            _buildTypeCheckbox(
              key: 'similar_word_choice',
              title: '相似字辨識',
              subtitle: '困難 - 根據情境選出語意最自然的單字',
            ),
            
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: canStart && !reviewState.isLoading
                    ? () async {
                        // Gather active types
                        final activeTypes = _enabledTypes.entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key)
                            .toList();

                        await ref.read(reviewNotifierProvider.notifier).createSession(
                              favorites: favoritesState,
                              plannedCount: _selectedCount,
                              enabledTypes: activeTypes,
                              mode: _selectedMode,
                            );

                        if (!mounted) return;
                        final currentReviewState = ref.read(reviewNotifierProvider);
                        if (currentReviewState.activeSession != null) {
                          if (context.mounted) {
                            context.pushReplacement('/review/session');
                          }
                        } else if (currentReviewState.error != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(currentReviewState.error!)),
                            );
                          }
                        }
                      }
                    : null,
                icon: reviewState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_fill_outlined),
                label: const Text('開始複習', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildModeOption({
    required String mode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.15) : Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: mode,
                groupValue: _selectedMode,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMode = val;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCheckbox({
    required String key,
    required String title,
    required String subtitle,
  }) {
    return CheckboxListTile(
      value: _enabledTypes[key],
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _enabledTypes[key] = val;
          });
        }
      },
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: EdgeInsets.zero,
    );
  }
}
