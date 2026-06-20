import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../dictionary/domain/dictionary_model.dart';
import '../../favorites/domain/favorites_model.dart';
import 'review_model.dart';

class ReviewEngine {
  static final Random _random = Random();

  // --- Weight Calculation ---
  static double calculateSelectionWeight(
    ReviewItem item, {
    required List<String> recentWords,
    required int occurrencesInSession,
    required String mode,
  }) {
    if (!item.reviewEnabled) return 0.0;

    double baseWeight = 1.0;
    double overdueFactor = 1.0;
    double difficultyFactor = 1.0;
    double errorFactor = 1.0;
    double unfamiliarFactor = 1.0;
    double recentPenalty = 1.0;
    double sessionPenalty = 1.0;
    
    // 1. Overdue Factor
    if (item.lastReviewedAt == null) {
      overdueFactor = 2.5;
    } else {
      try {
        final last = DateTime.parse(item.lastReviewedAt!);
        final difference = DateTime.now().difference(last).inDays;
        
        if (difference >= 30) {
          overdueFactor = 2.3;
        } else if (difference >= 14) {
          overdueFactor = 2.0;
        } else if (difference >= 7) {
          overdueFactor = 1.7;
        } else if (difference >= 3) {
          overdueFactor = 1.4;
        } else if (difference >= 1) {
          overdueFactor = 1.2;
        } else {
          // Reviewed today
          overdueFactor = 0.35;
        }
      } catch (_) {
        overdueFactor = 2.5;
      }
    }

    // 2. Difficulty Factor
    difficultyFactor = 1.0 + item.difficultyScore * 0.25;

    // 3. Error Factor
    double errorRate = item.reviewCount > 0 ? item.wrongCount / item.reviewCount : 0.0;
    errorFactor = 1.0 + errorRate * 1.5;

    // 4. Unfamiliar Factor
    switch (item.learningStatus) {
      case 'new':
        unfamiliarFactor = 1.8;
        break;
      case 'learning':
        unfamiliarFactor = 1.5;
        break;
      case 'familiar':
        unfamiliarFactor = 1.0;
        break;
      case 'mastered':
        unfamiliarFactor = 0.55;
        break;
      default:
        unfamiliarFactor = 1.0;
    }

    // Adjust factors based on mode
    if (mode == 'random') {
      overdueFactor = 1.0;
      difficultyFactor = 1.0;
      errorFactor = 1.0;
      unfamiliarFactor = 1.0;
    } else if (mode == 'difficult') {
      errorFactor = 1.0 + errorRate * 3.0; // Very high error rate multiplier
      overdueFactor = overdueFactor * 0.7; // Lower emphasis on time elapsed
    }

    // 5. Recent Penalty
    if (recentWords.isNotEmpty) {
      final index = recentWords.indexOf(item.normalizedWord);
      if (index == 0) {
        recentPenalty = 0.0; // Appeared in last question
      } else if (index == 1 || index == 2) {
        recentPenalty = 0.1; // Appeared in last 3 questions
      } else if (index == 3 || index == 4) {
        recentPenalty = 0.25; // Appeared in last 5 questions
      } else {
        recentPenalty = 1.0;
      }
    }

    // 6. Session Penalty
    if (occurrencesInSession == 0) {
      sessionPenalty = 1.0;
    } else if (occurrencesInSession == 1) {
      sessionPenalty = 0.35;
    } else if (occurrencesInSession == 2) {
      sessionPenalty = 0.12;
    } else {
      sessionPenalty = 0.0; // Max 3 times in a session
    }

    // 7. Random Factor (0.85 to 1.15)
    double randomVal = 0.85 + _random.nextDouble() * 0.30;

    double finalWeight = baseWeight *
        overdueFactor *
        difficultyFactor *
        errorFactor *
        unfamiliarFactor *
        recentPenalty *
        sessionPenalty *
        randomVal;

    return finalWeight;
  }

