import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../database/database_helper.dart';

/// Backup data structure containing all app data
class BackupData {
  final String version;
  final DateTime createdAt;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> topics;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> quizResults;
  final List<Map<String, dynamic>> quizAnswers;
  final List<Map<String, dynamic>> aiGenerations;

  BackupData({
    required this.version,
    required this.createdAt,
    required this.users,
    required this.topics,
    required this.questions,
    required this.quizResults,
    required this.quizAnswers,
    required this.aiGenerations,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'users': users,
      'topics': topics,
      'questions': questions,
      'quiz_results': quizResults,
      'quiz_answers': quizAnswers,
      'ai_generations': aiGenerations,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      users: (json['users'] as List).cast<Map<String, dynamic>>(),
      topics: (json['topics'] as List).cast<Map<String, dynamic>>(),
      questions: (json['questions'] as List).cast<Map<String, dynamic>>(),
      quizResults: (json['quiz_results'] as List).cast<Map<String, dynamic>>(),
      quizAnswers: (json['quiz_answers'] as List).cast<Map<String, dynamic>>(),
      aiGenerations: (json['ai_generations'] as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get summary statistics for preview
  BackupSummary getSummary() {
    return BackupSummary(
      userCount: users.length,
      topicCount: topics.length,
      questionCount: questions.length,
      quizResultCount: quizResults.length,
      quizAnswerCount: quizAnswers.length,
      aiGenerationCount: aiGenerations.length,
      createdAt: createdAt,
      version: version,
    );
  }
}

/// Backup summary for preview
class BackupSummary {
  final int userCount;
  final int topicCount;
  final int questionCount;
  final int quizResultCount;
  final int quizAnswerCount;
  final int aiGenerationCount;
  final DateTime createdAt;
  final String version;

  BackupSummary({
    required this.userCount,
    required this.topicCount,
    required this.questionCount,
    required this.quizResultCount,
    required this.quizAnswerCount,
    required this.aiGenerationCount,
    required this.createdAt,
    required this.version,
  });
}

/// Service for backup and restore operations
class BackupService {
  final DatabaseHelper _db;
  static const String _currentVersion = '1.0.0';

  BackupService(this._db);

  /// Export all data to a backup file
  /// Returns the path where the backup was saved
  Future<String> exportBackup(String? customFolderName) async {
    try {
      // Get all data from database
      final users = await _db.getAllUsers();
      final topics = await _db.getAllTopics();
      final questions = await _db.getAllQuestions();
      final quizResults = await _db.getAllQuizResults();
      final quizAnswers = await _db.getAllQuizAnswers();
      final aiGenerations = await _db.getAllAiGenerations();

      // Convert to maps
      final usersMaps = users.map((u) => u.toMap()).toList();
      final topicsMaps = topics.map((t) => t.toMap()).toList();
      final questionsMaps = questions.map((q) => q.toMap()).toList();
      final quizResultsMaps = quizResults.map((qr) => qr.toMap()).toList();
      final quizAnswersMaps = quizAnswers.map((qa) => qa.toMap()).toList();
      final aiGenerationsMaps = aiGenerations.map((ag) => ag).toList();

      // Create backup data
      final backupData = BackupData(
        version: _currentVersion,
        createdAt: DateTime.now(),
        users: usersMaps,
        topics: topicsMaps,
        questions: questionsMaps,
        quizResults: quizResultsMaps,
        quizAnswers: quizAnswersMaps,
        aiGenerations: aiGenerationsMaps,
      );

      // Convert to JSON
      final jsonString = jsonEncode(backupData.toJson());

      // Get directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}${Platform.pathSeparator}QuizBuilder_Backups');
      
      // Create custom folder if specified
      String finalPath = backupDir.path;
      if (customFolderName != null && customFolderName.trim().isNotEmpty) {
        final customDir = Directory('${backupDir.path}${Platform.pathSeparator}${customFolderName.trim()}');
        await customDir.create(recursive: true);
        finalPath = customDir.path;
      } else {
        await backupDir.create(recursive: true);
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'quizbuilder_backup_$timestamp.json';
      final filePath = '$finalPath${Platform.pathSeparator}$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  /// Import backup from a file
  /// Returns the backup data for preview
  Future<BackupData> importBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return BackupData.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  /// Select a backup file using file picker
  Future<String?> selectBackupFile() async {
    try {
      final result = await file_picker.FilePicker.pickFiles(
        type: file_picker.FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select QuizBuilder Backup File',
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to select backup file: $e');
    }
  }

  /// Restore data from backup
  /// This will replace all existing data
  Future<void> restoreBackup(BackupData backupData) async {
    try {
      final db = await _db.database;

      // Begin transaction
      await db.transaction((txn) async {
        // Clear existing data in correct order (respecting foreign keys)
        await txn.delete('quiz_answers');
        await txn.delete('quiz_results');
        await txn.delete('ai_generations');
        await txn.delete('questions');
        await txn.delete('topics');
        await txn.delete('users');

        // Restore users (preserve IDs)
        for (final userMap in backupData.users) {
          await txn.insert('users', userMap);
        }

        // Restore topics (preserve IDs)
        for (final topicMap in backupData.topics) {
          await txn.insert('topics', topicMap);
        }

        // Restore questions (preserve IDs)
        for (final questionMap in backupData.questions) {
          await txn.insert('questions', questionMap);
        }

        // Restore quiz results (preserve IDs)
        for (final quizResultMap in backupData.quizResults) {
          await txn.insert('quiz_results', quizResultMap);
        }

        // Restore quiz answers (preserve IDs)
        for (final quizAnswerMap in backupData.quizAnswers) {
          await txn.insert('quiz_answers', quizAnswerMap);
        }

        // Restore AI generations (preserve IDs)
        for (final aiGenerationMap in backupData.aiGenerations) {
          await txn.insert('ai_generations', aiGenerationMap);
        }
      });
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  /// Validate backup file before restore
  /// Returns true if backup is valid
  Future<bool> validateBackup(BackupData backupData) async {
    try {
      // Check version compatibility
      if (backupData.version != _currentVersion) {
        // Could add version migration logic here
        // For now, we'll allow it but warn the user
      }

      // Validate that required data exists
      if (backupData.users.isEmpty) {
        throw Exception('Backup contains no users');
      }

      // Check that at least one teacher exists
      final hasTeacher = backupData.users.any((u) => u['role'] == 'teacher');
      if (!hasTeacher) {
        throw Exception('Backup must contain at least one teacher account');
      }

      return true;
    } catch (e) {
      throw Exception('Backup validation failed: $e');
    }
  }
}