import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola sistem gamifikasi
/// Features:
/// - Poin system
/// - Level progression
/// - Achievement tracking
/// - Streak tracking
/// - Leaderboard
class GamificationService {
  // Keys untuk SharedPreferences
  static const String _userPointsKey = 'user_points';
  static const String _userLevelKey = 'user_level';
  static const String _achievementsKey = 'user_achievements';
  static const String _streakKey = 'user_streak';
  static const String _lastActiveKey = 'last_active_date';

  // Poin values
  static const int pointsPerTarget = 10;
  static const int pointsPerDailyComplete = 50;
  static const int pointsPerStreak7 = 100;
  static const int pointsPerAchievement = 50;

  // Level thresholds
  static const Map<int, int> levelThresholds = {
    1: 0,
    2: 500,
    3: 1500,
    4: 3000,
    5: 5000,
    6: 8000,
    7: 12000,
    8: 17000,
    9: 23000,
    10: 30000,
  };

  /// 🎯 ADD POINTS
  /// Tambah poin untuk user
  static Future<bool> addPoints({
    required String userId,
    required int points,
    String? reason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPoints = await getUserPoints(userId);
      final newPoints = currentPoints + points;

      // Save points
      await prefs.setInt('${_userPointsKey}_$userId', newPoints);

      // Check level up
      await _checkLevelUp(userId, newPoints);

      print('✅ Added $points points to $userId. Total: $newPoints${reason != null ? ' ($reason)' : ''}');
      return true;
    } catch (e) {
      print('❌ Error adding points: $e');
      return false;
    }
  }