  // --- Distractor Option Generators (Local Offline Mode) ---
  static List<String> generateOptions({
    required FavoriteWord target,
    required List<FavoriteWord> pool,
    required String questionType,
  }) {
    final List<String> options = [];
    final targetPos = target.primaryPartOfSpeech?.toLowerCase().trim();

    if (questionType == 'en_to_zh') {
      final String correct = target.primaryTranslationZhTw ?? '未知';
      options.add(correct);

      // Distractors: other favorites translations
      final candidates = pool.where((item) => item.normalizedWord != target.normalizedWord).toList();
      candidates.shuffle();

      // Priority 1: Same Part of Speech
      final samePosCandidates = candidates
          .where((item) => item.primaryPartOfSpeech?.toLowerCase().trim() == targetPos)
          .map((item) => item.primaryTranslationZhTw)
          .whereType<String>()
          .toList();

      for (var opt in samePosCandidates) {
        if (!options.contains(opt) && options.length < 4) {
          options.add(opt);
        }
      }

      // Priority 2: Other favorites
      final otherCandidates = candidates
          .map((item) => item.primaryTranslationZhTw)
          .whereType<String>()
          .toList();

      for (var opt in otherCandidates) {
        if (!options.contains(opt) && options.length < 4) {
          options.add(opt);
        }
      }

      // Fallback distractors if list is small
      final fallbacks = ['名詞，表特徵', '動詞，表行為', '形容詞，表狀態', '表示程度的副詞'];
      for (var opt in fallbacks) {
        if (options.length < 4 && !options.contains(opt)) {
          options.add(opt);
        }
      }
    } else if (questionType == 'zh_to_en') {
      final String correct = target.word;
      options.add(correct);

      final candidates = pool.where((item) => item.normalizedWord != target.normalizedWord).toList();
      candidates.shuffle();

      // Priority 1: Similar words if any in entry
      final List<String> similarWords = target.savedEntry.similarWords.map((sw) => sw.word).toList();
      for (var sw in similarWords) {
        if (options.length < 4 && !options.contains(sw) && sw.toLowerCase() != correct.toLowerCase()) {
          options.add(sw);
        }
      }

      // Priority 2: Same part of speech favorites
      final samePosCandidates = candidates
          .where((item) => item.primaryPartOfSpeech?.toLowerCase().trim() == targetPos)
          .map((item) => item.word)
          .toList();

      for (var opt in samePosCandidates) {
        if (!options.contains(opt) && options.length < 4) {
          options.add(opt);
        }
      }

      // Priority 3: Other favorites
      for (var item in candidates) {
        if (!options.contains(item.word) && options.length < 4) {
          options.add(item.word);
        }
      }

      // Fallbacks
      final fallbacks = ['acquire', 'determine', 'attribute', 'evaluate'];
      for (var opt in fallbacks) {
        if (options.length < 4 && !options.contains(opt) && opt.toLowerCase() != correct.toLowerCase()) {
          options.add(opt);
        }
      }
    } else if (questionType == 'context_choice') {
      final String correct = target.word;
      options.add(correct);

      final candidates = pool.where((item) => item.normalizedWord != target.normalizedWord).toList();
      candidates.shuffle();

      // Priority 1: Same Part of Speech favorites
      final samePosCandidates = candidates
          .where((item) => item.primaryPartOfSpeech?.toLowerCase().trim() == targetPos)
          .map((item) => item.word)
          .toList();

      for (var opt in samePosCandidates) {
        if (!options.contains(opt) && options.length < 4) {
          options.add(opt);
        }
      }

      // Priority 2: Other favorites
      for (var item in candidates) {
        if (!options.contains(item.word) && options.length < 4) {
          options.add(item.word);
        }
      }

      // Fallbacks
      final fallbacks = ['accomplish', 'demonstrate', 'predict', 'negotiate'];
      for (var opt in fallbacks) {
        if (options.length < 4 && !options.contains(opt) && opt.toLowerCase() != correct.toLowerCase()) {
          options.add(opt);
        }
      }
    } else if (questionType == 'similar_word_choice') {
      // options are the target word and the comparison/similar words
      options.add(target.word);
      final List<String> similarWords = target.savedEntry.similarWords.map((sw) => sw.word).toList();
      for (var sw in similarWords) {
        if (!options.contains(sw) && options.length < 4) {
          options.add(sw);
        }
      }

      // Fallbacks if no similar words exist
      final candidates = pool.where((item) => item.normalizedWord != target.normalizedWord).toList();
      candidates.shuffle();
      for (var item in candidates) {
        if (options.length < 4 && !options.contains(item.word)) {
          options.add(item.word);
        }
      }

      final fallbacks = ['affect', 'effect', 'accept', 'except'];
      for (var opt in fallbacks) {
        if (options.length < 4 && !options.contains(opt) && opt.toLowerCase() != target.word.toLowerCase()) {
          options.add(opt);
        }
      }
    }

    options.shuffle();
    return options;
  }

