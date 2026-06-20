import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/domain/settings_model.dart';
import '../domain/dictionary_model.dart';

class LLMClient {
  final Dio _dio;

  LLMClient({Dio? dio}) : _dio = dio ?? Dio();

  // SYSTEM PROMPT instructing the model to act as a dictionary and return strict JSON matching our schema
  static const String _systemPrompt = '''
You are an AI English dictionary and English-learning assistant.
The user may enter English (a word, phrase, or sentence) or Traditional Chinese (繁體中文).

Your tasks:
1. If the input is English, identify and explain the English word, phrase, or important vocabulary in the sentence.
2. If the input is Traditional Chinese, return the most appropriate English word or phrase as the main "word", and include alternative translations in the "alternatives" list.
3. Use Traditional Chinese (繁體中文) for translations, definitions, and usage notes.
4. Include concise English definitions.
5. Separate meanings by part of speech.
6. Provide IPA pronunciation for American English (ipaUS) and British English (ipaUK) (e.g. "/pərˈsɪstənt/").
7. Include natural example sentences with Traditional Chinese translations. Highlight the word in the example sentences.
8. Include common collocations, phrases, word forms (verb conjugations, plurals), synonyms, antonyms, and usage notes when applicable.
9. Explain important differences between alternative translations when the query is Chinese.
10. Identify up to four English words that are semantically similar to the primary word but differ in usage, context, collocation, formality, or nuance (populated under the "similarWords" list). Also provide a detailed comparison object (under the "comparison" key) comparing the primary word and these similar words (2 to 5 words total in the comparison list), explaining core differences, usage contexts, formality, common collocations, and example sentences for each.
11. Return valid JSON ONLY. Do not wrap it in markdown code blocks like ```json ... ```. Just return the raw JSON string.

Strictly adhere to the following JSON schema:
{
  "query": "the original user query",
  "detectedInputLanguage": "en" | "zh-TW" | "mixed",
  "word": "the main English word or phrase resolved (always lowercase unless proper noun)",
  "normalizedWord": "lowercase, trimmed version of the word",
  "alternatives": [
    {
      "word": "alternative English translation word",
      "translationZhTw": "Chinese translation of this alternative",
      "difference": "how this alternative differs from the main word in usage/nuance",
      "example": "optional short English example sentence"
    }
  ],
  "syllables": ["syl-la-ble", "di-vi-sion"],
  "phonetics": {
    "ipaUS": "/.../",
    "ipaUK": "/.../",
    "pronunciationText": "approximate phonetic spelling for Chinese speakers, e.g. 普西斯登特"
  },
  "cefrLevel": "A1" | "A2" | "B1" | "B2" | "C1" | "C2" | null,
  "frequency": "very_common" | "common" | "less_common" | "rare" | null,
  "meanings": [
    {
      "partOfSpeech": "noun" | "verb" | "adjective" | "adverb" | "phrase" | "preposition" | "conjunction",
      "transitivity": "transitive" | "intransitive" | "both" | null,
      "countability": "countable" | "uncountable" | "both" | null,
      "definitionEn": "English definition",
      "translationZhTw": "繁體中文翻譯",
      "usageContext": "e.g. medical, formal, colloquial",
      "register": "formal" | "informal" | "neutral" | "slang",
      "examples": [
        {
          "english": "Example sentence in English.",
          "traditionalChinese": "例句的繁體中文翻譯。",
          "highlightedTerm": "the matching word form in the sentence"
        }
      ]
    }
  ],
  "wordForms": {
    "base": "base form",
    "thirdPersonSingular": "verb form, e.g. runs",
    "presentParticiple": "verb form, e.g. running",
    "past": "verb form, e.g. ran",
    "pastParticiple": "verb form, e.g. run",
    "plural": "noun plural, e.g. boxes",
    "comparative": "adjective form, e.g. taller",
    "superlative": "adjective form, e.g. tallest"
  },
  "synonyms": ["synonym1", "synonym2"],
  "antonyms": ["antonym1", "antonym2"],
  "similarWords": [
    {
      "word": "similar English word",
      "normalizedWord": "lowercase word",
      "phonetic": "/.../ or null",
      "partOfSpeech": "part of speech",
      "shortTranslationZhTw": "concise meaning in Traditional Chinese",
      "keyDifference": "how it differs from primary word in Traditional Chinese",
      "relationshipType": "near_synonym" | "contextual_synonym" | "easily_confused"
    }
  ],
  "wordFamily": [
    {
      "word": "related word in family",
      "partOfSpeech": "part of speech",
      "translationZhTw": "繁體中文翻譯"
    }
  ],
  "collocations": [
    {
      "phrase": "common collocation phrase",
      "translationZhTw": "繁體中文翻譯",
      "exampleEn": "collocation example sentence",
      "exampleZhTw": "例句翻譯"
    }
  ],
  "phrases": [
    {
      "phrase": "idiomatic phrase / idiom",
      "translationZhTw": "繁體中文翻譯",
      "definitionEn": "definition in English",
      "exampleEn": "phrase example sentence",
      "exampleZhTw": "例句翻譯"
    }
  ],
  "confusingWords": [
    {
      "word": "similar but confusing word",
      "differenceZhTw": "usage difference explained in Traditional Chinese",
      "exampleEn": "example highlighting difference",
      "exampleZhTw": "example translation"
    }
  ],
  "comparison": {
    "title": "Title template (e.g. accomplish、achieve、complete 與 fulfill)",
    "quickSummary": "Quick summary in Traditional Chinese. Format as a newline-separated list (using \\n) of each word and its brief Core difference (e.g. 'accomplish：完成具體任務\\nachieve：達成目標...'). Do not put it in a single paragraph.",
    "interchangeabilitySummary": "A brief summary in Traditional Chinese explaining whether these words can be interchanged",
    "words": [
      {
        "word": "word string",
        "normalizedWord": "lowercase word",
        "phonetic": "/.../ or null",
        "partOfSpeech": "part of speech",
        "translationZhTw": "Traditional Chinese translation",
        "definitionEn": "Concise English definition",
        "keyDifference": "Key difference from the primary word in Traditional Chinese",
        "usageContext": "Typical usage context in Traditional Chinese",
        "formality": "formal" | "neutral" | "informal" | null,
        "commonCollocations": [
          {
            "phrase": "phrase string",
            "translationZhTw": "Traditional Chinese translation or null"
          }
        ],
        "example": {
          "english": "Example sentence in English.",
          "traditionalChinese": "Traditional Chinese translation."
        },
        "interchangeabilityNote": "Explanation in Traditional Chinese of when it can or cannot replace primary word",
        "isPrimaryWord": true or false
      }
    ]
  },
  "usageNotes": ["nuance or register tip 1", "tip 2"],
  "commonMistakes": ["frequent error or misconception 1"],
  "warnings": ["AI warning or ambiguity note if any"]
}
''';