  /// 📊 GET USER POINTS
  static Future<int> getUserPoints(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('${_userPointsKey}_$userId') ?? 0;
    } catch (e) {
      print('❌ Error getting points: $e');
      return 0;
    }
  }

  /// 📈 GET USER LEVEL
  static Future<int> getUserLevel(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('${_userLevelKey}_$userId') ?? 1;
    } catch (e) {
      print('❌ Error getting level: $e');
      return 1;
    }
  }

  /// 🎚️ SET USER LEVEL
  static Future<void> setUserLevel(String userId, int level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_userLevelKey}_$userId', level);
      
      // Update juga di user profile SharedPreferences
      await prefs.setInt('userLevel', level);
    } catch (e) {
      print('❌ Error setting level: $e');
    }
  }

  /// ⬆️ CHECK LEVEL UP
  static Future<bool> _checkLevelUp(String userId, int newPoints) async {
    final currentLevel = await getUserLevel(userId);
    
    // Cari level yang sesuai dengan poin saat ini
    int newLevel = currentLevel;
    for (var entry in levelThresholds.entries) {
      if (newPoints >= entry.value) {
        newLevel = entry.key;
      }
    }

    // Jika ada level up
    if (newLevel > currentLevel) {
      await setUserLevel(userId, newLevel);
      print('🎉 LEVEL UP! $userId naik ke level $newLevel');
      return true;
    }

    return false;
  }

  /// 📊 GET LEVEL PROGRESS
  /// Returns progress to next level (0.0 - 1.0)
  static Future<Map<String, dynamic>> getLevelProgress(String userId) async {
    final points = await getUserPoints(userId);
    final currentLevel = await getUserLevel(userId);
    
    final currentThreshold = levelThresholds[currentLevel] ?? 0;
    final nextThreshold = levelThresholds[currentLevel + 1] ?? currentThreshold;
    
    final pointsInLevel = points - currentThreshold;
    final pointsNeeded = nextThreshold - currentThreshold;
    final progress = pointsInLevel / pointsNeeded;

    return {
      'currentLevel': currentLevel,
      'currentPoints': points,
      'pointsInLevel': pointsInLevel,
      'pointsNeeded': pointsNeeded,
      'nextLevelThreshold': nextThreshold,
      'progress': progress.clamp(0.0, 1.0),
    };
  }

  /// 🔥 UPDATE STREAK
  /// Update streak berdasarkan aktivitas hari ini
  static Future<Map<String, int>> updateStreak(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      
      // Get last active date
      final lastActiveStr = prefs.getString('${_lastActiveKey}_$userId');
      
      int currentStreak = prefs.getInt('${_streakKey}_current_$userId') ?? 0;
      int longestStreak = prefs.getInt('${_streakKey}_longest_$userId') ?? 0;

      if (lastActiveStr == null) {
        // First time user
        currentStreak = 1;
      } else {
        final lastActive = DateTime.parse(lastActiveStr);
        final daysDiff = today.difference(lastActive).inDays;

        if (daysDiff == 0) {
          // Same day, no change
        } else if (daysDiff == 1) {
          // Consecutive day, increase streak
          currentStreak++;
          
          // Check for streak milestones (7, 14, 30 days)
          if (currentStreak % 7 == 0) {
            await addPoints(
              userId: userId,
              points: pointsPerStreak7,
              reason: 'Streak $currentStreak hari',
            );
          }
        } else {
          // Streak broken, reset
          currentStreak = 1;
        }
      }

      // Update longest streak
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
        await prefs.setInt('${_streakKey}_longest_$userId', longestStreak);
      }

      // Save current streak and last active
      await prefs.setInt('${_streakKey}_current_$userId', currentStreak);
      await prefs.setString('${_lastActiveKey}_$userId', todayStr);

      print('🔥 Streak updated: $currentStreak days (longest: $longestStreak)');

      return {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };
    } catch (e) {
      print('❌ Error updating streak: $e');
      return {'currentStreak': 0, 'longestStreak': 0};
    }
  }

  /// 🔥 GET STREAK INFO
  static Future<Map<String, int>> getStreakInfo(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentStreak = prefs.getInt('${_streakKey}_current_$userId') ?? 0;
      final longestStreak = prefs.getInt('${_streakKey}_longest_$userId') ?? 0;

      return {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };
    } catch (e) {
      print('❌ Error getting streak: $e');
      return {'currentStreak': 0, 'longestStreak': 0};
    }
  }

  /// 🏆 UNLOCK ACHIEVEMENT
  static Future<bool> unlockAchievement({
    required String userId,
    required String achievementId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString('${_achievementsKey}_$userId');
      
      List<Map<String, dynamic>> achievements = [];
      if (achievementsJson != null) {
        final List<dynamic> decoded = json.decode(achievementsJson);
        achievements = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Check if already unlocked
      final alreadyUnlocked = achievements.any((a) => a['id'] == achievementId);
      if (alreadyUnlocked) {
        print('ℹ️ Achievement already unlocked: $achievementId');
        return false;
      }

      // Add new achievement
      achievements.add({
        'id': achievementId,
        'unlockedDate': DateTime.now().toIso8601String(),
      });

      // Save
      await prefs.setString(
        '${_achievementsKey}_$userId',
        json.encode(achievements),
      );

      // Add points
      await addPoints(
        userId: userId,
        points: pointsPerAchievement,
        reason: 'Achievement: $achievementId',
      );

      print('🏆 Achievement unlocked: $achievementId');
      return true;
    } catch (e) {
      print('❌ Error unlocking achievement: $e');
      return false;
    }
  }

  /// 🏆 GET UNLOCKED ACHIEVEMENTS
  static Future<List<String>> getUnlockedAchievements(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString('${_achievementsKey}_$userId');
      
      if (achievementsJson == null) return [];

      final List<dynamic> decoded = json.decode(achievementsJson);
      return decoded.map((a) => a['id'].toString()).toList();
    } catch (e) {
      print('❌ Error getting achievements: $e');
      return [];
    }
  }

  /// ✅ HANDLE TARGET COMPLETION
  /// Called when user completes a target
  static Future<void> onTargetCompleted({
    required String userId,
    required int completedToday,
    required int totalToday,
  }) async {
    // Add points for target completion
    await addPoints(
      userId: userId,
      points: pointsPerTarget,
      reason: 'Target completed',
    );

    // If all daily targets completed
    if (completedToday == totalToday && totalToday > 0) {
      await addPoints(
        userId: userId,
        points: pointsPerDailyComplete,
        reason: 'All daily targets completed',
      );

      // Check achievements
      await _checkAchievements(userId);
    }

    // Update streak
    await updateStreak(userId);
  }

  /// 🏆 CHECK ACHIEVEMENTS
  /// Check if user qualifies for any achievements
  static Future<void> _checkAchievements(String userId) async {
    final streakInfo = await getStreakInfo(userId);
    final currentStreak = streakInfo['currentStreak'] ?? 0;

    // Streak achievements
    if (currentStreak >= 7) {
      await unlockAchievement(userId: userId, achievementId: 'streak_7');
    }
    if (currentStreak >= 30) {
      await unlockAchievement(userId: userId, achievementId: 'streak_30');
    }
  }

  /// 🗑️ RESET USER GAMIFICATION DATA
  static Future<bool> resetUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_userPointsKey}_$userId');
      await prefs.remove('${_userLevelKey}_$userId');
      await prefs.remove('${_achievementsKey}_$userId');
      await prefs.remove('${_streakKey}_current_$userId');
      await prefs.remove('${_streakKey}_longest_$userId');
      await prefs.remove('${_lastActiveKey}_$userId');
      
      print('✅ User gamification data reset');
      return true;
    } catch (e) {
      print('❌ Error resetting data: $e');
      return false;
    }
  }
}