  // --- Session Generation Engine ---
  static List<ReviewQuestion> generateSessionQuestions({
    required List<FavoriteWord> favorites,
    required List<ReviewItem> reviewItems,
    required int plannedCount,
    required List<String> enabledTypes,
    required String mode,
  }) {
    if (favorites.isEmpty || reviewItems.isEmpty || enabledTypes.isEmpty) {
      return [];
    }

    final List<ReviewQuestion> questionsList = [];
    final List<String> recentWords = [];
    final Map<String, int> sessionWordOccurrences = {};
    String? lastQuestionType;
    int consecutiveTypeCount = 0;

    // Filter review items: must be in favorites
    final activeWordIds = favorites.map((f) => f.normalizedWord).toSet();
    final eligibleReviewItems = reviewItems.where((item) => activeWordIds.contains(item.normalizedWord)).toList();

    if (eligibleReviewItems.isEmpty) return [];

    // Max occurrences constraints
    final int maxOccurrencesPerWord = (favorites.length >= plannedCount)
        ? 1
        : (favorites.length == 1 ? plannedCount : 2);

    for (int qIdx = 0; qIdx < plannedCount; qIdx++) {
      ReviewItem? selectedItem;
      double maxWeight = -1.0;

      // Calculate weights and pick item
      for (var item in eligibleReviewItems) {
        final occurrences = sessionWordOccurrences[item.normalizedWord] ?? 0;
        if (occurrences >= maxOccurrencesPerWord) continue;

        // Constraint: No consecutive duplicate words
        if (recentWords.isNotEmpty && recentWords.first == item.normalizedWord && eligibleReviewItems.length > 1) {
          continue;
        }

        final weight = calculateSelectionWeight(
          item,
          recentWords: recentWords,
          occurrencesInSession: occurrences,
          mode: mode,
        );

        if (weight > maxWeight) {
          maxWeight = weight;
          selectedItem = item;
        }
      }

      // Fallback: relax consecutive duplicate word constraint if needed
      if (selectedItem == null) {
        for (var item in eligibleReviewItems) {
          final occurrences = sessionWordOccurrences[item.normalizedWord] ?? 0;
          if (occurrences >= maxOccurrencesPerWord) continue;

          final weight = calculateSelectionWeight(
            item,
            recentWords: const [], // ignore recent penalty
            occurrencesInSession: occurrences,
            mode: mode,
          );

          if (weight > maxWeight) {
            maxWeight = weight;
            selectedItem = item;
          }
        }
      }

      if (selectedItem == null) {
        // No more words can be chosen (constraints are fully exhausted)
        break;
      }

      // Find the favorite word metadata
      final FavoriteWord favoriteWord = favorites.firstWhere((f) => f.normalizedWord == selectedItem!.normalizedWord);

      // Choose question type based on word learning status preferred types
      final List<String> typeCandidates = List<String>.from(enabledTypes);
      
      // Filter out types based on target details (e.g. context_choice needs example sentences, similar_word_choice needs similarWords)
      if (favoriteWord.savedEntry.meanings.isEmpty || 
          favoriteWord.savedEntry.meanings.first.examples.isEmpty) {
        typeCandidates.remove('context_choice');
      }
      if (favoriteWord.savedEntry.similarWords.isEmpty) {
        typeCandidates.remove('similar_word_choice');
      }

      // If candidates are empty, fallback to basic ones
      if (typeCandidates.isEmpty) {
        typeCandidates.addAll(enabledTypes.where((t) => t == 'en_to_zh' || t == 'zh_to_en'));
      }
      if (typeCandidates.isEmpty) {
        typeCandidates.add('en_to_zh');
      }

      // Weighted selection of type
      String chosenType = typeCandidates.first;
      if (typeCandidates.length > 1) {
        final Map<String, double> statusWeights = _getTypePreferencesForStatus(selectedItem.learningStatus);
        double totalTypeWeight = 0.0;
        final List<double> cumulativeWeights = [];
        
        for (var t in typeCandidates) {
          double w = statusWeights[t] ?? 0.25;
          
          // Anti-repetition penalties:
          // Same type consecutively
          if (lastQuestionType == t) {
            w *= (consecutiveTypeCount >= 2 ? 0.05 : 0.3);
          }
          // Same word repeats must change type
          if (sessionWordOccurrences.containsKey(selectedItem.normalizedWord)) {
            // This word has appeared before in this session, discourage last type
            w *= 0.1;
          }

          totalTypeWeight += w;
          cumulativeWeights.add(totalTypeWeight);
        }

        if (totalTypeWeight > 0.0) {
          final rand = _random.nextDouble() * totalTypeWeight;
          for (int i = 0; i < typeCandidates.length; i++) {
            if (rand <= cumulativeWeights[i]) {
              chosenType = typeCandidates[i];
              break;
            }
          }
        } else {
          chosenType = typeCandidates[_random.nextInt(typeCandidates.length)];
        }
      }

      // Generate prompt and question content
      String prompt = '請選出最適合的中文意思';
      String content = favoriteWord.word;
      String correctAnswer = favoriteWord.primaryTranslationZhTw ?? '未知';
      String explanation = '單字釋義與例句說明';
      String? exEn;
      String? exZh;

      if (chosenType == 'en_to_zh') {
        prompt = '請選出最適合的中文意思';
        content = favoriteWord.word;
        correctAnswer = favoriteWord.primaryTranslationZhTw ?? '未知';
        explanation = '${favoriteWord.word} (${favoriteWord.primaryPartOfSpeech ?? ""}): ${favoriteWord.primaryTranslationZhTw}';
        
        if (favoriteWord.savedEntry.meanings.isNotEmpty &&
            favoriteWord.savedEntry.meanings.first.examples.isNotEmpty) {
          final firstEx = favoriteWord.savedEntry.meanings.first.examples.first;
          exEn = firstEx.english;
          exZh = firstEx.traditionalChinese;
        }
      } else if (chosenType == 'zh_to_en') {
        prompt = '請選出最適合的英文單字';
        content = favoriteWord.primaryTranslationZhTw ?? '未知';
        correctAnswer = favoriteWord.word;
        explanation = '${favoriteWord.word} (${favoriteWord.primaryPartOfSpeech ?? ""}): ${favoriteWord.primaryTranslationZhTw}';
        
        if (favoriteWord.savedEntry.meanings.isNotEmpty &&
            favoriteWord.savedEntry.meanings.first.examples.isNotEmpty) {
          final firstEx = favoriteWord.savedEntry.meanings.first.examples.first;
          exEn = firstEx.english;
          exZh = firstEx.traditionalChinese;
        }
      } else if (chosenType == 'context_choice') {
        prompt = '哪個單字最適合填入句子？';
        
        // Pick an example sentence
        DictionaryExample? example;
        if (favoriteWord.savedEntry.meanings.isNotEmpty &&
            favoriteWord.savedEntry.meanings.first.examples.isNotEmpty) {
          example = favoriteWord.savedEntry.meanings.first.examples.first;
        } else if (favoriteWord.savedEntry.meanings.length > 1 &&
            favoriteWord.savedEntry.meanings[1].examples.isNotEmpty) {
          example = favoriteWord.savedEntry.meanings[1].examples.first;
        }

        if (example != null) {
          exEn = example.english;
          exZh = example.traditionalChinese;
          
          // Blank out target word in sentence
          // Regex match whole word to prevent partial matching (e.g. matching 'apple' inside 'apples')
          final regex = RegExp(r'\b' + RegExp.escape(favoriteWord.word) + r'\b', caseSensitive: false);
          if (regex.hasMatch(example.english)) {
            content = example.english.replaceAll(regex, '_______');
          } else {
            // Fallback case-insensitive replace
            content = example.english.replaceAll(RegExp(favoriteWord.word, caseSensitive: false), '_______');
          }
          
          correctAnswer = favoriteWord.word;
          explanation = '句子正確寫法為：\n"${example.english}"\n翻譯為：${example.traditionalChinese}';
        } else {
          // Fallback if no sentence (shouldn't happen because of filtering candidates)
          content = 'Please fill in the blank with: ${favoriteWord.primaryTranslationZhTw}';
          correctAnswer = favoriteWord.word;
          explanation = '無例句，單字釋義為：${favoriteWord.primaryTranslationZhTw}';
        }
      } else if (chosenType == 'similar_word_choice') {
        prompt = '根據情境選出最自然的單字';
        
        if (favoriteWord.savedEntry.similarWords.isNotEmpty) {
          final firstSimilar = favoriteWord.savedEntry.similarWords.first;
          content = '語意辨析：在以下句子的空格中，應該填入哪一個單字？\n\n'
              '${targetSentenceWithBlank(favoriteWord.savedEntry, favoriteWord.word)}\n'
              '提示（區別）：${firstSimilar.keyDifference}';
          
          correctAnswer = favoriteWord.word;
          explanation = '辨析比較：\n'
              ' - ${favoriteWord.word}: ${favoriteWord.primaryTranslationZhTw ?? ""}\n'
              ' - ${firstSimilar.word}: ${firstSimilar.shortTranslationZhTw}\n'
              '核心差異：${firstSimilar.keyDifference}';
        } else {
          content = '語意填空：請選出最自然的字 \n\n${targetSentenceWithBlank(favoriteWord.savedEntry, favoriteWord.word)}';
          correctAnswer = favoriteWord.word;
          explanation = '${favoriteWord.word}: ${favoriteWord.primaryTranslationZhTw}';
        }

        if (favoriteWord.savedEntry.meanings.isNotEmpty &&
            favoriteWord.savedEntry.meanings.first.examples.isNotEmpty) {
          final firstEx = favoriteWord.savedEntry.meanings.first.examples.first;
          exEn = firstEx.english;
          exZh = firstEx.traditionalChinese;
        }
      }

      final List<String> options = generateOptions(
        target: favoriteWord,
        pool: favorites,
        questionType: chosenType,
      );

      final question = ReviewQuestion(
        id: 'req-${qIdx + 1}-${Uuid().v4()}',
        reviewItemId: selectedItem.id,
        favoriteWordId: favoriteWord.id,
        normalizedWord: selectedItem.normalizedWord,
        questionType: chosenType,
        prompt: prompt,
        questionContent: content,
        options: options,
        correctAnswer: correctAnswer,
        explanation: explanation,
        exampleEnglish: exEn,
        exampleZhTw: exZh,
        source: 'favorite_data',
      );

      questionsList.add(question);

      // Update trackers
      if (recentWords.length >= 5) recentWords.removeLast();
      recentWords.insert(0, selectedItem.normalizedWord);

      sessionWordOccurrences[selectedItem.normalizedWord] = (sessionWordOccurrences[selectedItem.normalizedWord] ?? 0) + 1;

      if (lastQuestionType == chosenType) {
        consecutiveTypeCount++;
      } else {
        lastQuestionType = chosenType;
        consecutiveTypeCount = 1;
      }
    }

    // Sequence Post-processing: anti-repetition swap
    postProcessSequence(questionsList);

    return questionsList;
  }

