import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/data/settings_repository.dart';

class SmartReviewNotifier extends StateNotifier<Set<String>> {
  final SettingsRepository _repository;

  SmartReviewNotifier(this._repository) : super({}) {
    _load();
  }

  void _load() {
    state = _repository.loadSmartReviewWords().toSet();
  }

  Future<void> toggleWord(String word) async {
    final normalized = word.trim().toLowerCase();
    final newState = Set<String>.from(state);
    if (newState.contains(normalized)) {
      newState.remove(normalized);
    } else {
      newState.add(normalized);
    }
    state = newState;
    await _repository.saveSmartReviewWords(newState.toList());
  }

  bool isAdded(String word) {
    return state.contains(word.trim().toLowerCase());
  }
}

final smartReviewNotifierProvider =
    StateNotifierProvider<SmartReviewNotifier, Set<String>>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SmartReviewNotifier(repo);
});
