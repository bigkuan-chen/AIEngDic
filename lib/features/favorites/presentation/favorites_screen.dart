import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'favorites_notifier.dart';
import '../../dictionary/presentation/dictionary_notifier.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(favoritesFilterProvider);
    final sortedItems = filterState.filteredAndSortedItems;
    final notifier = ref.read(favoritesNotifierProvider.notifier);
    final filterNotifier = ref.read(favoritesFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的單字'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Sort Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_outlined),
            tooltip: '排序',
            initialValue: filterState.sortBy,
            onSelected: (val) => filterNotifier.updateSortBy(val),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'savedAt_desc', child: Text('新至舊')),
              PopupMenuItem(value: 'savedAt_asc', child: Text('舊至新')),
              PopupMenuItem(value: 'word_asc', child: Text('A 到 Z')),
              PopupMenuItem(value: 'word_desc', child: Text('Z 到 A')),
            ],
          ),
          // Clear all button
          if (filterState.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              tooltip: '清除全部',
              onPressed: () => _showClearAllConfirmation(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Local Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋我的單字...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            filterNotifier.updateSearchQuery('');
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (text) {
                setState(() {});
                filterNotifier.updateSearchQuery(text);
              },
            ),
          ),
          
          // Favorites List
          Expanded(
            child: sortedItems.isEmpty
                ? _buildEmptyState(filterState.searchQuery.isNotEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: sortedItems.length,
                    itemBuilder: (context, idx) {
                      final item = sortedItems[idx];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          notifier.removeFavorite(item.normalizedWord);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已刪除 ${item.word}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            title: Row(
                              children: [
                                Text(
                                  item.word,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                if (item.phonetic != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    item.phonetic!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.outline,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  if (item.primaryPartOfSpeech != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.primaryPartOfSpeech!.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (item.primaryTranslationZhTw != null)
                                    Expanded(
                                      child: Text(
                                        item.primaryTranslationZhTw!,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () {
                                notifier.removeFavorite(item.normalizedWord);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已刪除 ${item.word}'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              // 1. Set cached entry to show offline
                              ref.read(dictionaryNotifierProvider.notifier).showCachedEntry(item.savedEntry);
                              // 2. Go back to dictionary screen (or go to root)
                              context.go('/dictionary');
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: filterState.items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/review/setup'),
              icon: const Icon(Icons.school_outlined),
              label: const Text('開始智慧複習'),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.star_border,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? '找不到相符的單字' : '尚未收藏單字',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching ? '請嘗試其他關鍵字。' : '在查詢結果點選星星，即可加入清單。',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除全部收藏'),
        content: const Text('確定要清除所有收藏的單字嗎？此動作將無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              ref.read(favoritesNotifierProvider.notifier).clearAll();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清除所有收藏')),
              );
            },
            child: const Text('清除全部'),
          ),
        ],
      ),
    );
  }
}
