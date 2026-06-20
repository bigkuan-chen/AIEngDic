import 'package:flutter_test/flutter_test.dart';
import 'package:ai_eng_dic/features/dictionary/domain/dictionary_model.dart';
import 'package:ai_eng_dic/features/favorites/domain/favorites_model.dart';
import 'package:ai_eng_dic/features/review/domain/review_model.dart';
import 'package:ai_eng_dic/features/review/domain/review_engine.dart';

void main() {
  group('ReviewEngine Weight Calculation Tests', () {
    test('Should penalize recently seen words to 0 weight', () {
      final item = ReviewItem(
        id: '1',
        favoriteWordId: 'fav-1',
        normalizedWord: 'apple',
        reviewEnabled: true,
        learningStatus: 'new',
      );

      final weight = ReviewEngine.calculateSelectionWeight(
        item,
        recentWords: ['apple', 'banana'],
        occurrencesInSession: 0,
        mode: 'smart',
      );

      expect(weight, equals(0.0));
    });

    test('Should assign higher weight to overdue items', () {
      final itemOverdue = ReviewItem(
        id: '1',
        favoriteWordId: 'fav-1',
        normalizedWord: 'apple',
        lastReviewedAt: DateTime.now().subtract(const Duration(days: 35)).toIso8601String(),
      );

      final itemRecent = ReviewItem(
        id: '2',
        favoriteWordId: 'fav-2',
        normalizedWord: 'banana',
        lastReviewedAt: DateTime.now().toIso8601String(),
      );

      final weightOverdue = ReviewEngine.calculateSelectionWeight(
        itemOverdue,
        recentWords: [],
        occurrencesInSession: 0,
        mode: 'smart',
      );

      final weightRecent = ReviewEngine.calculateSelectionWeight(
        itemRecent,
        recentWords: [],
        occurrencesInSession: 0,
        mode: 'smart',
      );

      expect(weightOverdue, greaterThan(weightRecent));
    });

    test('Should assign higher weight to high difficulty items', () {
      final itemDifficult = ReviewItem(
        id: '1',
        favoriteWordId: 'fav-1',
        normalizedWord: 'apple',
        difficultyScore: 4.0, // max difficulty
      );

      final itemEasy = ReviewItem(
        id: '2',
        favoriteWordId: 'fav-2',
        normalizedWord: 'banana',
        difficultyScore: 0.5,
      );

      final wDiff = ReviewEngine.calculateSelectionWeight(
        itemDifficult,
        recentWords: [],
        occurrencesInSession: 0,
        mode: 'smart',
      );

      final wEasy = ReviewEngine.calculateSelectionWeight(
        itemEasy,
        recentWords: [],
        occurrencesInSession: 0,
        mode: 'smart',
      );

      expect(wDiff, greaterThan(wEasy));
    });

    test('Should assign lower weight to mastered items', () {
      final itemNew = ReviewItem(
        id: '1',
        favoriteWordId: 'fav-1',
        normalizedWord: 'apple',
        learningStatus: 'new',
      );

      final itemMastered = ReviewItem(
        id: '2',
        favoriteWordId: 'fav-2',
        normalizedWord: 'banana',
        learningStatus: 'mastered',
      );

      final wNew = ReviewEngine.calculateSelectionWeight(
        itemNew,
        recentWords: [],
        occurrencesInSession: 0,
        mode: 'smart',
      );

      final wMastered = ReviewEngine.calculateSelectionWeight(
        itemMastered,
        recentWords: [],
        occurrencesInSession: 0,
        mode: 'smart',
      );

      expect(wNew, greaterThan(wMastered));
    });
  });

  group('ReviewEngine Spaced Repetition Updates Tests', () {
    test('Incorrect answer should override interval to 1 and reset streak', () {
      final item = ReviewItem(
        id: '1',
        favoriteWordId: 'fav-1',
        normalizedWord: 'apple',
        currentIntervalDays: 14,
        streak: 4,
        difficultyScore: 2.0,
      );

      final updated = ReviewEngine.calculateScheduledReview(
        currentItem: item,
        isCorrect: false,
        selfRating: 'forgot',
      );

      expect(updated.currentIntervalDays, equals(1));
      expect(updated.streak, equals(0));
      expect(updated.difficultyScore, equals(2.5)); // +0.5 difficulty
      expect(updated.wrongCount, equals(1));
    });

    test('Correct + Easy rating should increase interval and streak', () {
      final item = ReviewItem(
        id: '1',
        favoriteWordId: 'fav-1',
        normalizedWord: 'apple',
        currentIntervalDays: 4,
        streak: 2,
        difficultyScore: 2.0,
      );

      final updated = ReviewEngine.calculateScheduledReview(
        currentItem: item,
        isCorrect: true,
        selfRating: 'easy',
      );

      expect(updated.currentIntervalDays, equals(12)); // 4 * 3.0
      expect(updated.streak, equals(3));
      expect(updated.difficultyScore, equals(1.75)); // 2.0 - 0.25 difficulty
      expect(updated.correctCount, equals(1));
    });
  });

  group('ReviewEngine Option Distractors Generation Tests', () {
    test('Options should contain correct answer and have 4 distinct values', () {
      final target = FavoriteWord(
        id: 'fav-1',
        word: 'abundant',
        normalizedWord: 'abundant',
        query: 'abundant',
        primaryTranslationZhTw: '豐富的',
        primaryPartOfSpeech: 'adjective',
        savedEntry: DictionaryEntry(
          query: 'abundant',
          detectedInputLanguage: 'en',
          word: 'abundant',
          normalizedWord: 'abundant',
          alternatives: [],
          syllables: [],
          phonetics: Phonetics(),
          meanings: [],
          synonyms: [],
          antonyms: [],
          wordFamily: [],
          collocations: [],
          phrases: [],
          confusingWords: [],
          usageNotes: [],
          commonMistakes: [],
          warnings: [],
          generatedAt: '',
          provider: 'gemini',
          model: 'gemini-2.5-flash',
        ),
        savedAt: '',
        updatedAt: '',
      );

      final pool = [
        target,
        FavoriteWord(
          id: 'fav-2',
          word: 'scarce',
          normalizedWord: 'scarce',
          query: 'scarce',
          primaryTranslationZhTw: '稀少的',
          primaryPartOfSpeech: 'adjective',
          savedEntry: target.savedEntry,
          savedAt: '',
          updatedAt: '',
        ),
        FavoriteWord(
          id: 'fav-3',
          word: 'diligent',
          normalizedWord: 'diligent',
          query: 'diligent',
          primaryTranslationZhTw: '勤奮的',
          primaryPartOfSpeech: 'adjective',
          savedEntry: target.savedEntry,
          savedAt: '',
          updatedAt: '',
        ),
        FavoriteWord(
          id: 'fav-4',
          word: 'vibrant',
          normalizedWord: 'vibrant',
          query: 'vibrant',
          primaryTranslationZhTw: '有活力的',
          primaryPartOfSpeech: 'adjective',
          savedEntry: target.savedEntry,
          savedAt: '',
          updatedAt: '',
        ),
      ];

      final options = ReviewEngine.generateOptions(
        target: target,
        pool: pool,
        questionType: 'en_to_zh',
      );

      expect(options.length, equals(4));
      expect(options, contains('豐富的'));
      expect(options.toSet().length, equals(4));
    });
  });

  group('ReviewEngine Anti-Repetition Sequence Post-Processing Tests', () {
    test('Should reorder questions to avoid consecutive identical words', () {
      final q1 = ReviewQuestion(
        id: '1',
        reviewItemId: 'item-1',
        favoriteWordId: 'fav-1',
        normalizedWord: 'apple',
        questionType: 'en_to_zh',
        prompt: '',
        questionContent: '',
        options: [],
        correctAnswer: '',
        explanation: '',
      );
      final q2 = ReviewQuestion(
        id: '2',
        reviewItemId: 'item-1',
        favoriteWordId: 'fav-1',
        normalizedWord: 'apple', // duplicate consecutive
        questionType: 'zh_to_en',
        prompt: '',
        questionContent: '',
        options: [],
        correctAnswer: '',
        explanation: '',
      );
      final q3 = ReviewQuestion(
        id: '3',
        reviewItemId: 'item-2',
        favoriteWordId: 'fav-2',
        normalizedWord: 'banana',
        questionType: 'en_to_zh',
        prompt: '',
        questionContent: '',
        options: [],
        correctAnswer: '',
        explanation: '',
      );

      final list = [q1, q2, q3];
      ReviewEngine.postProcessSequence(list);

      // Duplicate 'apple' should have been swapped so it is not consecutive
      expect(list[0].normalizedWord, equals('apple'));
      expect(list[1].normalizedWord, equals('banana'));
      expect(list[2].normalizedWord, equals('apple'));
    });
  });
}
