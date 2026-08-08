import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'auth_service.dart';
import 'backup_service.dart';
import 'export_service.dart';
import 'file_processing_service.dart';
import 'groq_ai_service.dart';
import 'quota_service.dart';
import 'quiz_session_service.dart';
import 'secure_storage_service.dart';

/// Simple service locator that keeps one instance of each core service.
class ServiceLocator {
  ServiceLocator._();

  static DatabaseHelper? _db;
  static SharedPreferences? _prefs;
  static AuthService? _auth;
  static GroqAiService? _groq;
  static SecureStorageService? _secure;
  static QuizSessionService? _quizSession;
  static ExportService? _export;
  static FileProcessingService? _fileProcessing;
  static BackupService? _backup;
  static QuotaService? _quota;

  static DatabaseHelper get db {
    _db ??= DatabaseHelper();
    return _db!;
  }

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<AuthService> get auth async {
    final p = await prefs;
    _auth ??= AuthService(db, p);
    return _auth!;
  }

  static Future<SecureStorageService> get secure async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(),
    );
    _secure ??= const SecureStorageService(secureStorage);
    return _secure!;
  }

  static Future<GroqAiService> get groq async {
    final s = await secure;
    final q = await quota;
    _groq ??= GroqAiService(s, db, q);
    return _groq!;
  }

  static Future<QuizSessionService> get quizSession async {
    final p = await prefs;
    _quizSession ??= QuizSessionService(p);
    return _quizSession!;
  }

  static ExportService get export {
    _export ??= ExportService(db);
    return _export!;
  }

  static FileProcessingService get fileProcessing {
    _fileProcessing ??= FileProcessingService();
    return _fileProcessing!;
  }

  static BackupService get backup {
    _backup ??= BackupService(db);
    return _backup!;
  }

  static Future<QuotaService> get quota async {
    final p = await prefs;
    _quota ??= QuotaService(db, p);
    return _quota!;
  }
}
