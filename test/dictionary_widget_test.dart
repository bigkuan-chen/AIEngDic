import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_eng_dic/features/dictionary/presentation/dictionary_screen.dart';
import 'package:ai_eng_dic/features/dictionary/presentation/dictionary_notifier.dart';
import 'package:ai_eng_dic/features/dictionary/domain/dictionary_model.dart';
import 'package:ai_eng_dic/features/favorites/presentation/favorites_notifier.dart';
import 'package:ai_eng_dic/features/favorites/domain/favorites_model.dart';
import 'package:ai_eng_dic/features/settings/presentation/settings_notifier.dart';
import 'package:ai_eng_dic/features/settings/domain/settings_model.dart';
import 'package:ai_eng_dic/core/tts/tts_service.dart';
import 'package:ai_eng_dic/features/dictionary/presentation/smart_review_notifier.dart';

// MOCKS
class MockTTSService extends TTSService {
  @override
  Future<void> speakUS(String text) async {}
  @override
  Future<void> speakUK(String text) async {}
  @override
  Future<void> stop() async {}
}

class MockSettingsNotifier extends StateNotifier<SettingsState> implements SettingsNotifier {
  MockSettingsNotifier() : super(SettingsState(settings: AppSettings.defaultSettings()));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSmartReviewNotifier extends StateNotifier<Set<String>> implements SmartReviewNotifier {
  MockSmartReviewNotifier() : super({});
  @override
  Future<void> toggleWord(String word) async {
    final normalized = word.trim().toLowerCase();
    if (state.contains(normalized)) {
      state = state.where((w) => w != normalized).toSet();
    } else {
      state = {...state, normalized};
    }
  }
  @override
  bool isAdded(String word) {
    return state.contains(word.trim().toLowerCase());
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFavoritesNotifier extends StateNotifier<List<FavoriteWord>> implements FavoritesNotifier {
  MockFavoritesNotifier([List<FavoriteWord>? initial]) : super(initial ?? []);

  @override
  Future<void> toggleComparisonWordFavorite(ComparisonWord w, String query) async {
    final cleanWord = w.normalizedWord.trim().toLowerCase();
    final index = state.indexWhere((item) => item.normalizedWord == cleanWord);
    if (index != -1) {
      state = state.where((item) => item.normalizedWord != cleanWord).toList();
    } else {
      final mockFav = FavoriteWord(
        id: 'mock-id-${w.word}',
        word: w.word,
        normalizedWord: cleanWord,
        query: query,
        phonetic: w.phonetic,
        primaryPartOfSpeech: w.partOfSpeech,
        primaryTranslationZhTw: w.translationZhTw,
        savedEntry: DictionaryEntry(
          query: query,
          detectedInputLanguage: 'en',
          word: w.word,
          normalizedWord: cleanWord,
          alternatives: [],
          syllables: [],
          phonetics: Phonetics(ipaUS: w.phonetic),
          cefrLevel: null,
          frequency: null,
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
          generatedAt: '2026-06-20T00:00:00Z',
          provider: 'gemini',
          model: 'gemini-2.5-flash',
        ),
        savedAt: '2026-06-20T00:00:00Z',
        updatedAt: '2026-06-20T00:00:00Z',
      );
      state = [...state, mockFav];
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDictionaryNotifier extends StateNotifier<DictionaryState> implements DictionaryNotifier {
  MockDictionaryNotifier(DictionaryState state) : super(state);

  @override
  Future<void> lookupWord(String word) async {}

  @override
  Future<void> toggleFavorite() async {
    state = state.copyWith(isFavorited: !state.isFavorited);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final mockEntryWithSimilarWords = DictionaryEntry(
    query: 'accomplish',
    detectedInputLanguage: 'en',
    word: 'accomplish',
    normalizedWord: 'accomplish',
    alternatives: [],
    syllables: ['ac', 'com', 'plish'],
    phonetics: Phonetics(ipaUS: '/əˈkʌmplɪʃ/', ipaUK: '/əˈkʌmplɪʃ/', pronunciationText: '俄康普利什'),
    cefrLevel: 'b2',
    frequency: 'common',
    meanings: [
      DictionaryMeaning(
        partOfSpeech: 'verb',
        definitionEn: 'To succeed in doing something.',
        translationZhTw: '完成',
        examples: [
          DictionaryExample(english: 'We accomplished the task.', traditionalChinese: '我們完成了任務。'),
        ],
      )
    ],
    synonyms: [],
    antonyms: [],
    wordFamily: [],
    collocations: [
      Collocation(phrase: 'accomplish a goal', translationZhTw: '達成目標', exampleEn: 'He accomplished his goal.', exampleZhTw: '他達成了他的目標。')
    ],
    phrases: [],
    confusingWords: [
      ConfusingWord(word: 'achieve', differenceZhTw: 'achieve 強調成就，accomplish 強調完成任務。', exampleEn: 'He achieved success.', exampleZhTw: '他取得了成功。')
    ],
    similarWords: [
      SimilarWord(
        word: 'achieve',
        normalizedWord: 'achieve',
        phonetic: '/əˈtʃiːv/',
        partOfSpeech: 'verb',
        shortTranslationZhTw: '達成目標',
        keyDifference: '強調取得成果或達到目標',
        relationshipType: 'near_synonym',
      ),
      SimilarWord(
        word: 'complete',
        normalizedWord: 'complete',
        phonetic: '/kəmˈpliːt/',
        partOfSpeech: 'verb',
        shortTranslationZhTw: '完整做完',
        keyDifference: '強調所有部分都已完成',
        relationshipType: 'near_synonym',
      ),
    ],
    comparisonInfo: WordComparison(
      title: 'accomplish、achieve 與 complete 比較',
      quickSummary: 'accomplish 強調完成任務；achieve 強調達到目標；complete 強調全部做完。',
      interchangeabilitySummary: '部分語境可互換。',
      words: [
        ComparisonWord(
          word: 'accomplish',
          normalizedWord: 'accomplish',
          phonetic: '/əˈkʌmplɪʃ/',
          partOfSpeech: 'verb',
          translationZhTw: '完成',
          definitionEn: 'To succeed in doing something.',
          keyDifference: '強調完成一項具體且需要努力的任務',
          usageContext: '任務、工作',
          formality: 'neutral',
          commonCollocations: [
            Collocation(phrase: 'accomplish a task', translationZhTw: '完成任務', exampleEn: 'example', exampleZhTw: 'example')
          ],
          example: DictionaryExample(english: 'We accomplished the project.', traditionalChinese: '我們完成了這個專案。'),
          interchangeabilityNote: '強調任務的完成。',
          isPrimaryWord: true,
        ),
        ComparisonWord(
          word: 'achieve',
          normalizedWord: 'achieve',
          phonetic: '/əˈtʃiːv/',
          partOfSpeech: 'verb',
          translationZhTw: '達成',
          definitionEn: 'To successfully reach a goal.',
          keyDifference: '強調達成目標或取得成果',
          usageContext: '目標、成就',
          formality: 'neutral',
          commonCollocations: [
            Collocation(phrase: 'achieve a goal', translationZhTw: '達成目標', exampleEn: 'example', exampleZhTw: 'example')
          ],
          example: DictionaryExample(english: 'She achieved her dream.', traditionalChinese: '她實現了她的夢想。'),
          interchangeabilityNote: '與目標有關。',
          isPrimaryWord: false,
        ),
      ],
    ),
    comparison: 'accomplish 強調完成任務；achieve 強調達到目標；complete 強調全部做完。',
    usageNotes: ['常用於工作/任務的完成'],
    commonMistakes: ['注意拼寫'],
    warnings: [],
    generatedAt: '2026-06-20T00:00:00Z',
    provider: 'gemini',
    model: 'gemini-2.5-flash',
  );

  final mockEntryNoSimilarWords = DictionaryEntry(
    query: 'apple',
    detectedInputLanguage: 'en',
    word: 'apple',
    normalizedWord: 'apple',
    alternatives: [],
    syllables: ['ap', 'ple'],
    phonetics: Phonetics(ipaUS: '/ˈæp.əl/', ipaUK: '/ˈæp.əl/', pronunciationText: '阿婆'),
    cefrLevel: 'a1',
    frequency: 'very_common',
    meanings: [
      DictionaryMeaning(
        partOfSpeech: 'noun',
        definitionEn: 'A round fruit.',
        translationZhTw: '蘋果',
        examples: [],
      )
    ],
    synonyms: [],
    antonyms: [],
    wordFamily: [],
    collocations: [],
    phrases: [],
    confusingWords: [],
    similarWords: [],
    comparisonInfo: null,
    comparison: '',
    usageNotes: [],
    commonMistakes: [],
    warnings: [],
    generatedAt: '2026-06-20T00:00:00Z',
    provider: 'gemini',
    model: 'gemini-2.5-flash',
  );

  Widget createTestWidget({
    required DictionaryState dictState,
    required List<FavoriteWord> favList,
  }) {
    return ProviderScope(
      overrides: [
        dictionaryNotifierProvider.overrideWith((ref) => MockDictionaryNotifier(dictState)),
        favoritesNotifierProvider.overrideWith((ref) => MockFavoritesNotifier(favList)),
        settingsNotifierProvider.overrideWith((ref) => MockSettingsNotifier()),
        smartReviewNotifierProvider.overrideWith((ref) => MockSmartReviewNotifier()),
        ttsServiceProvider.overrideWith((ref) => MockTTSService()),
      ],
      child: const MaterialApp(
        home: DictionaryScreen(),
      ),
    );
  }

  group('Dictionary Widget tests - Similar Words & Comparison', () {
    testWidgets('Should display similar words section and chips when similarWords is present', (tester) async {
      await tester.pumpWidget(createTestWidget(
        dictState: DictionaryState(entry: mockEntryWithSimilarWords, isLoading: false),
        favList: [],
      ));

      // Verify "相似單字" text is found
      expect(find.text('相似單字'), findsWidgets);

      // Verify the similar words chips are present
      expect(find.text('achieve 達成目標'), findsOneWidget);
      expect(find.text('complete 完整做完'), findsOneWidget);

      // Verify "比較單字" button is visible
      expect(find.text('比較單字'), findsOneWidget);
    });

    testWidgets('Should hide or disable similar words section when similarWords is empty', (tester) async {
      await tester.pumpWidget(createTestWidget(
        dictState: DictionaryState(entry: mockEntryNoSimilarWords, isLoading: false),
        favList: [],
      ));

      // Chips should not be visible
      expect(find.text('achieve 達成目標'), findsNothing);
      expect(find.text('complete 完整做完'), findsNothing);
      
      // "比較單字" button should not be found
      expect(find.text('比較單字'), findsNothing);
    });

    testWidgets('Should open Similar Word Preview bottom sheet when similar word chip is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        dictState: DictionaryState(entry: mockEntryWithSimilarWords, isLoading: false),
        favList: [],
      ));

      // Tap on "achieve 達成目標" chip
      await tester.tap(find.text('achieve 達成目標'));
      await tester.pumpAndSettle(); // Wait for bottom sheet animation to complete

      // Verify bottom sheet title is achieve
      expect(find.text('achieve'), findsOneWidget);
      
      // Verify key difference detail is shown
      expect(find.text('核心差異'), findsOneWidget);
      expect(find.text('強調取得成果或達到目標'), findsOneWidget);

      // Verify preview actions are shown
      expect(find.text('關閉'), findsOneWidget);
      expect(find.text('完整查詢'), findsOneWidget);
    });

    testWidgets('Should open Comparison Modal dialog when compare button is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        dictState: DictionaryState(entry: mockEntryWithSimilarWords, isLoading: false),
        favList: [],
      ));

      // Tap on "比較單字" button
      await tester.tap(find.text('比較單字'));
      await tester.pumpAndSettle();

      // Verify Comparison Title and Subtitle are shown
      expect(find.text('accomplish、achieve 與 complete 比較'), findsOneWidget);
      expect(find.text('比較意思、使用情境與常見搭配'), findsOneWidget);

      // Verify Quick summary section card is shown
      expect(find.text('快速理解'), findsOneWidget);
      expect(find.text('accomplish 強調完成任務\nachieve 強調達到目標\ncomplete 強調全部做完。'), findsWidgets);

      // Verify Comparison cards exist
      expect(find.text('核心差異'), findsWidgets);
      expect(find.text('適用情境'), findsWidgets);
      expect(find.text('例句比較'), findsWidgets);
    });

    testWidgets('Should toggle favorite state on a comparison card and synchronize with local storage', (tester) async {
      tester.view.physicalSize = const Size(800, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        dictState: DictionaryState(entry: mockEntryWithSimilarWords, isLoading: false),
        favList: [], // Initial favorite list is empty
      ));

      // Open comparison sheet
      await tester.tap(find.text('比較單字'));
      await tester.pumpAndSettle();

      // Locate the favorite bookmark button on the "achieve" card
      // In the layout, this is an OutlinedButton with text "加入我的單字" or "已加入我的單字"
      expect(find.text('加入我的單字'), findsWidgets);
      
      // Tap on "加入我的單字" button (we will tap the first one that is visible, e.g. for achieve or accomplish)
      final joinButtonFinder = find.text('加入我的單字');
      await tester.tap(joinButtonFinder.first);
      await tester.pumpAndSettle();

      // Verify that the UI updates (the text should change or the notifier state is triggered)
      // Since it's a mock provider, the state inside MockFavoritesNotifier should add the word, 
      // which triggers a rebuild and updates the list to contain the favorited word.
      expect(find.text('已加入我的單字'), findsWidgets);
    });
  });
}
