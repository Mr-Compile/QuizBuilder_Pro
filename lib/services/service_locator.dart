import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'auth_service.dart';
import 'groq_ai_service.dart';

/// Simple service locator that keeps one instance of each core service.
class ServiceLocator {
  ServiceLocator._();

  static final DatabaseHelper _db = DatabaseHelper();
  static SharedPreferences? _prefs;
  static AuthService? _auth;
  static GroqAiService? _groq;

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

  static Future<GroqAiService> get groq async {
    final p = await prefs;
    _groq ??= GroqAiService(p, _db);
    return _groq!;
  }
}
