import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

/// Handles local authentication and current session persistence.
class AuthService {
  final DatabaseHelper _db;
  final SharedPreferences _prefs;

  AuthService(this._db, this._prefs);

  /// Validates credentials against the local SQLite database.
  /// Returns the [User] on success, or throws an [Exception] on failure.
  Future<User?> login(String username, String password) async {
    final user = await _db.getUserByUsername(username.trim());
    if (user == null) {
      throw Exception('User not found');
    }
    if (user.password != password) {
      throw Exception('Incorrect password');
    }
    if (!user.isActive) {
      throw Exception('Account is inactive. Contact your teacher.');
    }

    await _prefs.setInt(AppConstants.prefsSessionUserId, user.id!);
    await _prefs.setString(AppConstants.prefsSessionRole, user.role);
    return user;
  }

  /// Clears the current session.
  Future<void> logout() async {
    await _prefs.remove(AppConstants.prefsSessionUserId);
    await _prefs.remove(AppConstants.prefsSessionRole);
  }

  /// Checks whether there is a persisted session.
  bool get isLoggedIn => _prefs.containsKey(AppConstants.prefsSessionUserId);

  /// Returns the currently logged-in user, or null.
  Future<User?> getCurrentUser() async {
    final id = _prefs.getInt(AppConstants.prefsSessionUserId);
    if (id == null) return null;
    return _db.getUserById(id);
  }

  /// Returns the current user's role, or null.
  String? get currentRole => _prefs.getString(AppConstants.prefsSessionRole);

  /// Throws if the active session is not a teacher.
  Future<void> requireTeacher() async {
    final role = currentRole;
    if (role != AppConstants.roleTeacher) {
      throw Exception('Teacher access required');
    }
  }

  /// Throws if the active session is not a student.
  Future<void> requireStudent() async {
    final role = currentRole;
    if (role != AppConstants.roleStudent) {
      throw Exception('Student access required');
    }
  }
}
