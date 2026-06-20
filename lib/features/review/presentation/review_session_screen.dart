import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/tts/tts_service.dart';
import '../domain/review_model.dart';
import 'review_notifier.dart';

class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  ConsumerState<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  String? _selectedOption;
  bool _isAnswerConfirmed = false;
  String? _selectedRating; // 'forgot', 'hard', 'good', 'easy'
  late DateTime _questionStartTime;
  int _responseTimeMs = 0;

  @override
  void initState() {
    super.initState();
    _questionStartTime = DateTime.now();
  }

  void _resetQuestionState() {
    setState(() {
      _selectedOption = null;
      _isAnswerConfirmed = false;
      _selectedRating = null;
      _questionStartTime = DateTime.now();
      _responseTimeMs = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewNotifierProvider);
    final session = state.activeSession;

    if (session == null) {
      return const Scaffold(
        body: Center(
          child: Text('無作用中的複習 Session。'),
        ),
      );
    }

    final total = session.plannedQuestionCount;
    final currentIdx = session.currentQuestionIndex;
    final isLast = currentIdx >= total - 1;

    // Safety check for index out of bounds (should not happen normally)
    if (currentIdx >= total) {
      // Navigate to results screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/review/result');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = session.questions[currentIdx];
    final progress = currentIdx / total;

    // Get color theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Map question type label
    String typeLabel = '複習';
    IconData typeIcon = Icons.help_outline;
    switch (question.questionType) {
      case 'en_to_zh':
        typeLabel = '英翻中';
        typeIcon = Icons.translate;
        break;
      case 'zh_to_en':
        typeLabel = '中翻英';
        typeIcon = Icons.g_translate;
        break;
      case 'context_choice':
        typeLabel = '情境選字';
        typeIcon = Icons.text_snippet_outlined;
        break;
      case 'similar_word_choice':
        typeLabel = '相似字辨識';
        typeIcon = Icons.compare_arrows_outlined;
        break;
    }

    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmation(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(typeIcon, size: 20),
              const SizedBox(width: 8),
              Text('智慧複習 (${currentIdx + 1}/$total)'),
            ],
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '結束複習',
              onPressed: () async {
                final confirm = await _showExitConfirmation(context);
                if (confirm && mounted) {
                  await ref.read(reviewNotifierProvider.notifier).abandonSession();
                  if (context.mounted) {
                    context.pushReplacement('/dictionary');
                  }
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Linear Progress Indicator
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Type Chip
                    Chip(
                      avatar: Icon(typeIcon, size: 14, color: colorScheme.onSecondaryContainer),
                      label: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      backgroundColor: colorScheme.secondaryContainer,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 8),

                    // Prompt
                    Text(
                      question.prompt,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question Content Card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                      ),
                      color: colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                        child: Center(
                          child: Text(
                            question.questionContent,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: question.questionType == 'context_choice' || question.questionType == 'similar_word_choice' ? 18 : 26,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Answer Options Area
                    Column(
                      children: question.options.map((option) {
                        return _buildOptionCard(
                          option: option,
                          correctAnswer: question.correctAnswer,
                          colorScheme: colorScheme,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),

                    // Verify Action Button
                    if (!_isAnswerConfirmed)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _selectedOption != null
                              ? () {
                                  setState(() {
                                    _isAnswerConfirmed = true;
                                    _responseTimeMs = DateTime.now().difference(_questionStartTime).inMilliseconds;
                                  });
                                }
                              : null,
                          child: const Text('確認答案', style: TextStyle(fontSize: 16)),
                        ),
                      ),

                    // Feedback and self-rating area (Visible after checking answer)
                    if (_isAnswerConfirmed) ...[
                      const Divider(height: 32),
                      _buildFeedbackPanel(
                        question: question,
                        colorScheme: colorScheme,
                        isLast: isLast,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String option,
    required String correctAnswer,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedOption == option;
    final isCorrect = option == correctAnswer;

    Color borderColor = colorScheme.outline.withOpacity(0.2);
    Color cardColor = colorScheme.surface;
    Widget? trailingIcon;
    double borderWidth = 1.0;

    if (_isAnswerConfirmed) {
      if (isCorrect) {
        borderColor = Colors.green;
        cardColor = Colors.green.withOpacity(0.08);
        trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
        borderWidth = 2.0;
      } else if (isSelected) {
        borderColor = Colors.red;
        cardColor = Colors.red.withOpacity(0.08);
        trailingIcon = const Icon(Icons.cancel, color: Colors.red);
        borderWidth = 2.0;
      } else {
        cardColor = colorScheme.surface.withOpacity(0.6);
      }
    } else {
      if (isSelected) {
        borderColor = colorScheme.primary;
        cardColor = colorScheme.primaryContainer.withOpacity(0.15);
        borderWidth = 2.0;
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      color: cardColor,
      child: InkWell(
        onTap: _isAnswerConfirmed
            ? null
            : () {
                setState(() {
                  _selectedOption = option;
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected || (_isAnswerConfirmed && isCorrect)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _isAnswerConfirmed && !isCorrect && !isSelected
                        ? colorScheme.onSurface.withOpacity(0.4)
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailingIcon != null) trailingIcon,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackPanel({
    required ReviewQuestion question,
    required ColorScheme colorScheme,
    required bool isLast,
  }) {
    final bool isUserCorrect = _selectedOption == question.correctAnswer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accuracy indicator header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUserCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUserCorrect ? Colors.green : Colors.red,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isUserCorrect ? Icons.check_circle_outline : Icons.error_outline,
                color: isUserCorrect ? Colors.green.shade800 : Colors.red.shade800,
              ),
              const SizedBox(width: 12),
              Text(
                isUserCorrect ? '答對了！' : '答錯了！正確答案是：${question.correctAnswer}',
                style: TextStyle(
                  color: isUserCorrect ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Word explanation area
        Card(
          elevation: 0,
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '單字解說：${question.normalizedWord}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up, color: colorScheme.primary),
                      onPressed: () {
                        // Play TTS audio
                        ref.read(ttsServiceProvider).speakUS(question.normalizedWord);
                      },
                      tooltip: '發音 (US)',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.explanation,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                if (question.exampleEnglish != null) ...[
                  const SizedBox(height: 12),
                  const Text('例句：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    question.exampleEnglish!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (question.exampleZhTw != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      question.exampleZhTw!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        
        // Self-rating section
        Text(
          '你覺得這個單字如何？',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRatingButton(rating: 'forgot', label: '忘記了', activeColor: Colors.red),
            const SizedBox(width: 6),
            _buildRatingButton(rating: 'hard', label: '有點難', activeColor: Colors.orange),
            const SizedBox(width: 6),
            _buildRatingButton(rating: 'good', label: '記得', activeColor: Colors.blue),
            const SizedBox(width: 6),
            _buildRatingButton(rating: 'easy', label: '很簡單', activeColor: Colors.green),
          ],
        ),

        const SizedBox(height: 28),

        // Next button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _selectedRating != null
                ? () async {
                    // Submit answer to notifier
                    await ref.read(reviewNotifierProvider.notifier).submitAnswer(
                          userAnswer: _selectedOption,
                          isCorrect: isUserCorrect,
                          selfRating: _selectedRating!,
                          responseTimeMs: _responseTimeMs,
                        );

                    if (isLast) {
                      if (mounted && context.mounted) {
                        context.pushReplacement('/review/result');
                      }
                    } else {
                      _resetQuestionState();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedRating != null ? colorScheme.primary : null,
              foregroundColor: _selectedRating != null ? colorScheme.onPrimary : null,
            ),
            child: Text(
              isLast ? '查看結果' : '下一題',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingButton({
    required String rating,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _selectedRating == rating;
    final theme = Theme.of(context);

    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedRating = rating;
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(
            color: isSelected ? activeColor : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2.0 : 1.0,
          ),
          backgroundColor: isSelected ? activeColor.withOpacity(0.12) : null,
          foregroundColor: isSelected ? activeColor : theme.colorScheme.onSurface,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('結束複習'),
        content: const Text('確定要結束本次複習嗎？目前進度將不會保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('繼續複習'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
