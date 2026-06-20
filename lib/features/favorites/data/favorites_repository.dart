import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/favorites_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesRepository {
  Future<File> _getFavoritesFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/favorites.json');
  }

  Future<File> _getBackupFavoritesFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/favorites.json.bak');
  }

  Future<File> _getTempFavoritesFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/favorites.json.tmp');
  }

  /// Loads favorite list from local JSON file (or SharedPreferences on Web).
  Future<List<FavoriteWord>> loadFavorites() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final content = prefs.getString('web_favorites_json');
        print('loadFavorites: web_favorites_json content = $content');
        if (content == null || content.trim().isEmpty) {
          return [];
        }

        final decoded = jsonDecode(content);
        if (decoded is! Map) {
          return [];
        }
        final rawList = decoded['favorites'] as List?;
        if (rawList == null) {
          return [];
        }

        final items = rawList.map((e) => FavoriteWord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        print('loadFavorites: successfully parsed ${items.length} items');
        return items;
      } catch (e, stackTrace) {
        print('Error loading web favorites: $e\n$stackTrace');
        return [];
      }
    }

    try {
      final file = await _getFavoritesFile();
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString(encoding: utf8);
      if (content.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        return [];
      }
      final rawList = decoded['favorites'] as List?;
      if (rawList == null) {
        return [];
      }

      return rawList.map((e) => FavoriteWord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e, stackTrace) {
      print('Error loading mobile favorites: $e\n$stackTrace');
      // Handle file corruption: backup corrupted file and initialize a blank one
      await _backupCorruptedFile();
      return [];
    }
  }

  /// Saves favorite list to local JSON file (or SharedPreferences on Web).
  Future<void> saveFavorites(List<FavoriteWord> favorites) async {
    final data = {
      'schemaVersion': '1.0',
      'updatedAt': DateTime.now().toIso8601String(),
      'favorites': favorites.map((e) => e.toJson()).toList(),
    };

    final jsonString = jsonEncode(data);

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      print('saveFavorites: saving to web_favorites_json = $jsonString');
      await prefs.setString('web_favorites_json', jsonString);
      return;
    }

    final file = await _getFavoritesFile();
    final tempFile = await _getTempFavoritesFile();

    // 1. Write content to temp file
    await tempFile.writeAsString(jsonString, encoding: utf8, flush: true);

    // 2. Atomically rename/replace temp file with the official file
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  /// Backs up the corrupted favorites.json file and initializes a blank one.
  Future<void> _backupCorruptedFile() async {
    if (kIsWeb) return; // Corruption handling only applies to physical local files
    
    try {
      final file = await _getFavoritesFile();
      final backupFile = await _getBackupFavoritesFile();

      if (await file.exists()) {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        await file.rename(backupFile.path);
      }

      // Initialize empty favorites file
      await saveFavorites([]);
    } catch (_) {
      // Fail silently during corruption backup to prevent app crashing
    }
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});
