import 'package:uuid/uuid.dart';

class ReviewItem {
  final String id;
  final String favoriteWordId;
  final String normalizedWord;
  final bool reviewEnabled;
  final String learningStatus; // 'new', 'learning', 'familiar', 'mastered'
  final double difficultyScore; // 0.0 to 4.0
  final int reviewCount;
  final int correctCount;
  final int wrongCount;
  final int streak;
  final int lapseCount;
  final int currentIntervalDays;
  final String? lastReviewedAt;
  final String? nextReviewAt;
  final String? lastQuestionType;
  final List<String> recentQuestionTypes;

  ReviewItem({
    required this.id,
    required this.favoriteWordId,
    required this.normalizedWord,
    this.reviewEnabled = true,
    this.learningStatus = 'new',
    this.difficultyScore = 2.0,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.streak = 0,
    this.lapseCount = 0,
    this.currentIntervalDays = 0,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.lastQuestionType,
    this.recentQuestionTypes = const [],
  });

  ReviewItem copyWith({
    String? id,
    String? favoriteWordId,
    String? normalizedWord,
    bool? reviewEnabled,
    String? learningStatus,
    double? difficultyScore,
    int? reviewCount,
    int? correctCount,
    int? wrongCount,
    int? streak,
    int? lapseCount,
    int? currentIntervalDays,
    String? Function()? lastReviewedAt,
    String? Function()? nextReviewAt,
    String? Function()? lastQuestionType,
    List<String>? recentQuestionTypes,
  }) {
    return ReviewItem(
      id: id ?? this.id,
      favoriteWordId: favoriteWordId ?? this.favoriteWordId,
      normalizedWord: normalizedWord ?? this.normalizedWord,
      reviewEnabled: reviewEnabled ?? this.reviewEnabled,
      learningStatus: learningStatus ?? this.learningStatus,
      difficultyScore: difficultyScore ?? this.difficultyScore,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      streak: streak ?? this.streak,
      lapseCount: lapseCount ?? this.lapseCount,
      currentIntervalDays: currentIntervalDays ?? this.currentIntervalDays,
      lastReviewedAt: lastReviewedAt != null ? lastReviewedAt() : this.lastReviewedAt,
      nextReviewAt: nextReviewAt != null ? nextReviewAt() : this.nextReviewAt,
      lastQuestionType: lastQuestionType != null ? lastQuestionType() : this.lastQuestionType,
      recentQuestionTypes: recentQuestionTypes ?? this.recentQuestionTypes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'favoriteWordId': favoriteWordId,
        'normalizedWord': normalizedWord,
        'reviewEnabled': reviewEnabled,
        'learningStatus': learningStatus,
        'difficultyScore': difficultyScore,
        'reviewCount': reviewCount,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'streak': streak,
        'lapseCount': lapseCount,
        'currentIntervalDays': currentIntervalDays,
        'lastReviewedAt': lastReviewedAt,
        'nextReviewAt': nextReviewAt,
        'lastQuestionType': lastQuestionType,
        'recentQuestionTypes': recentQuestionTypes,
      };

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    var rawRecent = json['recentQuestionTypes'] as List?;
    return ReviewItem(
      id: json['id'] as String? ?? const Uuid().v4(),
      favoriteWordId: json['favoriteWordId'] as String? ?? '',
      normalizedWord: json['normalizedWord'] as String? ?? '',
      reviewEnabled: json['reviewEnabled'] as bool? ?? true,
      learningStatus: json['learningStatus'] as String? ?? 'new',
      difficultyScore: (json['difficultyScore'] as num?)?.toDouble() ?? 2.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      wrongCount: json['wrongCount'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lapseCount: json['lapseCount'] as int? ?? 0,
      currentIntervalDays: json['currentIntervalDays'] as int? ?? 0,
      lastReviewedAt: json['lastReviewedAt'] as String?,
      nextReviewAt: json['nextReviewAt'] as String?,
      lastQuestionType: json['lastQuestionType'] as String?,
      recentQuestionTypes: rawRecent != null ? List<String>.from(rawRecent) : [],
    );
  }
}

class ReviewQuestion {
  final String id;
  final String reviewItemId;
  final String favoriteWordId;
  final String normalizedWord;
  final String questionType; // 'en_to_zh', 'zh_to_en', 'spelling_input', 'context_choice', 'similar_word_choice', 'flashcard'
  final String prompt;
  final String questionContent;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String? exampleEnglish;
  final String? exampleZhTw;
  final String source; // 'favorite_data', 'comparison_data', 'generated_and_cached'