  static String targetSentenceWithBlank(DictionaryEntry entry, String targetWord) {
    if (entry.meanings.isNotEmpty && entry.meanings.first.examples.isNotEmpty) {
      final text = entry.meanings.first.examples.first.english;
      final regex = RegExp(r'\b' + RegExp.escape(targetWord) + r'\b', caseSensitive: false);
      if (regex.hasMatch(text)) {
        return text.replaceAll(regex, '_______');
      }
      return text.replaceAll(RegExp(targetWord, caseSensitive: false), '_______');
    }
    return 'We need to _______ the goal.';
  }

  static Map<String, double> _getTypePreferencesForStatus(String status) {
    switch (status) {
      case 'new':
        return {'en_to_zh': 0.45, 'zh_to_en': 0.30, 'context_choice': 0.15, 'similar_word_choice': 0.10};
      case 'learning':
        return {'en_to_zh': 0.20, 'zh_to_en': 0.30, 'context_choice': 0.30, 'similar_word_choice': 0.20};
      case 'familiar':
        return {'en_to_zh': 0.10, 'zh_to_en': 0.25, 'context_choice': 0.35, 'similar_word_choice': 0.30};
      case 'mastered':
        return {'en_to_zh': 0.05, 'zh_to_en': 0.20, 'context_choice': 0.35, 'similar_word_choice': 0.40};
      default:
        return {'en_to_zh': 0.25, 'zh_to_en': 0.25, 'context_choice': 0.25, 'similar_word_choice': 0.25};
    }
  }

