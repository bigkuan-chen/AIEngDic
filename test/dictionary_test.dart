import 'package:flutter_test/flutter_test.dart';
import '../lib/features/dictionary/domain/dictionary_model.dart';
import '../lib/features/dictionary/data/llm_client.dart';
import '../lib/features/settings/domain/settings_model.dart';

void main() {
  group('DictionaryEntry Model Tests', () {
    test('Should parse a valid dictionary entry JSON successfully', () {
      final json = {
        'query': 'persistent',
        'detectedInputLanguage': 'en',
        'word': 'persistent',
        'normalizedWord': 'persistent',
        'alternatives': [
          {
            'word': 'tenacious',
            'translationZhTw': '堅韌的',
            'difference': '堅韌的偏重意志力，persistent偏重持續性。',
            'example': 'She is tenacious in pursuing her goals.'
          }
        ],
        'syllables': ['per', 'sis', 'tent'],
        'phonetics': {
          'ipaUS': '/pərˈsɪstənt/',
          'ipaUK': '/pəˈsɪstənt/',
          'pronunciationText': '普西斯登特'
        },
        'cefrLevel': 'b2',
        'frequency': 'common',
        'meanings': [
          {
            'partOfSpeech': 'adjective',
            'transitivity': null,
            'countability': null,
            'definitionEn': 'Continuing firmly or obstinately in a course of action in spite of difficulty or opposition.',
            'translationZhTw': '堅持不懈的；執意的；持續的',
            'usageContext': null,
            'register': 'neutral',
            'examples': [
              {
                'english': 'He is persistent in his efforts to learn English.',
                'traditionalChinese': '他堅持不懈地努力學習英文。',
                'highlightedTerm': 'persistent'
              }
            ]
          }
        ],
        'wordForms': {
          'base': 'persistent',
          'thirdPersonSingular': null,
          'presentParticiple': null,
          'past': null,
          'pastParticiple': null,
          'plural': null,
          'comparative': null,
          'superlative': null
        },
        'synonyms': ['tenacious', 'obstinate', 'constant'],
        'antonyms': ['lazy', 'irresolute', 'temporary'],
        'wordFamily': [
          {
            'word': 'persistency',
            'partOfSpeech': 'noun',
            'translationZhTw': '堅持'
          }
        ],
        'collocations': [
          {
            'phrase': 'persistent effort',
            'translationZhTw': '持續的努力',
            'exampleEn': 'Persistent effort leads to success.',
            'exampleZhTw': '持續的努力會帶來成功。'
          }
        ],
        'phrases': [],
        'confusingWords': [],
        'usageNotes': ['常用於正面描述堅持不懈，但有時也可用於負面描述令人厭煩的糾纏。'],
        'commonMistakes': ['不要將 persistent 誤拼寫為 persistant。'],
        'warnings': [],
        'generatedAt': '2026-06-20T01:00:00Z',
        'provider': 'gemini',
        'model': 'gemini-2.5-flash'
      };

      final entry = DictionaryEntry.fromJson(json);

      expect(entry.query, equals('persistent'));
      expect(entry.word, equals('persistent'));
      expect(entry.normalizedWord, equals('persistent'));
      expect(entry.alternatives.length, equals(1));
      expect(entry.alternatives[0].word, equals('tenacious'));
      expect(entry.phonetics.ipaUS, equals('/pərˈsɪstənt/'));
      expect(entry.phonetics.pronunciationText, equals('普西斯登特'));
      expect(entry.cefrLevel, equals('b2'));
      expect(entry.meanings.length, equals(1));
      expect(entry.meanings[0].partOfSpeech, equals('adjective'));
      expect(entry.meanings[0].examples.length, equals(1));
      expect(entry.meanings[0].examples[0].highlightedTerm, equals('persistent'));
      expect(entry.synonyms, contains('tenacious'));
      expect(entry.antonyms, contains('lazy'));
      expect(entry.wordFamily[0].word, equals('persistency'));
      expect(entry.collocations[0].phrase, equals('persistent effort'));
      expect(entry.provider, equals('gemini'));
      expect(entry.model, equals('gemini-2.5-flash'));
    });

    test('Should handle null or empty optional list fields gracefully', () {
      final json = {
        'query': 'look',
        'detectedInputLanguage': 'en',
        'word': 'look',
        'normalizedWord': 'look',
        'alternatives': null,
        'syllables': null,
        'phonetics': null,
        'cefrLevel': null,
        'frequency': null,
        'meanings': null,
        'wordForms': null,
        'synonyms': null,
        'antonyms': null,
        'wordFamily': null,
        'collocations': null,
        'phrases': null,
        'confusingWords': null,
        'usageNotes': null,
        'commonMistakes': null,
        'warnings': null,
        'generatedAt': null,
        'provider': null,
        'model': null
      };

      final entry = DictionaryEntry.fromJson(json);

      expect(entry.query, equals('look'));
      expect(entry.word, equals('look'));
      expect(entry.alternatives, isEmpty);
      expect(entry.syllables, isEmpty);
      expect(entry.meanings, isEmpty);
      expect(entry.synonyms, isEmpty);
      expect(entry.antonyms, isEmpty);
      expect(entry.wordFamily, isEmpty);
      expect(entry.collocations, isEmpty);
      expect(entry.phrases, isEmpty);
      expect(entry.confusingWords, isEmpty);
      expect(entry.usageNotes, isEmpty);
      expect(entry.commonMistakes, isEmpty);
      expect(entry.warnings, isEmpty);
      expect(entry.phonetics.ipaUS, isNull);
    });

    test('Should parse similarWords and comparisonInfo JSON successfully', () {
      final json = {
        'query': 'accomplish',
        'detectedInputLanguage': 'en',
        'word': 'accomplish',
        'normalizedWord': 'accomplish',
        'similarWords': [
          {
            'word': 'achieve',
            'normalizedWord': 'achieve',
            'phonetic': '/əˈtʃiːv/',
            'partOfSpeech': 'verb',
            'shortTranslationZhTw': '達成目標',
            'keyDifference': '強調取得成果或達到目標',
            'relationshipType': 'near_synonym'
          }
        ],
        'comparison': {
          'title': 'accomplish 與 achieve 比較',
          'quickSummary': 'accomplish 強調工作完成；achieve 強調成就與目標。',
          'interchangeabilitySummary': '部分情況可互換',
          'words': [
            {
              'word': 'accomplish',
              'normalizedWord': 'accomplish',
              'phonetic': '/əˈkʌmplɪʃ/',
              'partOfSpeech': 'verb',
              'translationZhTw': '完成',
              'definitionEn': 'To succeed in doing something.',
              'keyDifference': '主要字核心差異',
              'usageContext': '任務',
              'formality': 'neutral',
              'commonCollocations': [
                {
                  'phrase': 'accomplish a task',
                  'translationZhTw': '完成任務'
                }
              ],
              'example': {
                'english': 'We accomplished it.',
                'traditionalChinese': '我們完成了。'
              },
              'interchangeabilityNote': '可與 achieve 互換',
              'isPrimaryWord': true
            }
          ]
        }
      };

      final entry = DictionaryEntry.fromJson(json);

      expect(entry.similarWords.length, equals(1));
      expect(entry.similarWords[0].word, equals('achieve'));
      expect(entry.similarWords[0].relationshipType, equals('near_synonym'));
      expect(entry.comparisonInfo, isNotNull);
      expect(entry.comparisonInfo!.title, equals('accomplish 與 achieve 比較'));
      expect(entry.comparisonInfo!.words.length, equals(1));
      expect(entry.comparisonInfo!.words[0].word, equals('accomplish'));
      expect(entry.comparisonInfo!.words[0].isPrimaryWord, isTrue);
      expect(entry.comparison, equals('accomplish 強調工作完成；achieve 強調成就與目標。'));
    });

    test('Integration test with real Gemini API lookup', () async {
      final apiKey = const String.fromEnvironment('GEMINI_API_KEY');
      if (apiKey.isEmpty) {
        print('Skipping real API test because GEMINI_API_KEY is not defined.');
        return;
      }
      final client = LLMClient();
      final settings = AppSettings.defaultSettings();
      try {
        final result = await client.lookupDictionary(
          query: 'accomplish',
          apiKey: apiKey,
          settings: settings,
        );
        print('Parsed successfully!');
        print('Word: ${result.word}');
        print('Similar words: ${result.similarWords.map((sw) => sw.word).toList()}');
        print('Comparison title: ${result.comparisonInfo?.title}');
        expect(result.word, equals('accomplish'));
        expect(result.similarWords, isNotEmpty);
        expect(result.comparisonInfo, isNotNull);
      } catch (e) {
        print('Error during real lookup: $e');
        rethrow;
      }
    });
  });
}