  /// Validates the API key by running a tiny completion request.
  Future<bool> validateApiKey(String provider, String apiKey, String modelName) async {
    try {
      if (provider.trim().toLowerCase() == 'gemini') {
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey';
        final response = await _dio.post(
          url,
          data: {
            'contents': [
              {
                'parts': [
                  {'text': 'Respond with only the letters: OK'}
                ]
              }
            ],
            'generationConfig': {'maxOutputTokens': 5}
          },
          options: Options(
            headers: {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        
        if (response.statusCode == 200) {
          final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          return text != null && text.contains('OK');
        }
      } else if (provider.trim().toLowerCase() == 'openai') {
        const url = 'https://api.openai.com/v1/chat/completions';
        final response = await _dio.post(
          url,
          data: {
            'model': modelName,
            'messages': [
              {'role': 'user', 'content': 'Respond with only: OK'}
            ],
            'max_tokens': 5
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200) {
          final text = response.data['choices']?[0]?['message']?['content'] as String?;
          return text != null && text.contains('OK');
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Performs dictionary lookup using the selected LLM provider.
  Future<DictionaryEntry> lookupDictionary({
    required String query,
    required String apiKey,
    required AppSettings settings,
  }) async {
    final provider = settings.provider.trim().toLowerCase();
    final modelName = settings.activeModel;

    if (provider == 'gemini') {
      return _lookupGemini(query, apiKey, modelName, settings);
    } else if (provider == 'openai') {
      return _lookupOpenAI(query, apiKey, modelName, settings);
    } else {
      throw Exception('Unsupported provider: ${settings.provider}');
    }
  }

  Future<DictionaryEntry> _lookupGemini(
    String query,
    String apiKey,
    String modelName,
    AppSettings settings,
  ) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey';
    final userPrompt = 'Query: "$query"\nOutput language: ${settings.outputLanguage}\nLearner level: ${settings.learnerLevel}\nEnglish variant preferred: ${settings.englishVariant}';

    try {
      final response = await _dio.post(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {'text': '$_systemPrompt\n\n$userPrompt'}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'temperature': 0.1,
          }
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text == null || text.trim().isEmpty) {
          throw Exception('Gemini 回傳了空的內容。');
        }
        
        final cleanText = _cleanJsonString(text);
        final Map<String, dynamic> parsedJson = jsonDecode(cleanText);
        
        // Enrich metadata fields
        parsedJson['provider'] = 'gemini';
        parsedJson['model'] = modelName;
        
        return DictionaryEntry.fromJson(parsedJson);
      } else {
        throw Exception('Gemini 伺服器回應錯誤: ${response.statusCode} - ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _parseDioError(e);
    } catch (e) {
      throw Exception('解析字典結果時發生錯誤: ${e.toString()}');
    }
  }

  Future<DictionaryEntry> _lookupOpenAI(
    String query,
    String apiKey,
    String modelName,
    AppSettings settings,
  ) async {
    const url = 'https://api.openai.com/v1/chat/completions';
    final userPrompt = 'Query: "$query"\nOutput language: ${settings.outputLanguage}\nLearner level: ${settings.learnerLevel}\nEnglish variant preferred: ${settings.englishVariant}';

    try {
      final response = await _dio.post(
        url,
        data: {
          'model': modelName,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userPrompt}
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.1,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final text = response.data['choices']?[0]?['message']?['content'] as String?;
        if (text == null || text.trim().isEmpty) {
          throw Exception('OpenAI 回傳了空的內容。');
        }

        final cleanText = _cleanJsonString(text);
        final Map<String, dynamic> parsedJson = jsonDecode(cleanText);
        
        // Enrich metadata fields
        parsedJson['provider'] = 'openai';
        parsedJson['model'] = modelName;

        return DictionaryEntry.fromJson(parsedJson);
      } else {
        throw Exception('OpenAI 伺服器回應錯誤: ${response.statusCode} - ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _parseDioError(e);
    } catch (e) {
      throw Exception('解析字典結果時發生錯誤: ${e.toString()}');
    }
  }

  /// Cleans potential LLM formatting anomalies like markdown code blocks
  String _cleanJsonString(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      // Remove starting markdown
      final lines = cleaned.split('\n');
      if (lines.first.startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.last.startsWith('```')) {
        lines.removeLast();
      }
      cleaned = lines.join('\n').trim();
    }
    return cleaned;
  }

  Exception _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return Exception('連線逾時，請檢查網路後重試。');
    }
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return Exception('API Key 無效或已過期，請檢查設定。');
      } else if (statusCode == 429) {
        return Exception('查詢頻率過高或額度不足，請稍後重試。');
      }
      return Exception('伺服器連線錯誤 (代碼: $statusCode): ${e.response!.statusMessage}');
    }
    return Exception('網路連線失敗，請確認是否已連線至網路。');
  }
}

final llmClientProvider = Provider<LLMClient>((ref) {
  return LLMClient();
});
