import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/review_model.dart';

class ReviewRepository {
  Future<File> _getReviewItemsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/review_items.json');
  }

  Future<File> _getBackupReviewItemsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/review_items.json.bak');
  }

  Future<File> _getTempReviewItemsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/review_items.json.tmp');
  }

  Future<File> _getSessionsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/review_sessions.json');
  }

  Future<File> _getBackupSessionsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/review_sessions.json.bak');
  }

  Future<File> _getTempSessionsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/review_sessions.json.tmp');
  }

  Future<File> _getAnswersFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/review_answers.json');
  }

  Future<File> _getBackupAnswersFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/review_answers.json.bak');
  }

  Future<File> _getTempAnswersFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/review_answers.json.tmp');
  }

  // --- Review Items ---
  Future<List<ReviewItem>> loadReviewItems() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final content = prefs.getString('web_review_items_json');
        if (content == null || content.trim().isEmpty) return [];
        final decoded = jsonDecode(content);
        if (decoded is! Map) return [];
        final rawList = decoded['items'] as List?;
        if (rawList == null) return [];
        return rawList.map((e) => ReviewItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (e) {
        print('Error loading web review items: $e');
        return [];
      }
    }

    try {
      final file = await _getReviewItemsFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString(encoding: utf8);
      if (content.trim().isEmpty) return [];
      final decoded = jsonDecode(content);
      if (decoded is! Map) return [];
      final rawList = decoded['items'] as List?;
      if (rawList == null) return [];
      return rawList.map((e) => ReviewItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      print('Error loading mobile review items: $e');
      await _backupCorruptedReviewItemsFile();
      return [];
    }
  }

  Future<void> saveReviewItems(List<ReviewItem> items) async {
    final data = {
      'schemaVersion': '1.0',
      'updatedAt': DateTime.now().toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
    final jsonString = jsonEncode(data);

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_review_items_json', jsonString);
      return;
    }

    final file = await _getReviewItemsFile();
    final tempFile = await _getTempReviewItemsFile();

    await tempFile.writeAsString(jsonString, encoding: utf8, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  Future<void> _backupCorruptedReviewItemsFile() async {
    if (kIsWeb) return;
    try {
      final file = await _getReviewItemsFile();
      final backupFile = await _getBackupReviewItemsFile();
      if (await file.exists()) {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        await file.rename(backupFile.path);
      }
      await saveReviewItems([]);
    } catch (_) {}
  }

  // --- Review Sessions ---
  Future<List<ReviewSession>> loadSessions() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final content = prefs.getString('web_review_sessions_json');
        if (content == null || content.trim().isEmpty) return [];
        final decoded = jsonDecode(content);
        if (decoded is! Map) return [];
        final rawList = decoded['sessions'] as List?;
        if (rawList == null) return [];
        return rawList.map((e) => ReviewSession.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (e) {
        print('Error loading web sessions: $e');
        return [];
      }
    }

    try {
      final file = await _getSessionsFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString(encoding: utf8);
      if (content.trim().isEmpty) return [];
      final decoded = jsonDecode(content);
      if (decoded is! Map) return [];
      final rawList = decoded['sessions'] as List?;
      if (rawList == null) return [];
      return rawList.map((e) => ReviewSession.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      print('Error loading mobile sessions: $e');
      await _backupCorruptedSessionsFile();
      return [];
    }
  }

  Future<void> saveSessions(List<ReviewSession> sessions) async {
    // Keep only recent sessions to avoid bloated JSON files
    // Limit to 20 sessions for MVP
    final sublist = sessions.length > 20 ? sessions.sublist(sessions.length - 20) : sessions;
    final data = {
      'schemaVersion': '1.0',
      'sessions': sublist.map((e) => e.toJson()).toList(),
    };
    final jsonString = jsonEncode(data);

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_review_sessions_json', jsonString);
      return;
    }

    final file = await _getSessionsFile();
    final tempFile = await _getTempSessionsFile();

    await tempFile.writeAsString(jsonString, encoding: utf8, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  Future<void> _backupCorruptedSessionsFile() async {
    if (kIsWeb) return;
    try {
      final file = await _getSessionsFile();
      final backupFile = await _getBackupSessionsFile();
      if (await file.exists()) {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        await file.rename(backupFile.path);
      }
      await saveSessions([]);
    } catch (_) {}
  }

  // --- Review Answers ---
  Future<List<ReviewAnswer>> loadAnswers() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final content = prefs.getString('web_review_answers_json');
        if (content == null || content.trim().isEmpty) return [];
        final decoded = jsonDecode(content);
        if (decoded is! Map) return [];
        final rawList = decoded['answers'] as List?;
        if (rawList == null) return [];
        return rawList.map((e) => ReviewAnswer.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (e) {
        print('Error loading web answers: $e');
        return [];
      }
    }

    try {
      final file = await _getAnswersFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString(encoding: utf8);
      if (content.trim().isEmpty) return [];
      final decoded = jsonDecode(content);
      if (decoded is! Map) return [];
      final rawList = decoded['answers'] as List?;
      if (rawList == null) return [];
      return rawList.map((e) => ReviewAnswer.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      print('Error loading mobile answers: $e');
      await _backupCorruptedAnswersFile();
      return [];
    }
  }

  Future<void> saveAnswers(List<ReviewAnswer> answers) async {
    // Limit retention: keep only recent 1000 answers
    final sublist = answers.length > 1000 ? answers.sublist(answers.length - 1000) : answers;
    final data = {
      'schemaVersion': '1.0',
      'answers': sublist.map((e) => e.toJson()).toList(),
    };
    final jsonString = jsonEncode(data);

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_review_answers_json', jsonString);
      return;
    }

    final file = await _getAnswersFile();
    final tempFile = await _getTempAnswersFile();

    await tempFile.writeAsString(jsonString, encoding: utf8, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  Future<void> _backupCorruptedAnswersFile() async {
    if (kIsWeb) return;
    try {
      final file = await _getAnswersFile();
      final backupFile = await _getBackupAnswersFile();
      if (await file.exists()) {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        await file.rename(backupFile.path);
      }
      await saveAnswers([]);
    } catch (_) {}
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});
