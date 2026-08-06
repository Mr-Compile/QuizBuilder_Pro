import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'auth_service.dart';
import 'groq_ai_service.dart';
import 'secure_storage_service.dart';

/// Simple service locator that keeps one instance of each core service.
class ServiceLocator {
  ServiceLocator._();

  static final DatabaseHelper _db = DatabaseHelper();
  static SharedPreferences? _prefs;
  static AuthService? _auth;
  static GroqAiService? _groq;
  static SecureStorageService? _secure;

  static DatabaseHelper get db => _db;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<AuthService> get auth async {
    final p = await prefs;
    _auth ??= AuthService(_db, p);
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
    _groq ??= GroqAiService(s, _db);
    return _groq!;
  }
}
