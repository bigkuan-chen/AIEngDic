import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dictionary_notifier.dart';
import 'smart_review_notifier.dart';
import '../domain/dictionary_model.dart';
import '../../favorites/presentation/favorites_notifier.dart';
import '../../../core/tts/tts_service.dart';

class DictionaryScreen extends ConsumerStatefulWidget {
  final String? autoQuery;
  const DictionaryScreen({super.key, this.autoQuery});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: '設定',
      onPressed: () => context.push('/settings'),
    );
  }
}

class _FavoritesListButton extends StatelessWidget {
  const _FavoritesListButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.list_alt_outlined),
      tooltip: '我的單字清單',
      onPressed: () => context.push('/favorites'),
    );
  }
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoQuery != null && widget.autoQuery!.isNotEmpty) {
        _searchController.text = widget.autoQuery!;
        ref.read(dictionaryNotifierProvider.notifier).lookupWord(widget.autoQuery!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DictionaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoQuery != oldWidget.autoQuery && widget.autoQuery != null && widget.autoQuery!.isNotEmpty) {
      _searchController.text = widget.autoQuery!;
      ref.read(dictionaryNotifierProvider.notifier).lookupWord(widget.autoQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmit() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(dictionaryNotifierProvider.notifier).lookupWord(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dictionaryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI WordPilot'),
        actions: const [
          _SettingsButton(),
          _FavoritesListButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Input Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearchSubmit(),
                    decoration: InputDecoration(
                      hintText: '輸入英文或中文',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (text) {
                      // Trigger rebuild to update suffixIcon state
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: state.isLoading ? null : _onSearchSubmit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  ),
                  child: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
          
          // Dictionary Content view
          Expanded(
            child: _buildResultArea(state),
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea(DictionaryState state) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在查詢...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onSearchSubmit,
              icon: const Icon(Icons.refresh),
              label: const Text('重新查詢'),
            ),
          ],
        ),
      );
    }

    if (state.entry == null) {
      // Empty/Idle State
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '開始查詢英文單字',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '請輸入英文或中文內容。',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Success State
    return _buildDictionaryResult(state.entry!, state.isFavorited);
  }

  Widget _buildDictionaryResult(DictionaryEntry entry, bool isFavorited) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 單字、音標、發音、收藏
          Card(
            margin: const EdgeInsets.only(bottom: 16, top: 8),
            elevation: 0,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.word,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      // Favorite Icon Button
                      IconButton(
                        icon: Icon(
                          isFavorited ? Icons.star : Icons.star_border,
                          color: isFavorited ? Colors.amber : Colors.grey,
                          size: 32,
                        ),
                        onPressed: () {
                          ref.read(dictionaryNotifierProvider.notifier).toggleFavorite();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFavorited ? '已從我的單字移出' : '已加入我的單字'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  // IPA Section
                  if (entry.phonetics.ipaUS != null || entry.phonetics.ipaUK != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (entry.phonetics.ipaUS != null)
                          _buildIPABadge('美音', entry.phonetics.ipaUS!, entry.word),
                        if (entry.phonetics.ipaUK != null)
                          _buildIPABadge('英音', entry.phonetics.ipaUK!, entry.word),
                      ],
                    ),
                  ],

                  // Pronunciation approximate text for Chinese speakers
                  if (entry.phonetics.pronunciationText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '諧音：${entry.phonetics.pronunciationText}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],

                  // Syllables, CEFR and Frequency Row
                  if (entry.syllables.isNotEmpty || entry.cefrLevel != null || entry.frequency != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (entry.syllables.isNotEmpty)
                          _buildMetadataBadge('音節：${entry.syllables.join(' • ')}'),
                        if (entry.cefrLevel != null)
                          _buildMetadataBadge('CEFR：${entry.cefrLevel!.toUpperCase()}', color: const Color(0xFF10B981)),
                        if (entry.frequency != null)
                          _buildMetadataBadge(_getFrequencyLabel(entry.frequency!), color: Colors.blue),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),

          // 2. 中文意思與英文解釋
          _buildSectionHeader('中文意思與英文解釋'),
          _buildDefinitionsSummaryCard(entry),

          // 3. 詞性與例句
          _buildSectionHeader('詞性與例句'),
          ...entry.meanings.map((meaning) => _buildPartOfSpeechAndExamplesCard(meaning)),
          if (_hasWordForms(entry.wordForms)) ...[
            _buildSectionHeader('單字變化形'),
            _buildWordFormsCard(entry.wordForms!),
          ],

          // 4. 常見搭配
          if (entry.collocations.isNotEmpty) ...[
            _buildSectionHeader('常見搭配'),
            ...entry.collocations.map((coll) => _buildCollocationCard(coll)),
          ],
          if (entry.phrases.isNotEmpty) ...[
            _buildSectionHeader('常見片語與俗語'),
            ...entry.phrases.map((phrase) => _buildPhraseCard(phrase)),
          ],

          // 5. 相似單字
          if (entry.similarWords.isNotEmpty) ...[
            _buildSimilarWordsSection(entry),
          ] else if (entry.synonyms.isNotEmpty || entry.antonyms.isNotEmpty) ...[
            _buildSectionHeader('相似單字'),
            _buildSynonymsAntonymsCard(entry.synonyms, entry.antonyms),
          ],

          // 6. 容易混淆
          if (entry.confusingWords.isNotEmpty) ...[
            _buildSectionHeader('容易混淆'),
            ...entry.confusingWords.map((conf) => _buildConfusingCard(conf)),
          ],

          // 7. 比較這些單字
          if (entry.comparison.isNotEmpty || entry.alternatives.isNotEmpty) ...[
            _buildSectionHeader('比較這些單字'),
            if (entry.comparison.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.compare_arrows, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text('相似/混淆單字辨析', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatSummary(entry.comparison),
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            if (entry.alternatives.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entry.alternatives.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, idx) {
                    final alt = entry.alternatives[idx];
                    return ListTile(
                      title: Text(alt.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('翻譯：${alt.translationZhTw}', style: const TextStyle(fontSize: 13)),
                          Text('用法差異：${alt.difference}', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
                          if (alt.example != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('例：${alt.example}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],

          // Usage Notes and Warnings
          if (entry.usageNotes.isNotEmpty) ...[
            _buildSectionHeader('用法備忘錄'),
            _buildBulletPointsCard(entry.usageNotes),
          ],
          if (entry.commonMistakes.isNotEmpty) ...[
            _buildSectionHeader('常見錯誤與警告'),
            _buildBulletPointsCard(entry.commonMistakes, color: Colors.orange.shade800, icon: Icons.warning_amber),
          ],

          // 8. 加入智慧複習
          _buildSectionHeader('加入智慧複習'),
          _buildSmartReviewCard(entry),

          // Metadata and Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'AI 產生內容 • 服務由 ${entry.provider.toUpperCase()} (${entry.model}) 提供',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildIPABadge(String type, String ipa, String word) {
    final tts = ref.read(ttsServiceProvider);
    return InkWell(
      onTap: () {
        if (type == '美音') {
          tts.speakUS(word);
        } else {
          tts.speakUK(word);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              ipa,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.volume_up,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataBadge(String text, {Color? color}) {
    final activeColor = color ?? Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: activeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: activeColor,
        ),
      ),
    );
  }

  String _getFrequencyLabel(String freq) {
    switch (freq) {
      case 'very_common':
        return '詞頻：極常用';
      case 'common':
        return '詞頻：常用';
      case 'less_common':
        return '詞頻：中等常用';
      case 'rare':
        return '詞頻：罕見';
      default:
        return '詞頻：未知';
    }
  }

  Widget _buildDefinitionsSummaryCard(DictionaryEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entry.meanings.map((meaning) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          meaning.partOfSpeech.toLowerCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          meaning.translationZhTw,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (meaning.definitionEn.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 38.0),
                      child: Text(
                        meaning.definitionEn,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPartOfSpeechAndExamplesCard(DictionaryMeaning meaning) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    meaning.partOfSpeech.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (meaning.transitivity != null) ...[
                  const SizedBox(width: 8),
                  _buildMetadataBadge(meaning.transitivity == 'transitive'
                      ? '及物'
                      : meaning.transitivity == 'intransitive'
                          ? '不及物'
                          : '及物/不及物'),
                ],
                if (meaning.countability != null) ...[
                  const SizedBox(width: 8),
                  _buildMetadataBadge(meaning.countability == 'countable'
                      ? '可數'
                      : meaning.countability == 'uncountable'
                          ? '不可數'
                          : '可數/不可數'),
                ],
                if (meaning.register != null && meaning.register != 'neutral') ...[
                  const SizedBox(width: 8),
                  _buildMetadataBadge('語體：${meaning.register}'),
                ]
              ],
            ),
            if (meaning.usageContext != null) ...[
              const SizedBox(height: 8),
              Text(
                '使用語境：${meaning.usageContext}',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
            if (meaning.examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                '例句',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...meaning.examples.map((ex) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.english,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ex.traditionalChinese,
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmartReviewCard(DictionaryEntry entry) {
    // Read the smart review notifier state
    final smartReviewState = ref.watch(smartReviewNotifierProvider);
    final isAdded = smartReviewState.contains(entry.word.trim().toLowerCase());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: isAdded 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
      child: InkWell(
        onTap: () {
          ref.read(smartReviewNotifierProvider.notifier).toggleWord(entry.word);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAdded ? '已移出智慧複習清單' : '已加入智慧複習清單，將為您安排複習時程！'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            children: [
              Icon(
                isAdded ? Icons.psychology : Icons.psychology_outlined,
                color: isAdded ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdded ? '已加入智慧複習' : '加入智慧複習',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAdded ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAdded ? '系統將會定時安排該單字的記憶複習' : '使用間隔重複算法 (SRS) 來輔助記憶此單字',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isAdded ? Icons.check_circle : Icons.add_circle_outline,
                color: isAdded ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasWordForms(WordForms? forms) {
    if (forms == null) return false;
    return forms.base != null ||
        forms.thirdPersonSingular != null ||
        forms.presentParticiple != null ||
        forms.past != null ||
        forms.pastParticiple != null ||
        forms.plural != null ||
        forms.comparative != null ||
        forms.superlative != null;
  }

  Widget _buildWordFormsCard(WordForms forms) {
    final Map<String, String> formsMap = {
      if (forms.base != null) '原型 (Base)': forms.base!,
      if (forms.thirdPersonSingular != null) '第三人稱單數': forms.thirdPersonSingular!,
      if (forms.presentParticiple != null) '現在分詞': forms.presentParticiple!,
      if (forms.past != null) '過去式 (Past)': forms.past!,
      if (forms.pastParticiple != null) '過去分詞': forms.pastParticiple!,
      if (forms.plural != null) '複數形式': forms.plural!,
      if (forms.comparative != null) '比較級': forms.comparative!,
      if (forms.superlative != null) '最高級': forms.superlative!,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          children: formsMap.entries.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${e.key}：', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline)),
                Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSynonymsAntonymsCard(List<String> synonyms, List<String> antonyms) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (synonyms.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('同義字：', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: synonyms.map((s) => GestureDetector(
                        onTap: () {
                          _searchController.text = s;
                          ref.read(dictionaryNotifierProvider.notifier).lookupWord(s);
                        },
                        child: Text(s, style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            if (synonyms.isNotEmpty && antonyms.isNotEmpty) const SizedBox(height: 12),
            if (antonyms.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('反義字：', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: antonyms.map((a) => GestureDetector(
                        onTap: () {
                          _searchController.text = a;
                          ref.read(dictionaryNotifierProvider.notifier).lookupWord(a);
                        },
                        child: Text(a, style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                      )).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollocationCard(Collocation coll) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(coll.phrase, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('釋義：${coll.translationZhTw}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(coll.exampleEn, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(coll.exampleZhTw, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhraseCard(Phrase phrase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(phrase.phrase, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
            const SizedBox(height: 4),
            Text('釋義：${phrase.translationZhTw}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(phrase.definitionEn, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phrase.exampleEn, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  Text(phrase.exampleZhTw, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfusingCard(ConfusingWord conf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text('對比字：${conf.word}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 6),
            Text('用法差異：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.outline)),
            Text(conf.differenceZhTw, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text('例句：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.outline)),
            Text(conf.exampleEn, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(conf.exampleZhTw, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPointsCard(List<String> points, {Color? color, IconData icon = Icons.info_outline}) {
    final activeColor = color ?? Theme.of(context).colorScheme.onBackground;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: activeColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(fontSize: 13, height: 1.4, color: activeColor),
                      ),
                    ),
                  ],
                ),
              )).toList(),
        ),
      ),
    );
  }

  Widget _buildSimilarWordsSection(DictionaryEntry entry) {
    if (entry.similarWords.isEmpty) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dynamic_feed_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '相似單字',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '這些單字意思相近，但使用情境可能不同。',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.similarWords.map((sim) {
                return ActionChip(
                  avatar: const Icon(Icons.info_outline, size: 14),
                  label: Text('${sim.word} ${sim.shortTranslationZhTw}'),
                  onPressed: () {
                    _showSimilarWordPreviewBottomSheet(sim, entry.query);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (entry.comparisonInfo != null) {
                    _showWordComparisonModal(entry.comparisonInfo!, entry.query);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('無比較資料！請確保使用的是最新的 AI 模型查詢結果。')),
                    );
                  }
                },
                icon: const Icon(Icons.compare_arrows),
                label: const Text('比較單字'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSimilarWordPreviewBottomSheet(SimilarWord sim, String query) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final favorites = ref.watch(favoritesNotifierProvider);
            final isFav = favorites.any((item) => item.normalizedWord == sim.normalizedWord.trim().toLowerCase());
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sim.word,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.star : Icons.star_border,
                          color: isFav ? Colors.amber : Colors.grey,
                          size: 28,
                        ),
                        onPressed: () async {
                          final compWord = ComparisonWord(
                            word: sim.word,
                            normalizedWord: sim.normalizedWord,
                            phonetic: sim.phonetic,
                            partOfSpeech: sim.partOfSpeech,
                            translationZhTw: sim.shortTranslationZhTw,
                            keyDifference: sim.keyDifference,
                            usageContext: '相似字快速收藏',
                            commonCollocations: [],
                            example: DictionaryExample(english: '', traditionalChinese: ''),
                          );
                          
                          await ref.read(favoritesNotifierProvider.notifier)
                              .toggleComparisonWordFavorite(compWord, query);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFav ? '${sim.word} 已從我的單字移出' : '${sim.word} 已加入我的單字'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (sim.phonetic != null || sim.partOfSpeech != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (sim.partOfSpeech != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              sim.partOfSpeech!.toLowerCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        if (sim.phonetic != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            sim.phonetic!,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    '核心差異',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sim.keyDifference,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('關閉'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _searchController.text = sim.word;
                            ref.read(dictionaryNotifierProvider.notifier).lookupWord(sim.word);
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('完整查詢'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showWordComparisonModal(WordComparison comparison, String query) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final favorites = ref.watch(favoritesNotifierProvider);
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  comparison.title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '比較意思、使用情境與常見搭配',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: comparison.words.map((w) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(w.word),
                                    selected: w.isPrimaryWord,
                                    onSelected: (_) {},
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.secondary),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '快速理解',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatSummary(comparison.quickSummary),
                                    style: const TextStyle(fontSize: 14, height: 1.5),
                                  ),
                                  if (comparison.interchangeabilitySummary != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '互換提醒：${comparison.interchangeabilitySummary!}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.outline,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...comparison.words.map((w) {
                            final isFav = favorites.any((item) => item.normalizedWord == w.normalizedWord.trim().toLowerCase());
                            return _buildComparisonWordCard(w, isFav, query);
                          }).toList(),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              '比較內容由 AI 產生，可能需要交叉確認。',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                );
              }
            );
          },
        );
      },
    );
  }

  Widget _buildComparisonWordCard(ComparisonWord w, bool isFav, String query) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        w.word,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: w.isPrimaryWord ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (w.isPrimaryWord) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '主要查詢',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: isFav ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () async {
                    await ref.read(favoritesNotifierProvider.notifier)
                        .toggleComparisonWordFavorite(w, query);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFav ? '${w.word} 已從我的單字移除' : '${w.word} 已加入我的單字'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (w.phonetic != null || w.partOfSpeech != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (w.partOfSpeech != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        w.partOfSpeech!.toLowerCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (w.phonetic != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      w.phonetic!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ],
                  if (w.formality != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '語體：${w.formality}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildComparisonCardField('核心差異', w.keyDifference),
            const SizedBox(height: 10),
            _buildComparisonCardField('適用情境', w.usageContext),
            const SizedBox(height: 10),
            if (w.commonCollocations.isNotEmpty) ...[
              const Text(
                '常見搭配',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: w.commonCollocations.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${c.phrase} ${c.translationZhTw}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
            if (w.example.english.isNotEmpty) ...[
              const Text(
                '例句比較',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.example.english,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      w.example.traditionalChinese,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (w.interchangeabilityNote != null) ...[
              _buildComparisonCardField('互換提醒', w.interchangeabilityNote!),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(favoritesNotifierProvider.notifier)
                      .toggleComparisonWordFavorite(w, query);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFav ? '${w.word} 已從我的單字移除' : '${w.word} 已加入我的單字'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: Icon(isFav ? Icons.bookmark_added : Icons.bookmark_add_outlined),
                label: Text(isFav ? '已加入我的單字' : '加入我的單字'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCardField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  String _formatSummary(String summary) {
    if (summary.contains('\n')) {
      return summary.trim();
    }
    return summary
        .replaceAll('；\n', '\n')
        .replaceAll('；', '\n')
        .replaceAll(';\n', '\n')
        .replaceAll(';', '\n')
        .trim();
  }
}
