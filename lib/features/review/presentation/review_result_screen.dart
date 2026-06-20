import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../favorites/presentation/favorites_notifier.dart';
import '../domain/review_model.dart';
import 'review_notifier.dart';

class ReviewResultScreen extends ConsumerWidget {
  const ReviewResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewNotifierProvider);
    final answers = state.sessionAnswers;
    final favorites = ref.watch(favoritesNotifierProvider);

    // Calculate statistics
    final totalCount = answers.length;
    final correctCount = answers.where((a) => a.isCorrect).length;
    final wrongCount = totalCount - correctCount;
    final accuracy = totalCount > 0 ? correctCount / totalCount : 0.0;
    
    // Average response time
    double avgTimeSec = 0.0;
    if (totalCount > 0) {
      final totalMs = answers.fold<int>(0, (sum, a) => sum + a.responseTimeMs);
      avgTimeSec = (totalMs / totalCount) / 1000.0;
    }

    // Categorize words
    final Map<String, bool> wrongWordMap = {};
    final Map<String, String> wordRatings = {};
    for (var a in answers) {
      // Find the corresponding ReviewQuestion in the session to get normalizedWord
      final question = state.activeSession?.questions.firstWhere(
        (q) => q.id == a.questionId,
        orElse: () => state.activeSession!.questions.first,
      );
      if (question != null) {
        if (!a.isCorrect || a.selfRating == 'forgot' || a.selfRating == 'hard') {
          wrongWordMap[question.normalizedWord] = true;
        }
        wordRatings[question.normalizedWord] = a.selfRating;
      }
    }

    // Filter actual FavoriteWords to show in lists
    final difficultWords = favorites.where((f) => wrongWordMap.containsKey(f.normalizedWord)).toList();
    final masteredWords = favorites.where((f) {
      final hasAnswered = answers.any((a) {
        final q = state.activeSession?.questions.firstWhere((q) => q.id == a.questionId, orElse: () => state.activeSession!.questions.first);
        return q?.normalizedWord == f.normalizedWord;
      });
      return hasAnswered && !wrongWordMap.containsKey(f.normalizedWord);
    }).toList();

    // Theme values
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('複習結果摘要'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Large circular accuracy chart
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: accuracy,
                      strokeWidth: 10,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        accuracy >= 0.8 ? Colors.green : (accuracy >= 0.6 ? Colors.orange : Colors.red),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(accuracy * 100).round()}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '正確率',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  title: '答對題數',
                  value: '$correctCount 題',
                  color: Colors.green,
                  icon: Icons.check_circle_outline,
                  colorScheme: colorScheme,
                ),
                _buildStatCard(
                  title: '答錯題數',
                  value: '$wrongCount 題',
                  color: wrongCount > 0 ? Colors.red : colorScheme.onSurfaceVariant,
                  icon: Icons.cancel_outlined,
                  colorScheme: colorScheme,
                ),
                _buildStatCard(
                  title: '總複習題數',
                  value: '$totalCount 題',
                  color: colorScheme.primary,
                  icon: Icons.assignment_outlined,
                  colorScheme: colorScheme,
                ),
                _buildStatCard(
                  title: '平均答題時間',
                  value: '${avgTimeSec.toStringAsFixed(1)} 秒',
                  color: Colors.blue,
                  icon: Icons.timer_outlined,
                  colorScheme: colorScheme,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Weakness section (Difficult Words)
            if (difficultWords.isNotEmpty) ...[
              _buildSectionHeader('需要加強 (${difficultWords.length})', Colors.red, colorScheme),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: difficultWords.length,
                itemBuilder: (context, index) {
                  final f = difficultWords[index];
                  final reviewItem = state.reviewItems.firstWhere(
                    (item) => item.normalizedWord == f.normalizedWord,
                    orElse: () => ReviewItem(id: '', favoriteWordId: '', normalizedWord: ''),
                  );
                  return _buildWordRow(
                    word: f.word,
                    translation: f.primaryTranslationZhTw ?? '',
                    rating: wordRatings[f.normalizedWord],
                    status: reviewItem.learningStatus,
                    colorScheme: colorScheme,
                    isDifficult: true,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Mastered section (Mastered Words)
            if (masteredWords.isNotEmpty) ...[
              _buildSectionHeader('表現良好 (${masteredWords.length})', Colors.green, colorScheme),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: masteredWords.length,
                itemBuilder: (context, index) {
                  final f = masteredWords[index];
                  final reviewItem = state.reviewItems.firstWhere(
                    (item) => item.normalizedWord == f.normalizedWord,
                    orElse: () => ReviewItem(id: '', favoriteWordId: '', normalizedWord: ''),
                  );
                  return _buildWordRow(
                    word: f.word,
                    translation: f.primaryTranslationZhTw ?? '',
                    rating: wordRatings[f.normalizedWord],
                    status: reviewItem.learningStatus,
                    colorScheme: colorScheme,
                    isDifficult: false,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            if (difficultWords.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Start a new review session only containing incorrect words
                    final wrongFavorites = favorites
                        .where((f) => wrongWordMap.containsKey(f.normalizedWord))
                        .toList();

                    await ref.read(reviewNotifierProvider.notifier).createSession(
                          favorites: wrongFavorites,
                          plannedCount: wrongFavorites.length,
                          enabledTypes: const ['en_to_zh', 'zh_to_en', 'context_choice'],
                          mode: 'difficult',
                        );

                    if (context.mounted) {
                      context.pushReplacement('/review/session');
                    }
                  },
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  label: const Text('再複習錯題', style: TextStyle(color: Colors.red, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(reviewNotifierProvider.notifier).clearActiveSession();
                      context.pushReplacement('/favorites');
                    },
                    child: const Text('回到我的單字'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(reviewNotifierProvider.notifier).clearActiveSession();
                      context.pushReplacement('/dictionary');
                    },
                    child: const Text('完成'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      color: colorScheme.surfaceVariant.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildWordRow({
    required String word,
    required String translation,
    required String? rating,
    required String status,
    required ColorScheme colorScheme,
    required bool isDifficult,
  }) {
    String ratingLabel = '記得';
    Color ratingColor = Colors.blue;
    switch (rating) {
      case 'forgot':
        ratingLabel = '忘記了';
        ratingColor = Colors.red;
        break;
      case 'hard':
        ratingLabel = '有點難';
        ratingColor = Colors.orange;
        break;
      case 'good':
        ratingLabel = '記得';
        ratingColor = Colors.blue;
        break;
      case 'easy':
        ratingLabel = '很簡單';
        ratingColor = Colors.green;
        break;
    }

    String statusLabel = '新單字';
    Color statusColor = colorScheme.outline;
    switch (status) {
      case 'new':
        statusLabel = '新單字';
        statusColor = Colors.purple;
        break;
      case 'learning':
        statusLabel = '學習中';
        statusColor = Colors.amber;
        break;
      case 'familiar':
        statusLabel = '已熟悉';
        statusColor = Colors.blue;
        break;
      case 'mastered':
        statusLabel = '已掌握';
        statusColor = Colors.green;
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        title: Row(
          children: [
            Text(
              word,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            // Learning status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          translation,
          style: const TextStyle(fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: ratingColor.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(6),
            color: ratingColor.withOpacity(0.05),
          ),
          child: Text(
            ratingLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: ratingColor,
            ),
          ),
        ),
      ),
    );
  }
}
