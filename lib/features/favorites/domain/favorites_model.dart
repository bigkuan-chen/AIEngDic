import '../../dictionary/domain/dictionary_model.dart';

class FavoriteWord {
  final String id;
  final String word;
  final String normalizedWord;
  final String query;
  final String? phonetic;
  final String? primaryPartOfSpeech;
  final String? primaryTranslationZhTw;
  final DictionaryEntry savedEntry;
  final String savedAt;
  final String updatedAt;

  FavoriteWord({
    required this.id,
    required this.word,
    required this.normalizedWord,
    required this.query,
    this.phonetic,
    this.primaryPartOfSpeech,
    this.primaryTranslationZhTw,
    required this.savedEntry,
    required this.savedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'normalizedWord': normalizedWord,
        'query': query,
        'phonetic': phonetic,
        'primaryPartOfSpeech': primaryPartOfSpeech,
        'primaryTranslationZhTw': primaryTranslationZhTw,
        'savedEntry': savedEntry.toJson(),
        'savedAt': savedAt,
        'updatedAt': updatedAt,
      };

  factory FavoriteWord.fromJson(Map<String, dynamic> json) {
    return FavoriteWord(
      id: json['id'] as String? ?? '',
      word: json['word'] as String? ?? '',
      normalizedWord: json['normalizedWord'] as String? ?? '',
      query: json['query'] as String? ?? '',
      phonetic: json['phonetic'] as String?,
      primaryPartOfSpeech: json['primaryPartOfSpeech'] as String?,
      primaryTranslationZhTw: json['primaryTranslationZhTw'] as String?,
      savedEntry: DictionaryEntry.fromJson(Map<String, dynamic>.from(json['savedEntry'] as Map)),
      savedAt: json['savedAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
