import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../favorites/domain/favorites_model.dart';
import '../data/review_repository.dart';
import '../domain/review_engine.dart';
import '../domain/review_model.dart';

class ReviewState {
  final ReviewSession? activeSession;
  final List<ReviewItem> reviewItems;
  final List<ReviewAnswer> sessionAnswers;
  final bool isLoading;
  final String? error;

  ReviewState({
    this.activeSession,
    this.reviewItems = const [],
    this.sessionAnswers = const [],
    this.isLoading = false,
    this.error,
  });

  ReviewState copyWith({
    ReviewSession? Function()? activeSession,
    List<ReviewItem>? reviewItems,
    List<ReviewAnswer>? sessionAnswers,
    bool? isLoading,
    String? Function()? error,
  }) {
    return ReviewState(
      activeSession: activeSession != null ? activeSession() : this.activeSession,
      reviewItems: reviewItems ?? this.reviewItems,
      sessionAnswers: sessionAnswers ?? this.sessionAnswers,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final ReviewRepository _repository;

  ReviewNotifier(this._repository) : super(ReviewState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.loadReviewItems();
      state = state.copyWith(
        reviewItems: items,
        isLoading: false,
        error: () => null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => '無法載入複習資料。',
      );
    }
  }

  Future<void> createSession({
    required List<FavoriteWord> favorites,
    required int plannedCount,
    required List<String> enabledTypes,
    required String mode,
  }) async {
    if (favorites.isEmpty) {
      state = state.copyWith(error: () => '尚未加入任何收藏單字。');
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      // 1. Reload items to ensure fresh status and dates
      final items = await _repository.loadReviewItems();

      // 2. Generate questions list using engine
      final questions = ReviewEngine.generateSessionQuestions(
        favorites: favorites,
        reviewItems: items,
        plannedCount: plannedCount,
        enabledTypes: enabledTypes,
        mode: mode,
      );

      if (questions.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: () => '無法產生複習題目，請檢查您的單字與題型設定。',
        );
        return;
      }

      // 3. Create session object
      final newSession = ReviewSession(
        id: const Uuid().v4(),
        mode: mode,
        plannedQuestionCount: questions.length, // use actual count
        currentQuestionIndex: 0,
        questions: questions,
        recentWordIds: [],
        startedAt: DateTime.now().toIso8601String(),
        status: 'in_progress',
      );

      // 4. Save session and answers
      final sessions = await _repository.loadSessions();
      sessions.add(newSession);
      await _repository.saveSessions(sessions);

      state = state.copyWith(
        activeSession: () => newSession,
        sessionAnswers: [],
        reviewItems: items,
        isLoading: false,
        error: () => null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => '建立複習 Session 失敗：$e',
      );
    }
  }

  Future<void> submitAnswer({
    required String? userAnswer,
    required bool isCorrect,
    required String selfRating, // 'forgot', 'hard', 'good', 'easy'
    required int responseTimeMs,
  }) async {
    final session = state.activeSession;
    if (session == null) return;

    final question = session.questions[session.currentQuestionIndex];
    
    // Find target review item
    final itemIndex = state.reviewItems.indexWhere((item) => item.id == question.reviewItemId);
    if (itemIndex == -1) return;

    final currentItem = state.reviewItems[itemIndex];
    final updatedItem = ReviewEngine.calculateScheduledReview(
      currentItem: currentItem,
      isCorrect: isCorrect,
      selfRating: selfRating,
    );

    // Create review answer
    final newAnswer = ReviewAnswer(
      id: const Uuid().v4(),
      sessionId: session.id,
      questionId: question.id,
      reviewItemId: question.reviewItemId,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      selfRating: selfRating,
      responseTimeMs: responseTimeMs,
      answeredAt: DateTime.now().toIso8601String(),
      previousIntervalDays: currentItem.currentIntervalDays,
      nextIntervalDays: updatedItem.currentIntervalDays,
    );

    // Update session index and completed status
    final nextIdx = session.currentQuestionIndex + 1;
    final isCompleted = nextIdx >= session.plannedQuestionCount;
    
    final updatedSession = session.copyWith(
      currentQuestionIndex: nextIdx,
      status: isCompleted ? 'completed' : 'in_progress',
      completedAt: isCompleted ? () => DateTime.now().toIso8601String() : null,
      recentWordIds: [...session.recentWordIds, question.normalizedWord],
    );

    // Save changes to local repository
    try {
      // 1. Save items
      final updatedItems = List<ReviewItem>.from(state.reviewItems);
      updatedItems[itemIndex] = updatedItem;
      await _repository.saveReviewItems(updatedItems);

      // 2. Save session
      final sessions = await _repository.loadSessions();
      final idx = sessions.indexWhere((s) => s.id == session.id);
      if (idx != -1) {
        sessions[idx] = updatedSession;
      } else {
        sessions.add(updatedSession);
      }
      await _repository.saveSessions(sessions);

      // 3. Save answers
      final answers = await _repository.loadAnswers();
      answers.add(newAnswer);
      await _repository.saveAnswers(answers);

      state = state.copyWith(
        activeSession: () => updatedSession,
        sessionAnswers: [...state.sessionAnswers, newAnswer],
        reviewItems: updatedItems,
        error: () => null,
      );
    } catch (e) {
      print('Error saving answer/item updates: $e');
      state = state.copyWith(error: () => '資料儲存失敗，但答題已完成。');
    }
  }

  Future<void> abandonSession() async {
    final session = state.activeSession;
    if (session == null) return;

    final updatedSession = session.copyWith(
      status: 'abandoned',
      completedAt: () => DateTime.now().toIso8601String(),
    );

    try {
      final sessions = await _repository.loadSessions();
      final idx = sessions.indexWhere((s) => s.id == session.id);
      if (idx != -1) {
        sessions[idx] = updatedSession;
      }
      await _repository.saveSessions(sessions);
    } catch (e) {
      print('Error abandoning session: $e');
    }

    state = state.copyWith(
      activeSession: () => null,
      sessionAnswers: [],
    );
  }

  void clearActiveSession() {
    state = state.copyWith(
      activeSession: () => null,
      sessionAnswers: [],
    );
  }
}

// Global provider for ReviewNotifier
final reviewNotifierProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  final repo = ref.watch(reviewRepositoryProvider);
  return ReviewNotifier(repo);
});

// Derived provider to calculate today's pending/due reviews count
final dueReviewCountProvider = Provider<int>((ref) {
  final state = ref.watch(reviewNotifierProvider);
  final now = DateTime.now();
  int count = 0;
  for (var item in state.reviewItems) {
    if (!item.reviewEnabled) continue;
    if (item.nextReviewAt == null) {
      count++;
    } else {
      try {
        final next = DateTime.parse(item.nextReviewAt!);
        if (next.isBefore(now)) {
          count++;
        }
      } catch (_) {
        count++;
      }
    }
  }
  return count;
});

final recentReviewStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final answers = await repo.loadAnswers();
  if (answers.isEmpty) {
    return {'accuracy': 1.0, 'count': 0};
  }
  final recent = answers.length > 50 ? answers.sublist(answers.length - 50) : answers;
  final correct = recent.where((a) => a.isCorrect).length;
  final accuracy = correct / recent.length;
  return {
    'accuracy': accuracy,
    'count': answers.length,
  };
});
