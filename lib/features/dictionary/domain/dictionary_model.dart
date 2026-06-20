class TranslationAlternative {
  final String word;
  final String translationZhTw;
  final String difference;
  final String? example;

  TranslationAlternative({
    required this.word,
    required this.translationZhTw,
    required this.difference,
    this.example,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'translationZhTw': translationZhTw,
        'difference': difference,
        'example': example,
      };

  factory TranslationAlternative.fromJson(Map<String, dynamic> json) {
    return TranslationAlternative(
      word: json['word'] as String? ?? '',
      translationZhTw: json['translationZhTw'] as String? ?? '',
      difference: json['difference'] as String? ?? '',
      example: json['example'] as String?,
    );
  }
}

class Phonetics {
  final String? ipaUS;
  final String? ipaUK;
  final String? pronunciationText;

  Phonetics({
    this.ipaUS,
    this.ipaUK,
    this.pronunciationText,
  });

  Map<String, dynamic> toJson() => {
        'ipaUS': ipaUS,
        'ipaUK': ipaUK,
        'pronunciationText': pronunciationText,
      };

  factory Phonetics.fromJson(Map<String, dynamic> json) {
    return Phonetics(
      ipaUS: json['ipaUS'] as String?,
      ipaUK: json['ipaUK'] as String?,
      pronunciationText: json['pronunciationText'] as String?,
    );
  }
}

class DictionaryExample {
  final String english;
  final String traditionalChinese;
  final String? highlightedTerm;

  DictionaryExample({
    required this.english,
    required this.traditionalChinese,
    this.highlightedTerm,
  });

  Map<String, dynamic> toJson() => {
        'english': english,
        'traditionalChinese': traditionalChinese,
        'highlightedTerm': highlightedTerm,
      };

  factory DictionaryExample.fromJson(Map<String, dynamic> json) {
    return DictionaryExample(
      english: json['english'] as String? ?? '',
      traditionalChinese: json['traditionalChinese'] as String? ?? '',
      highlightedTerm: json['highlightedTerm'] as String?,
    );
  }
}

class DictionaryMeaning {
  final String partOfSpeech;
  final String? transitivity;
  final String? countability;
  final String definitionEn;
  final String translationZhTw;
  final String? usageContext;
  final String? register;
  final List<DictionaryExample> examples;

  DictionaryMeaning({
    required this.partOfSpeech,
    this.transitivity,
    this.countability,
    required this.definitionEn,
    required this.translationZhTw,
    this.usageContext,
    this.register,
    required this.examples,
  });

  Map<String, dynamic> toJson() => {
        'partOfSpeech': partOfSpeech,
        'transitivity': transitivity,
        'countability': countability,
        'definitionEn': definitionEn,
        'translationZhTw': translationZhTw,
        'usageContext': usageContext,
        'register': register,
        'examples': examples.map((e) => e.toJson()).toList(),
      };

  factory DictionaryMeaning.fromJson(Map<String, dynamic> json) {
    var rawExamples = json['examples'] as List?;
    List<DictionaryExample> listExamples = rawExamples != null
        ? rawExamples.map((e) => DictionaryExample.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : [];
    return DictionaryMeaning(
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      transitivity: json['transitivity'] as String?,
      countability: json['countability'] as String?,
      definitionEn: json['definitionEn'] as String? ?? '',
      translationZhTw: json['translationZhTw'] as String? ?? '',
      usageContext: json['usageContext'] as String?,
      register: json['register'] as String?,
      examples: listExamples,
    );
  }
}

class WordForms {
  final String? base;
  final String? thirdPersonSingular;
  final String? presentParticiple;
  final String? past;
  final String? pastParticiple;
  final String? plural;
  final String? comparative;
  final String? superlative;

  WordForms({
    this.base,
    this.thirdPersonSingular,
    this.presentParticiple,
    this.past,
    this.pastParticiple,
    this.plural,
    this.comparative,
    this.superlative,
  });

  Map<String, dynamic> toJson() => {
        'base': base,
        'thirdPersonSingular': thirdPersonSingular,
        'presentParticiple': presentParticiple,
        'past': past,
        'pastParticiple': pastParticiple,
        'plural': plural,
        'comparative': comparative,
        'superlative': superlative,
      };

  factory WordForms.fromJson(Map<String, dynamic> json) {
    return WordForms(
      base: json['base'] as String?,
      thirdPersonSingular: json['thirdPersonSingular'] as String?,
      presentParticiple: json['presentParticiple'] as String?,
      past: json['past'] as String?,
      pastParticiple: json['pastParticiple'] as String?,
      plural: json['plural'] as String?,
      comparative: json['comparative'] as String?,
      superlative: json['superlative'] as String?,
    );
  }
}

class RelatedWord {
  final String word;
  final String partOfSpeech;
  final String translationZhTw;

  RelatedWord({
    required this.word,
    required this.partOfSpeech,
    required this.translationZhTw,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'partOfSpeech': partOfSpeech,
        'translationZhTw': translationZhTw,
      };

  factory RelatedWord.fromJson(Map<String, dynamic> json) {
    return RelatedWord(
      word: json['word'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      translationZhTw: json['translationZhTw'] as String? ?? '',
    );
  }
}

class Collocation {
  final String phrase;
  final String translationZhTw;
  final String exampleEn;
  final String exampleZhTw;

  Collocation({
    required this.phrase,
    required this.translationZhTw,
    required this.exampleEn,
    required this.exampleZhTw,
  });

  Map<String, dynamic> toJson() => {
        'phrase': phrase,
        'translationZhTw': translationZhTw,
        'exampleEn': exampleEn,
        'exampleZhTw': exampleZhTw,
      };

  factory Collocation.fromJson(Map<String, dynamic> json) {
    return Collocation(
      phrase: json['phrase'] as String? ?? '',
      translationZhTw: json['translationZhTw'] as String? ?? '',
      exampleEn: json['exampleEn'] as String? ?? '',
      exampleZhTw: json['exampleZhTw'] as String? ?? '',
    );
  }
}

class Phrase {
  final String phrase;
  final String translationZhTw;
  final String definitionEn;
  final String exampleEn;
  final String exampleZhTw;

  Phrase({
    required this.phrase,
    required this.translationZhTw,
    required this.definitionEn,
    required this.exampleEn,
    required this.exampleZhTw,
  });

  Map<String, dynamic> toJson() => {
        'phrase': phrase,
        'translationZhTw': translationZhTw,
        'definitionEn': definitionEn,
        'exampleEn': exampleEn,
        'exampleZhTw': exampleZhTw,
      };

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      phrase: json['phrase'] as String? ?? '',
      translationZhTw: json['translationZhTw'] as String? ?? '',
      definitionEn: json['definitionEn'] as String? ?? '',
      exampleEn: json['exampleEn'] as String? ?? '',
      exampleZhTw: json['exampleZhTw'] as String? ?? '',
    );
  }
}

class ConfusingWord {
  final String word;
  final String differenceZhTw;
  final String exampleEn;
  final String exampleZhTw;

  ConfusingWord({
    required this.word,
    required this.differenceZhTw,
    required this.exampleEn,
    required this.exampleZhTw,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'differenceZhTw': differenceZhTw,
        'exampleEn': exampleEn,
        'exampleZhTw': exampleZhTw,
      };

  factory ConfusingWord.fromJson(Map<String, dynamic> json) {
    return ConfusingWord(
      word: json['word'] as String? ?? '',
      differenceZhTw: json['differenceZhTw'] as String? ?? '',
      exampleEn: json['exampleEn'] as String? ?? '',
      exampleZhTw: json['exampleZhTw'] as String? ?? '',
    );
  }
}

class DictionaryEntry {
  final String query;
  final String detectedInputLanguage;
  final String word;
  final String normalizedWord;
  final List<TranslationAlternative> alternatives;
  final List<String> syllables;
  final Phonetics phonetics;
  final String? cefrLevel;
  final String? frequency;
  final List<DictionaryMeaning> meanings;
  final WordForms? wordForms;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<RelatedWord> wordFamily;
  final List<Collocation> collocations;
  final List<Phrase> phrases;
  final List<ConfusingWord> confusingWords;
  final String comparison;
  final List<SimilarWord> similarWords;
  final WordComparison? comparisonInfo;
  final List<String> usageNotes;
  final List<String> commonMistakes;
  final List<String> warnings;
  final String generatedAt;
  final String provider;
  final String model;

  DictionaryEntry({
    required this.query,
    required this.detectedInputLanguage,
    required this.word,
    required this.normalizedWord,
    required this.alternatives,
    required this.syllables,
    required this.phonetics,
    this.cefrLevel,
    this.frequency,
    required this.meanings,
    this.wordForms,
    required this.synonyms,
    required this.antonyms,
    required this.wordFamily,
    required this.collocations,
    required this.phrases,
    required this.confusingWords,
    this.comparison = '',
    this.similarWords = const [],
    this.comparisonInfo,
    required this.usageNotes,
    required this.commonMistakes,
    required this.warnings,
    required this.generatedAt,
    required this.provider,
    required this.model,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'detectedInputLanguage': detectedInputLanguage,
        'word': word,
        'normalizedWord': normalizedWord,
        'alternatives': alternatives.map((e) => e.toJson()).toList(),
        'syllables': syllables,
        'phonetics': phonetics.toJson(),
        'cefrLevel': cefrLevel,
        'frequency': frequency,
        'meanings': meanings.map((e) => e.toJson()).toList(),
        'wordForms': wordForms?.toJson(),
        'synonyms': synonyms,
        'antonyms': antonyms,
        'wordFamily': wordFamily.map((e) => e.toJson()).toList(),
        'collocations': collocations.map((e) => e.toJson()).toList(),
        'phrases': phrases.map((e) => e.toJson()).toList(),
        'confusingWords': confusingWords.map((e) => e.toJson()).toList(),
        'comparison': comparison,
        'similarWords': similarWords.map((e) => e.toJson()).toList(),
        'comparisonInfo': comparisonInfo?.toJson(),
        'usageNotes': usageNotes,
        'commonMistakes': commonMistakes,
        'warnings': warnings,
        'generatedAt': generatedAt,
        'provider': provider,
        'model': model,
      };

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    var rawAlts = json['alternatives'] as List?;
    var rawSyllables = json['syllables'] as List?;
    var rawMeanings = json['meanings'] as List?;
    var rawSyns = json['synonyms'] as List?;
    var rawAnts = json['antonyms'] as List?;
    var rawFamily = json['wordFamily'] as List?;
    var rawColls = json['collocations'] as List?;
    var rawPhrases = json['phrases'] as List?;
    var rawConfusing = json['confusingWords'] as List?;
    var rawNotes = json['usageNotes'] as List?;
    var rawMistakes = json['commonMistakes'] as List?;
    var rawWarnings = json['warnings'] as List?;

    var rawSimilar = json['similarWords'] as List?;
    List<SimilarWord> parsedSimilar = rawSimilar != null
        ? rawSimilar.map((e) => SimilarWord.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : [];

    WordComparison? parsedComparisonInfo;
    String parsedComparisonText = '';

    if (json['comparison'] != null) {
      if (json['comparison'] is Map) {
        parsedComparisonInfo = WordComparison.fromJson(Map<String, dynamic>.from(json['comparison'] as Map));
        parsedComparisonText = parsedComparisonInfo.quickSummary;
      } else if (json['comparison'] is String) {
        parsedComparisonText = json['comparison'] as String;
      }
    }

    if (json['comparisonInfo'] != null && json['comparisonInfo'] is Map) {
      parsedComparisonInfo = WordComparison.fromJson(Map<String, dynamic>.from(json['comparisonInfo'] as Map));
    }

    return DictionaryEntry(
      query: json['query'] as String? ?? '',
      detectedInputLanguage: json['detectedInputLanguage'] as String? ?? 'unknown',
      word: json['word'] as String? ?? '',
      normalizedWord: json['normalizedWord'] as String? ?? '',
      alternatives: rawAlts != null
          ? rawAlts.map((e) => TranslationAlternative.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : [],
      syllables: rawSyllables != null ? rawSyllables.cast<String>() : [],
      phonetics: json['phonetics'] != null
          ? Phonetics.fromJson(Map<String, dynamic>.from(json['phonetics'] as Map))
          : Phonetics(),
      cefrLevel: json['cefrLevel'] as String?,
      frequency: json['frequency'] as String?,
      meanings: rawMeanings != null
          ? rawMeanings.map((e) => DictionaryMeaning.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : [],
      wordForms: json['wordForms'] != null
          ? WordForms.fromJson(Map<String, dynamic>.from(json['wordForms'] as Map))
          : null,
      synonyms: rawSyns != null ? rawSyns.cast<String>() : [],
      antonyms: rawAnts != null ? rawAnts.cast<String>() : [],
      wordFamily: rawFamily != null
          ? rawFamily.map((e) => RelatedWord.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : [],
      collocations: rawColls != null
          ? rawColls.map((e) => Collocation.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : [],
      phrases: rawPhrases != null
          ? rawPhrases.map((e) => Phrase.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : [],
      confusingWords: rawConfusing != null
          ? rawConfusing.map((e) => ConfusingWord.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : [],
      comparison: parsedComparisonText,
      similarWords: parsedSimilar,
      comparisonInfo: parsedComparisonInfo,
      usageNotes: rawNotes != null ? rawNotes.cast<String>() : [],
      commonMistakes: rawMistakes != null ? rawMistakes.cast<String>() : [],
      warnings: rawWarnings != null ? rawWarnings.cast<String>() : [],
      generatedAt: json['generatedAt'] as String? ?? DateTime.now().toIso8601String(),
      provider: json['provider'] as String? ?? 'gemini',
      model: json['model'] as String? ?? '',
    );
  }
}

class SimilarWord {
  final String word;
  final String normalizedWord;
  final String? phonetic;
  final String? partOfSpeech;
  final String shortTranslationZhTw;
  final String keyDifference;
  final String relationshipType; // 'near_synonym' | 'contextual_synonym' | 'easily_confused'

  SimilarWord({
    required this.word,
    required this.normalizedWord,
    this.phonetic,
    this.partOfSpeech,
    required this.shortTranslationZhTw,
    required this.keyDifference,
    required this.relationshipType,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'normalizedWord': normalizedWord,
    'phonetic': phonetic,
    'partOfSpeech': partOfSpeech,
    'shortTranslationZhTw': shortTranslationZhTw,
    'keyDifference': keyDifference,
    'relationshipType': relationshipType,
  };

  factory SimilarWord.fromJson(Map<String, dynamic> json) {
    return SimilarWord(
      word: json['word'] as String? ?? '',
      normalizedWord: json['normalizedWord'] as String? ?? '',
      phonetic: json['phonetic'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      shortTranslationZhTw: json['shortTranslationZhTw'] as String? ?? '',
      keyDifference: json['keyDifference'] as String? ?? '',
      relationshipType: json['relationshipType'] as String? ?? 'near_synonym',
    );
  }
}

class WordComparison {
  final String title;
  final String quickSummary;
  final String? interchangeabilitySummary;
  final List<ComparisonWord> words;

  WordComparison({
    required this.title,
    required this.quickSummary,
    this.interchangeabilitySummary,
    required this.words,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'quickSummary': quickSummary,
    'interchangeabilitySummary': interchangeabilitySummary,
    'words': words.map((w) => w.toJson()).toList(),
  };

  factory WordComparison.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List?;
    final parsedWords = rawWords != null
        ? rawWords.map((w) => ComparisonWord.fromJson(Map<String, dynamic>.from(w as Map))).toList()
        : <ComparisonWord>[];

    return WordComparison(
      title: json['title'] as String? ?? '',
      quickSummary: json['quickSummary'] as String? ?? '',
      interchangeabilitySummary: json['interchangeabilitySummary'] as String?,
      words: parsedWords,
    );
  }
}

class ComparisonWord {
  final String word;
  final String normalizedWord;
  final String? phonetic;
  final String? partOfSpeech;
  final String translationZhTw;
  final String? definitionEn;
  final String keyDifference;
  final String usageContext;
  final String? formality; // 'formal' | 'neutral' | 'informal' | null
  final List<Collocation> commonCollocations;
  final DictionaryExample example;
  final String? interchangeabilityNote;
  final bool isPrimaryWord;

  ComparisonWord({
    required this.word,
    required this.normalizedWord,
    this.phonetic,
    this.partOfSpeech,
    required this.translationZhTw,
    this.definitionEn,
    required this.keyDifference,
    required this.usageContext,
    this.formality,
    required this.commonCollocations,
    required this.example,
    this.interchangeabilityNote,
    this.isPrimaryWord = false,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'normalizedWord': normalizedWord,
    'phonetic': phonetic,
    'partOfSpeech': partOfSpeech,
    'translationZhTw': translationZhTw,
    'definitionEn': definitionEn,
    'keyDifference': keyDifference,
    'usageContext': usageContext,
    'formality': formality,
    'commonCollocations': commonCollocations.map((c) => c.toJson()).toList(),
    'example': example.toJson(),
    'interchangeabilityNote': interchangeabilityNote,
    'isPrimaryWord': isPrimaryWord,
  };

  factory ComparisonWord.fromJson(Map<String, dynamic> json) {
    final rawColls = json['commonCollocations'] as List?;
    final parsedColls = rawColls != null
        ? rawColls.map((c) => Collocation.fromJson(Map<String, dynamic>.from(c as Map))).toList()
        : <Collocation>[];

    final rawExample = json['example'] as Map?;
    final parsedExample = rawExample != null
        ? DictionaryExample.fromJson(Map<String, dynamic>.from(rawExample))
        : DictionaryExample(english: '', traditionalChinese: '');

    return ComparisonWord(
      word: json['word'] as String? ?? '',
      normalizedWord: json['normalizedWord'] as String? ?? '',
      phonetic: json['phonetic'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      translationZhTw: json['translationZhTw'] as String? ?? '',
      definitionEn: json['definitionEn'] as String?,
      keyDifference: json['keyDifference'] as String? ?? '',
      usageContext: json['usageContext'] as String? ?? '',
      formality: json['formality'] as String?,
      commonCollocations: parsedColls,
      example: parsedExample,
      interchangeabilityNote: json['interchangeabilityNote'] as String?,
      isPrimaryWord: json['isPrimaryWord'] as bool? ?? false,
    );
  }
}