  ReviewQuestion({
    required this.id,
    required this.reviewItemId,
    required this.favoriteWordId,
    required this.normalizedWord,
    required this.questionType,
    required this.prompt,
    required this.questionContent,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.exampleEnglish,
    this.exampleZhTw,
    this.source = 'favorite_data',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'reviewItemId': reviewItemId,
        'favoriteWordId': favoriteWordId,
        'normalizedWord': normalizedWord,
        'questionType': questionType,
        'prompt': prompt,
        'questionContent': questionContent,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'exampleEnglish': exampleEnglish,
        'exampleZhTw': exampleZhTw,
        'source': source,
      };

  factory ReviewQuestion.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'] as List?;
    return ReviewQuestion(
      id: json['id'] as String? ?? const Uuid().v4(),
      reviewItemId: json['reviewItemId'] as String? ?? '',
      favoriteWordId: json['favoriteWordId'] as String? ?? '',
      normalizedWord: json['normalizedWord'] as String? ?? '',
      questionType: json['questionType'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      questionContent: json['questionContent'] as String? ?? '',
      options: rawOptions != null ? List<String>.from(rawOptions) : [],
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      exampleEnglish: json['exampleEnglish'] as String?,
      exampleZhTw: json['exampleZhTw'] as String?,
      source: json['source'] as String? ?? 'favorite_data',
    );
  }
}

class ReviewSession {
  final String id;
  final String mode; // 'smart', 'random', 'difficult'
  final int plannedQuestionCount;
  final int currentQuestionIndex;
  final List<ReviewQuestion> questions;
  final List<String> recentWordIds;
  final String startedAt;
  final String? completedAt;
  final String status; // 'created', 'in_progress', 'completed', 'abandoned'

  ReviewSession({
    required this.id,
    required this.mode,
    required this.plannedQuestionCount,
    required this.currentQuestionIndex,
    required this.questions,
    this.recentWordIds = const [],
    required this.startedAt,
    this.completedAt,
    this.status = 'created',
  });

  ReviewSession copyWith({
    String? id,
    String? mode,
    int? plannedQuestionCount,
    int? currentQuestionIndex,
    List<ReviewQuestion>? questions,
    List<String>? recentWordIds,
    String? startedAt,
    String? Function()? completedAt,
    String? status,
  }) {
    return ReviewSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      plannedQuestionCount: plannedQuestionCount ?? this.plannedQuestionCount,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questions: questions ?? this.questions,
      recentWordIds: recentWordIds ?? this.recentWordIds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'plannedQuestionCount': plannedQuestionCount,
        'currentQuestionIndex': currentQuestionIndex,
        'questions': questions.map((q) => q.toJson()).toList(),
        'recentWordIds': recentWordIds,
        'startedAt': startedAt,
        'completedAt': completedAt,
        'status': status,
      };

  factory ReviewSession.fromJson(Map<String, dynamic> json) {
    var rawQuestions = json['questions'] as List?;
    var parsedQuestions = rawQuestions != null
        ? rawQuestions.map((q) => ReviewQuestion.fromJson(Map<String, dynamic>.from(q as Map))).toList()
        : <ReviewQuestion>[];
    var rawRecentWords = json['recentWordIds'] as List?;

    return ReviewSession(
      id: json['id'] as String? ?? const Uuid().v4(),
      mode: json['mode'] as String? ?? 'smart',
      plannedQuestionCount: json['plannedQuestionCount'] as int? ?? 0,
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      questions: parsedQuestions,
      recentWordIds: rawRecentWords != null ? List<String>.from(rawRecentWords) : [],
      startedAt: json['startedAt'] as String? ?? DateTime.now().toIso8601String(),
      completedAt: json['completedAt'] as String?,
      status: json['status'] as String? ?? 'created',
    );
  }
}

class ReviewAnswer {
  final String id;
  final String sessionId;
  final String questionId;
  final String reviewItemId;
  final String? userAnswer;
  final bool isCorrect;
  final String selfRating; // 'forgot', 'hard', 'good', 'easy'
  final int responseTimeMs;
  final String answeredAt;
  final int previousIntervalDays;
  final int nextIntervalDays;

  ReviewAnswer({
    required this.id,
    required this.sessionId,
    required this.questionId,
    required this.reviewItemId,
    this.userAnswer,
    required this.isCorrect,
    required this.selfRating,
    required this.responseTimeMs,
    required this.answeredAt,
    required this.previousIntervalDays,
    required this.nextIntervalDays,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'questionId': questionId,
        'reviewItemId': reviewItemId,
        'userAnswer': userAnswer,
        'isCorrect': isCorrect,
        'selfRating': selfRating,
        'responseTimeMs': responseTimeMs,
        'answeredAt': answeredAt,
        'previousIntervalDays': previousIntervalDays,
        'nextIntervalDays': nextIntervalDays,
      };

  factory ReviewAnswer.fromJson(Map<String, dynamic> json) {
    return ReviewAnswer(
      id: json['id'] as String? ?? const Uuid().v4(),
      sessionId: json['sessionId'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      reviewItemId: json['reviewItemId'] as String? ?? '',
      userAnswer: json['userAnswer'] as String?,
      isCorrect: json['isCorrect'] as bool? ?? false,
      selfRating: json['selfRating'] as String? ?? 'good',
      responseTimeMs: json['responseTimeMs'] as int? ?? 0,
      answeredAt: json['answeredAt'] as String? ?? DateTime.now().toIso8601String(),
      previousIntervalDays: json['previousIntervalDays'] as int? ?? 0,
      nextIntervalDays: json['nextIntervalDays'] as int? ?? 0,
    );
  }
}
