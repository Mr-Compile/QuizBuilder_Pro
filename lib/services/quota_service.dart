import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

/// Service that manages and enforces daily AI generation quotas.
/// 
/// This service provides secure quota enforcement at the service layer,
/// preventing users from bypassing limits through UI modifications.
/// All AI generation requests must pass through this service's validation.
class QuotaService {
  final DatabaseHelper _db;
  final SharedPreferences _prefs;

  QuotaService(this._db, this._prefs);

  /// Returns the daily quota limit for a given role.
  int getDailyLimit(String role) {
    switch (role) {
      case AppConstants.roleTeacher:
        return AppConstants.teacherDailyQuota;
      case AppConstants.roleStudent:
        return AppConstants.studentDailyQuota;
      default:
        return 0;
    }
  }

  /// Gets the current date string in YYYY-MM-DD format for quota tracking.
  String _getCurrentDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Checks if the quota reset needs to be performed and resets if necessary.
  /// This ensures quotas reset automatically at midnight.
  Future<void> _checkAndResetQuotaIfNeeded() async {
    final lastResetDate = _prefs.getString(AppConstants.prefsLastQuotaResetDate);
    final currentDate = _getCurrentDateKey();

    if (lastResetDate != currentDate) {
      // New day - reset all quotas
      await _resetAllQuotas();
      await _prefs.setString(AppConstants.prefsLastQuotaResetDate, currentDate);
    }
  }

  /// Resets all daily quotas by clearing the ai_generations table.
  Future<void> _resetAllQuotas() async {
    final db = await _db.database;
    await db.delete('ai_generations');
  }

  /// Gets the number of AI generations used by a user today.
  Future<int> getTodayUsage(int userId) async {
    await _checkAndResetQuotaIfNeeded();

    final db = await _db.database;
    final currentDate = _getCurrentDateKey();
    
    final results = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM ai_generations
      WHERE created_by = ? 
      AND generated_at LIKE ?
    ''', [userId, '$currentDate%']);

    return (results.first['count'] as int?) ?? 0;
  }

  /// Gets the remaining quota for a user today.
  Future<int> getRemainingQuota(User user) async {
    final dailyLimit = getDailyLimit(user.role);
    final used = await getTodayUsage(user.id!);
    final remaining = dailyLimit - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Checks if a user can perform an AI generation request.
  /// 
  /// Throws an exception if the user has exceeded their daily quota.
  /// This is the primary enforcement point - all generation requests must call this.
  Future<void> checkQuotaAndThrowIfExceeded(User user) async {
    await _checkAndResetQuotaIfNeeded();

    final dailyLimit = getDailyLimit(user.role);
    if (dailyLimit == 0) {
      throw QuotaExceededException(
        'AI generation is not available for ${user.role}s.',
        remaining: 0,
        limit: 0,
      );
    }

    final remaining = await getRemainingQuota(user);
    if (remaining <= 0) {
      throw QuotaExceededException(
        'Daily AI generation limit reached. You have used your quota of $dailyLimit generations for today.',
        remaining: 0,
        limit: dailyLimit,
      );
    }
  }

  /// Records an AI generation request for quota tracking.
  /// 
  /// This should be called after a successful AI generation.
  /// [userId] - The user who made the request
  /// [topicId] - The topic for which questions were generated
  /// [difficulty] - The difficulty level of the generated questions
  /// [count] - The number of questions generated
  Future<void> recordGeneration({
    required int userId,
    required int topicId,
    required String difficulty,
    required int count,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    await db.insert('ai_generations', {
      'created_by': userId,
      'topic_id': topicId,
      'difficulty': difficulty,
      'count': count,
      'generated_at': now,
    });
  }

  /// Gets quota information for display in the UI.
  /// Returns a map with 'used', 'limit', and 'remaining' counts.
  Future<Map<String, int>> getQuotaInfo(User user) async {
    await _checkAndResetQuotaIfNeeded();

    final used = await getTodayUsage(user.id!);
    final limit = getDailyLimit(user.role);
    final remaining = limit - used;

    return {
      'used': used,
      'limit': limit,
      'remaining': remaining < 0 ? 0 : remaining,
    };
  }

  /// Manually resets quotas (for testing or admin purposes).
  Future<void> manualReset() async {
    await _resetAllQuotas();
    await _prefs.setString(AppConstants.prefsLastQuotaResetDate, _getCurrentDateKey());
  }
}

/// Exception thrown when a user exceeds their daily quota.
class QuotaExceededException implements Exception {
  final String message;
  final int remaining;
  final int limit;

  QuotaExceededException(this.message, {required this.remaining, required this.limit});

  @override
  String toString() => message;
}
