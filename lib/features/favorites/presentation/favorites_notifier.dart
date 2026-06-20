import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/favorites_model.dart';
import '../data/favorites_repository.dart';
import '../../dictionary/domain/dictionary_model.dart';
import '../../review/data/review_repository.dart';
import '../../review/domain/review_model.dart';

class FavoritesState {
  final List<FavoriteWord> items;
  final String sortBy; // 'savedAt_desc', 'word_asc', 'word_desc'
  final String searchQuery;
  final bool isLoading;

  FavoritesState({
    required this.items,
    this.sortBy = 'savedAt_desc',
    this.searchQuery = '',
    this.isLoading = false,
  });

  List<FavoriteWord> get filteredAndSortedItems {
    var list = items;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      list = list.where((item) {
        final matchesWord = item.word.toLowerCase().contains(query);
        final matchesTranslation = item.primaryTranslationZhTw?.toLowerCase().contains(query) ?? false;
        final matchesQuery = item.query.toLowerCase().contains(query);
        return matchesWord || matchesTranslation || matchesQuery;
      }).toList();
    }

    final sorted = List<FavoriteWord>.from(list);
    if (sortBy == 'word_asc') {
      sorted.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    } else if (sortBy == 'word_desc') {
      sorted.sort((a, b) => b.word.toLowerCase().compareTo(a.word.toLowerCase()));
    } else if (sortBy == 'savedAt_asc') {
      sorted.sort((a, b) => a.savedAt.compareTo(b.savedAt));
    } else {
      // default: savedAt_desc
      sorted.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    }
    return sorted;
  }

  FavoritesState copyWith({
    List<FavoriteWord>? items,
    String? sortBy,
    String? searchQuery,
    bool? isLoading,
  }) {
    return FavoritesState(
      items: items ?? this.items,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FavoritesNotifier extends StateNotifier<List<FavoriteWord>> {
  final FavoritesRepository _repository;
  final Ref _ref;

  FavoritesNotifier(this._repository, this._ref) : super([]) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final list = await _repository.loadFavorites();
    state = list;
  }

  Future<void> addFavorite(DictionaryEntry entry) async {
    // BR-002: Ensure we don't save duplicate normalizedWord values
    final normalized = entry.normalizedWord.trim().toLowerCase();
    
    // Check if duplicate already exists
    if (state.any((item) => item.normalizedWord == normalized)) {
      return; // Already favorited
    }

    // Identify primary meaning and part of speech for rapid rendering
    String? primaryPOS;
    String? primaryTranslation;
    if (entry.meanings.isNotEmpty) {
      primaryPOS = entry.meanings.first.partOfSpeech;
      primaryTranslation = entry.meanings.first.translationZhTw;
    }

    final newItem = FavoriteWord(
      id: Uuid().v4(),
      word: entry.word,
      normalizedWord: normalized,
      query: entry.query,
      phonetic: entry.phonetics.ipaUS ?? entry.phonetics.ipaUK,
      primaryPartOfSpeech: primaryPOS,
      primaryTranslationZhTw: primaryTranslation,
      savedEntry: entry,
      savedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final updated = [...state, newItem];
    state = updated;
    await _repository.saveFavorites(updated);

    // Sync ReviewItem
    try {
      final reviewRepo = _ref.read(reviewRepositoryProvider);
      final reviewItems = await reviewRepo.loadReviewItems();
      final existingIndex = reviewItems.indexWhere((item) => item.normalizedWord == normalized);
      if (existingIndex != -1) {
        reviewItems[existingIndex] = reviewItems[existingIndex].copyWith(
          reviewEnabled: true,
          favoriteWordId: newItem.id,
        );
      } else {
        reviewItems.add(ReviewItem(
          id: const Uuid().v4(),
          favoriteWordId: newItem.id,
          normalizedWord: normalized,
          reviewEnabled: true,
          learningStatus: 'new',
          nextReviewAt: DateTime.now().toIso8601String(),
        ));
      }
      await reviewRepo.saveReviewItems(reviewItems);
    } catch (e) {
      print('Error syncing review item on addFavorite: $e');
    }
  }

  Future<void> removeFavorite(String normalizedWord) async {
    final normalized = normalizedWord.trim().toLowerCase();
    final updated = state.where((item) => item.normalizedWord != normalized).toList();
    state = updated;
    await _repository.saveFavorites(updated);

    // Sync ReviewItem
    try {
      final reviewRepo = _ref.read(reviewRepositoryProvider);
      final reviewItems = await reviewRepo.loadReviewItems();
      reviewItems.removeWhere((item) => item.normalizedWord == normalized);
      await reviewRepo.saveReviewItems(reviewItems);
    } catch (e) {
      print('Error syncing review item on removeFavorite: $e');
    }
  }

  Future<void> toggleComparisonWordFavorite(ComparisonWord compWord, String query) async {
    final normalized = compWord.normalizedWord.trim().toLowerCase();
    final isAlreadyFav = state.any((item) => item.normalizedWord == normalized);
    
    if (isAlreadyFav) {
      await removeFavorite(normalized);
    } else {
      // Map ComparisonWord to DictionaryEntry wrapper for saving
      final mockEntry = DictionaryEntry(
        query: query,
        detectedInputLanguage: 'en',
        word: compWord.word,
        normalizedWord: normalized,
        alternatives: [],
        syllables: [],
        phonetics: Phonetics(ipaUS: compWord.phonetic),
        meanings: [
          DictionaryMeaning(
            partOfSpeech: compWord.partOfSpeech ?? 'vocabulary',
            definitionEn: compWord.definitionEn ?? '',
            translationZhTw: compWord.translationZhTw,
            examples: [
              DictionaryExample(
                english: compWord.example.english,
                traditionalChinese: compWord.example.traditionalChinese,
              )
            ],
          )
        ],
        synonyms: [],
        antonyms: [],
        wordFamily: [],
        collocations: compWord.commonCollocations,
        phrases: [],
        confusingWords: [],
        comparison: '',
        similarWords: [],
        comparisonInfo: null,
        usageNotes: compWord.interchangeabilityNote != null ? [compWord.interchangeabilityNote!] : [],
        commonMistakes: [],
        warnings: [],
        generatedAt: DateTime.now().toIso8601String(),
        provider: 'gemini',
        model: 'gemini-2.5-flash',
      );
      
      await addFavorite(mockEntry);
    }
  }

  Future<void> clearAll() async {
    state = [];
    await _repository.saveFavorites([]);

    // Sync ReviewItems
    try {
      final reviewRepo = _ref.read(reviewRepositoryProvider);
      await reviewRepo.saveReviewItems([]);
    } catch (e) {
      print('Error clearing review items: $e');
    }
  }
}

// Global list notifier
final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, List<FavoriteWord>>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repository, ref);
});

// Separate StateNotifier for filtering/sorting state to keep list updates fast
class FavoritesFilterNotifier extends StateNotifier<FavoritesState> {
  final Ref _ref;

  FavoritesFilterNotifier(this._ref) : super(FavoritesState(items: [])) {
    // Re-sync with the base favorites list provider
    _ref.listen<List<FavoriteWord>>(favoritesNotifierProvider, (prev, next) {
      state = state.copyWith(items: next);
    }, fireImmediately: true);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }
}

final favoritesFilterProvider =
    StateNotifierProvider<FavoritesFilterNotifier, FavoritesState>((ref) {
  return FavoritesFilterNotifier(ref);
});