  // --- Anti-Repetition Sequence Post-Processing ---
  static void postProcessSequence(List<ReviewQuestion> list) {
    if (list.length <= 2) return;

    // 1. Avoid consecutive duplicate words
    for (int i = 0; i < list.length - 1; i++) {
      if (list[i].normalizedWord == list[i + 1].normalizedWord) {
        // Find a subsequent question with a different word to swap with
        int swapIdx = -1;
        for (int j = i + 2; j < list.length; j++) {
          if (list[j].normalizedWord != list[i].normalizedWord &&
              (i == 0 || list[j].normalizedWord != list[i - 1].normalizedWord)) {
            swapIdx = j;
            break;
          }
        }

        // Perform swap
        if (swapIdx != -1) {
          final temp = list[i + 1];
          list[i + 1] = list[swapIdx];
          list[swapIdx] = temp;
        }
      }
    }

    // 2. Avoid consecutive duplicate question types (> 3 times)
    int consecutiveCount = 1;
    String lastType = list[0].questionType;

    for (int i = 1; i < list.length; i++) {
      if (list[i].questionType == lastType) {
        consecutiveCount++;
        if (consecutiveCount > 3) {
          // Find a subsequent question with a different type to swap
          int swapIdx = -1;
          for (int j = i + 1; j < list.length; j++) {
            if (list[j].questionType != lastType) {
              swapIdx = j;
              break;
            }
          }
          if (swapIdx != -1) {
            final temp = list[i];
            list[i] = list[swapIdx];
            list[swapIdx] = temp;
            lastType = list[i].questionType;
            consecutiveCount = 1;
          }
        }
      } else {
        lastType = list[i].questionType;
        consecutiveCount = 1;
      }
    }
  }

