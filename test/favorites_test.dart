import 'package:flutter_test/flutter_test.dart';
import 'package:ai_eng_dic/features/dictionary/domain/dictionary_model.dart';
import 'package:ai_eng_dic/features/favorites/domain/favorites_model.dart';

void main() {
  group('FavoriteWord Model Tests', () {
    test('Should serialize and deserialize FavoriteWord correctly', () {
      final mockEntry = DictionaryEntry(
        query: 'apple',
        detectedInputLanguage: 'en',
        word: 'apple',
        normalizedWord: 'apple',
        alternatives: [],
        syllables: ['ap', 'ple'],
        phonetics: Phonetics(ipaUS: '/ˈæp.əl/'),
        cefrLevel: 'a1',
        frequency: 'very_common',
        meanings: [
          DictionaryMeaning(
            partOfSpeech: 'noun',
            definitionEn: 'A round fruit with red, green, or yellow skin and crisp white flesh.',
            translationZhTw: '蘋果',
            examples: [],
          ),
        ],
        synonyms: [],
        antonyms: [],
        wordFamily: [],
        collocations: [],
        phrases: [],
        confusingWords: [],
        usageNotes: [],
        commonMistakes: [],
        warnings: [],
        generatedAt: '2026-06-20T01:00:00Z',
        provider: 'gemini',
        model: 'gemini-2.5-flash',
      );

      final favorite = FavoriteWord(
        id: 'mock-uuid-1234',
        word: 'apple',
        normalizedWord: 'apple',
        query: 'apple',
        phonetic: '/ˈæp.əl/',
        primaryPartOfSpeech: 'noun',
        primaryTranslationZhTw: '蘋果',
        savedEntry: mockEntry,
        savedAt: '2026-06-20T01:05:00Z',
        updatedAt: '2026-06-20T01:05:00Z',
      );

      // Convert to JSON
      final json = favorite.toJson();

      expect(json['id'], equals('mock-uuid-1234'));
      expect(json['word'], equals('apple'));
      expect(json['normalizedWord'], equals('apple'));
      expect(json['phonetic'], equals('/ˈæp.əl/'));
      expect(json['primaryPartOfSpeech'], equals('noun'));
      expect(json['primaryTranslationZhTw'], equals('蘋果'));
      expect(json['savedAt'], equals('2026-06-20T01:05:00Z'));
      
      // Parse back from JSON
      final parsed = FavoriteWord.fromJson(json);

      expect(parsed.id, equals('mock-uuid-1234'));
      expect(parsed.word, equals('apple'));
      expect(parsed.normalizedWord, equals('apple'));
      expect(parsed.phonetic, equals('/ˈæp.əl/'));
      expect(parsed.primaryPartOfSpeech, equals('noun'));
      expect(parsed.primaryTranslationZhTw, equals('蘋果'));
      expect(parsed.savedEntry.word, equals('apple'));
      expect(parsed.savedEntry.syllables, contains('ap'));
      expect(parsed.savedEntry.meanings[0].translationZhTw, equals('蘋果'));
    });
  });
}