  // --- Simplified Spaced Repetition Scheduling Interval Algorithm ---
  static ReviewItem calculateScheduledReview({
    required ReviewItem currentItem,
    required bool isCorrect,
    required String selfRating, // 'forgot', 'hard', 'good', 'easy'
  }) {
    int nextInterval = currentItem.currentIntervalDays;
    double difficultyChange = 0.0;
    int newStreak = currentItem.streak;
    int newLapse = currentItem.lapseCount;

    if (!isCorrect) {
      // Incorrect answer override
      nextInterval = 1;
      difficultyChange = 0.5;
      newStreak = 0;
      newLapse += 1;
    } else {
      // Correct answer scheduling
      newStreak += 1;
      switch (selfRating) {
        case 'forgot':
          nextInterval = 1;
          difficultyChange = 0.5;
          newStreak = 0;
          newLapse += 1;
          break;
        case 'hard':
          nextInterval = max(1, (currentItem.currentIntervalDays * 1.2).round());
          difficultyChange = 0.2;
          break;
        case 'good':
          if (currentItem.currentIntervalDays == 0) {
            nextInterval = 2; // initial interval
          } else {
            nextInterval = max(2, (currentItem.currentIntervalDays * 2.0).round());
          }
          difficultyChange = -0.1;
          break;
        case 'easy':
          if (currentItem.currentIntervalDays == 0) {
            nextInterval = 4;
          } else {
            nextInterval = max(4, (currentItem.currentIntervalDays * 3.0).round());
          }
          difficultyChange = -0.25;
          break;
        default:
          nextInterval = max(1, (currentItem.currentIntervalDays * 1.5).round());
      }
    }

    // Interval limits: minimum 1 day, maximum 180 days
    if (nextInterval < 1) nextInterval = 1;
    if (nextInterval > 180) nextInterval = 180;

    // Difficulty score boundary constraints (0.0 to 4.0)
    double newDifficulty = currentItem.difficultyScore + difficultyChange;
    if (newDifficulty < 0.0) newDifficulty = 0.0;
    if (newDifficulty > 4.0) newDifficulty = 4.0;

    // Review counts
    final newReviewCount = currentItem.reviewCount + 1;
    final newCorrectCount = currentItem.correctCount + (isCorrect ? 1 : 0);
    final newWrongCount = currentItem.wrongCount + (isCorrect ? 0 : 1);

    // Calculate dates
    final now = DateTime.now();
    final nextReviewDate = now.add(Duration(days: nextInterval));

    // Update learning status progression
    String newStatus = currentItem.learningStatus;
    if (currentItem.learningStatus == 'new') {
      newStatus = 'learning'; // Transition on first review complete
    } else if (currentItem.learningStatus == 'learning') {
      // learning -> familiar: streak >= 3 and correct rate >= 80%
      final correctRate = newReviewCount > 0 ? (newCorrectCount / newReviewCount) : 0.0;
      if (newStreak >= 3 && correctRate >= 0.80) {
        newStatus = 'familiar';
      }
    } else if (currentItem.learningStatus == 'familiar') {
      // familiar -> mastered: streak >= 5 and correct rate >= 90%
      final correctRate = newReviewCount > 0 ? (newCorrectCount / newReviewCount) : 0.0;
      if (newStreak >= 5 && correctRate >= 0.90) {
        newStatus = 'mastered';
      }
    }

    // Downgrades:
    if (!isCorrect) {
      if (currentItem.learningStatus == 'mastered') {
        newStatus = 'familiar'; // Mastered to familiar on single error
      } else if (currentItem.learningStatus == 'familiar') {
        newStatus = 'learning'; // Familiar to learning on error
      }
    }

    return currentItem.copyWith(
      reviewCount: newReviewCount,
      correctCount: newCorrectCount,
      wrongCount: newWrongCount,
      streak: newStreak,
      lapseCount: newLapse,
      currentIntervalDays: nextInterval,
      difficultyScore: newDifficulty,
      learningStatus: newStatus,
      lastReviewedAt: () => now.toIso8601String(),
      nextReviewAt: () => nextReviewDate.toIso8601String(),
    );
  }
}
