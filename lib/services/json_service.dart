import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/target_ibadah_model.dart';

/// Service untuk mengelola data statis (assets) dan dinamis (SharedPreferences)
/// - Data statis: prayer times, surah, categories, dll (dari assets/data/)
/// - Data dinamis: progress, achievements unlock, streak (dari SharedPreferences)
class JsonService {
  // ========================================
  // PRIVATE HELPER - LOAD JSON FILE
  // ========================================
  static Future<Map<String, dynamic>> _loadJsonFile(String path) async {
    try {
      final String response = await rootBundle.loadString(path);
      return json.decode(response);
    } catch (e) {
      print('Error loading JSON from $path: $e');
      return {};
    }
  }

  // ========================================
  // PRAYER TIMES (Static Data)
  // ========================================
  static Future<Map<String, dynamic>> loadPrayerTimes() async {
    return await _loadJsonFile('assets/data/prayer_times.json');
  }

  static Future<Map<String, String>> getPrayerTimesMap() async {
    final data = await loadPrayerTimes();
    final times = data['times'] as Map<String, dynamic>?;
    
    if (times == null) return {};
    
    return times.map((key, value) => MapEntry(key, value.toString()));
  }

  static Future<Map<String, String>> getNextPrayerInfo() async {
    final data = await loadPrayerTimes();
    final nextPrayer = data['nextPrayer'] as Map<String, dynamic>?;
    
    if (nextPrayer == null) return {};
    
    return {
      'name': nextPrayer['name']?.toString() ?? '',
      'time': nextPrayer['time']?.toString() ?? '',
      'countdown': nextPrayer['countdown']?.toString() ?? '',
    };
  }

  // ========================================
  // SURAH LIST (Static Data)
  // ========================================
  static Future<Map<String, dynamic>> loadSurahList() async {
    return await _loadJsonFile('assets/data/surah_list.json');
  }

  static Future<List<Map<String, dynamic>>> getSurahList() async {
    final data = await loadSurahList();
    final surahList = data['surah'] as List<dynamic>?;
    
    if (surahList == null) return [];
    
    return surahList.map((surah) => surah as Map<String, dynamic>).toList();
  }

  static Future<Map<String, String>> getReadingTips() async {
    final data = await loadSurahList();
    final tips = data['readingTips'] as Map<String, dynamic>?;
    
    if (tips == null) return {};
    
    return {
      'title': tips['title']?.toString() ?? '',
      'description': tips['description']?.toString() ?? '',
    };
  }

  // ========================================
  // ACHIEVEMENTS (Dynamic Data)
  // ========================================
  static Future<List<Map<String, dynamic>>> getAchievementsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('achievements');
      
      if (jsonString != null) {
        final List<dynamic> data = json.decode(jsonString);
        return data.cast<Map<String, dynamic>>();
      }
      
      return _getDefaultAchievements();
    } catch (e) {
      print('Error loading achievements: $e');
      return _getDefaultAchievements();
    }
  }

  static List<Map<String, dynamic>> _getDefaultAchievements() {
    return [
      {
        'title': 'Pemula',
        'description': 'Selesaikan target pertama',
        'icon': 'emoji_events',
        'color': '#FFC107',
        'unlocked': false,
        'unlockedDate': null,
      },
      {
        'title': 'Konsisten',
        'description': 'Streak 7 hari berturut-turut',
        'icon': 'local_fire_department',
        'color': '#FF5722',
        'unlocked': false,
        'unlockedDate': null,
      },
      {
        'title': 'Rajin Sholat',
        'description': 'Sholat 5 waktu selama 30 hari',
        'icon': 'mosque',
        'color': '#7E57C2',
        'unlocked': false,
        'unlockedDate': null,
      },
      {
        'title': 'Pembaca Al-Quran',
        'description': 'Baca Al-Quran 50 kali',
        'icon': 'menu_book',
        'color': '#4CAF50',
        'unlocked': false,
        'unlockedDate': null,
      },
      {
        'title': 'Dermawan',
        'description': 'Sedekah 20 kali',
        'icon': 'favorite',
        'color': '#2196F3',
        'unlocked': false,
        'unlockedDate': null,
      },
    ];
  }

  static Future<Map<String, int>> getPointsSystem() async {
    // Points system bisa dibuat static atau dynamic
    // Untuk saat ini kita return static data
    return {
      'sholatFardhu': 10,
      'sholatSunnah': 5,
      'bacaQuran': 15,
      'dzikir': 5,
      'sedekah': 20,
      'puasa': 25,
    };
  }

  // ========================================
  // CATEGORIES (Static Data)
  // ========================================
  static Future<Map<String, dynamic>> loadCategories() async {
    return await _loadJsonFile('assets/data/categories.json');
  }

  static Future<List<Map<String, dynamic>>> getCategoriesList() async {
    final data = await loadCategories();
    final categories = data['categories'] as List<dynamic>?;
    
    if (categories == null) return [];
    
    return categories.map((cat) => cat as Map<String, dynamic>).toList();
  }

  static Future<List<String>> getCategoryNames() async {
    final categories = await getCategoriesList();
    return categories.map((cat) => cat['name'].toString()).toList();
  }

  // ========================================
  // DUMMY TARGETS (Static Data)
  // ========================================
  static Future<Map<String, dynamic>> loadDummyTargets() async {
    return await _loadJsonFile('assets/data/dummy_targets.json');
  }

  static Future<List<TargetIbadah>> getTargetsList() async {
    final data = await loadDummyTargets();
    final targets = data['targets'] as List<dynamic>?;
    
    if (targets == null) return [];
    
    return targets.map((target) {
      return TargetIbadah.fromJson(target as Map<String, dynamic>);
    }).toList();
  }

  static Future<List<TargetIbadah>> getTodayTargets() async {
    final allTargets = await getTargetsList();
    final today = DateTime.now();
    
    return allTargets.where((target) {
      return target.targetDate.year == today.year &&
          target.targetDate.month == today.month &&
          target.targetDate.day == today.day;
    }).toList();
  }

  // ========================================
  // DZIKIR LIST (Static Data)
  // ========================================
  static Future<Map<String, dynamic>> loadDzikirList() async {
    return await _loadJsonFile('assets/data/dzikir_list.json');
  }

  static Future<List<Map<String, dynamic>>> getDzikirList() async {
    final data = await loadDzikirList();
    final dzikirList = data['dzikirList'] as List<dynamic>?;
    
    if (dzikirList == null) return [];
    
    return dzikirList.map((dzikir) => dzikir as Map<String, dynamic>).toList();
  }

  static Future<List<String>> getDzikirNames() async {
    final dzikirList = await getDzikirList();
    return dzikirList.map((dzikir) => dzikir['name'].toString()).toList();
  }

  static Future<Map<String, String>> getDzikirBenefits() async {
    final data = await loadDzikirList();
    final benefits = data['benefits'] as Map<String, dynamic>?;
    
    if (benefits == null) return {};
    
    return {
      'title': benefits['title']?.toString() ?? '',
      'description': benefits['description']?.toString() ?? '',
    };
  }

  // ========================================
  // SEDEKAH HISTORY (Static Data)
  // ========================================
  static Future<Map<String, dynamic>> loadSedekahHistory() async {
    return await _loadJsonFile('assets/data/sedekah_history.json');
  }

  static Future<List<Map<String, dynamic>>> getSedekahHistory() async {
    final data = await loadSedekahHistory();
    final history = data['history'] as List<dynamic>?;
    
    if (history == null) return [];
    
    return history.map((item) => item as Map<String, dynamic>).toList();
  }

  static Future<List<String>> getSedekahCategories() async {
    final data = await loadSedekahHistory();
    final categories = data['categories'] as List<dynamic>?;
    
    if (categories == null) return [];
    
    return categories.map((cat) => cat.toString()).toList();
  }

  static Future<Map<String, dynamic>> getSedekahTips() async {
    final data = await loadSedekahHistory();
    return data['tips'] as Map<String, dynamic>? ?? {};
  }

  static Future<int> getTotalSedekah() async {
    final history = await getSedekahHistory();
    return history.fold<int>(0, (int sum, Map<String, dynamic> item) => 
      sum + (item['jumlah'] as int));
  }

  // ========================================
  // DAILY PROGRESS (Dynamic Data)
  // ========================================
  static Future<List<Map<String, dynamic>>> getDailyProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('daily_progress');
      
      if (jsonString != null) {
        final List<dynamic> data = json.decode(jsonString);
        return data.cast<Map<String, dynamic>>();
      }
      
      return _getDefaultDailyProgress();
    } catch (e) {
      print('Error loading daily progress: $e');
      return _getDefaultDailyProgress();
    }
  }

  static List<Map<String, dynamic>> _getDefaultDailyProgress() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> defaultProgress = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      
      defaultProgress.add({
        'day': dayName,
        'date': '${date.day}/${date.month}',
        'completed': 0,
        'total': 7,
        'percentage': 0,
      });
    }
    
    return defaultProgress;
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Sen';
      case 2: return 'Sel';
      case 3: return 'Rab';
      case 4: return 'Kam';
      case 5: return 'Jum';
      case 6: return 'Sab';
      case 7: return 'Min';
      default: return '';
    }
  }

  // ========================================
  // CATEGORY STATISTICS (Dynamic Data)
  // ========================================
  static Future<List<Map<String, dynamic>>> getCategoryStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('category_stats');
      
      if (jsonString != null) {
        final List<dynamic> data = json.decode(jsonString);
        return data.cast<Map<String, dynamic>>();
      }
      
      return _getDefaultCategoryStats();
    } catch (e) {
      print('Error loading category stats: $e');
      return _getDefaultCategoryStats();
    }
  }

  static List<Map<String, dynamic>> _getDefaultCategoryStats() {
    return [
      {
        'name': 'Sholat 5 Waktu',
        'icon': 'mosque',
        'color': '#7E57C2',
        'completed': 0,
        'total': 5,
        'percentage': 0,
      },
      {
        'name': 'Baca Al-Quran',
        'icon': 'menu_book',
        'color': '#4CAF50',
        'completed': 0,
        'total': 1,
        'percentage': 0,
      },
      {
        'name': 'Dzikir',
        'icon': 'favorite',
        'color': '#FF9800',
        'completed': 0,
        'total': 1,
        'percentage': 0,
      },
      {
        'name': 'Sedekah',
        'icon': 'favorite_border',
        'color': '#2196F3',
        'completed': 0,
        'total': 1,
        'percentage': 0,
      },
    ];
  }

  // ========================================
  // STREAK INFO (Dynamic Data)
  // ========================================
  static Future<Map<String, dynamic>> getStreakInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int currentStreak = prefs.getInt('current_streak') ?? 0;
      final int longestStreak = prefs.getInt('longest_streak') ?? 0;
      
      return {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActivityDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error loading streak info: $e');
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'lastActivityDate': DateTime.now().toIso8601String(),
      };
    }
  }

  // ========================================
  // MOTIVATIONAL MESSAGE
  // ========================================
  static Future<String> getMotivationalMessage() async {
    final messages = [
      'Konsistensi adalah kunci kesuksesan dalam beribadah!',
      'Setiap langkah kecil adalah progress yang berarti.',
      'Allah mencintai amalan yang konsisten walau sedikit.',
      'Jangan pernah menyerah, terus tingkatkan ibadahmu!',
      'Hari ini adalah kesempatan baru untuk lebih baik.',
      'Ingat, setiap ibadah akan dicatat sebagai kebaikan.',
      'Jadikan ibadah sebagai kebiasaan, bukan beban.',
      'Sholat adalah tiang agama, jaga sholat 5 waktumu!',
    ];
    
    final now = DateTime.now();
    final index = now.day % messages.length;
    
    return messages[index];
  }

  // ========================================
  // WEEKLY AVERAGE
  // ========================================
  static Future<double> getWeeklyAverage() async {
    final dailyProgress = await getDailyProgress();
    
    if (dailyProgress.isEmpty) return 0.0;
    
    int totalPercentage = dailyProgress.fold(
      0, 
      (sum, item) => sum + (item['percentage'] as int)
    );
    
    return totalPercentage / dailyProgress.length;
  }

  // ========================================
  // SAVE METHODS (Dynamic Data)
  // ========================================
  static Future<void> saveDailyProgress(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(data);
    await prefs.setString('daily_progress', jsonString);
  }

  static Future<void> saveCategoryStats(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(data);
    await prefs.setString('category_stats', jsonString);
  }

  static Future<void> saveAchievements(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(data);
    await prefs.setString('achievements', jsonString);
  }

  static Future<void> updateStreak(int currentStreak, int longestStreak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_streak', currentStreak);
    await prefs.setInt('longest_streak', longestStreak);
  }

  // ========================================
  // UPDATE PROGRESS ON TARGET COMPLETE
  // ========================================
  static Future<void> updateProgressOnTargetComplete(String category) async {
    // Update category stats
    final stats = await getCategoryStats();
    final categoryIndex = stats.indexWhere((s) => s['name'] == category);
    
    if (categoryIndex != -1) {
      stats[categoryIndex]['completed'] = 
          (stats[categoryIndex]['completed'] as int) + 1;
      stats[categoryIndex]['percentage'] = 
          ((stats[categoryIndex]['completed'] as int) * 100) ~/ 
          (stats[categoryIndex]['total'] as int);
      
      await saveCategoryStats(stats);
    }

    // Update daily progress
    final dailyProgress = await getDailyProgress();
    if (dailyProgress.isNotEmpty) {
      final today = dailyProgress.last;
      today['completed'] = (today['completed'] as int) + 1;
      today['percentage'] = 
          ((today['completed'] as int) * 100) ~/ (today['total'] as int);
      
      await saveDailyProgress(dailyProgress);
    }
    
    // Update streak
    await _updateStreak();
  }
  
  // ========================================
  // UPDATE STREAK (dipanggil otomatis)
  // ========================================
  static Future<void> _updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get last activity date
      final lastActivityString = prefs.getString('last_activity_date');
      DateTime? lastActivity;
      
      if (lastActivityString != null) {
        lastActivity = DateTime.parse(lastActivityString);
        lastActivity = DateTime(
          lastActivity.year, 
          lastActivity.month, 
          lastActivity.day
        );
      }
      
      int currentStreak = prefs.getInt('current_streak') ?? 0;
      int longestStreak = prefs.getInt('longest_streak') ?? 0;
      
      // Check if activity today
      if (lastActivity == null || lastActivity.isBefore(today)) {
        // First activity today
        if (lastActivity == null) {
          // First ever activity
          currentStreak = 1;
        } else {
          final daysDiff = today.difference(lastActivity).inDays;
          
          if (daysDiff == 1) {
            // Consecutive day - increase streak
            currentStreak++;
          } else {
            // Streak broken - reset to 1
            currentStreak = 1;
          }
        }
        
        // Update longest streak if current is higher
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
        
        // Save updated values
        await prefs.setInt('current_streak', currentStreak);
        await prefs.setInt('longest_streak', longestStreak);
        await prefs.setString('last_activity_date', now.toIso8601String());
        
        print('✅ Streak updated: $currentStreak days (longest: $longestStreak)');
      }
    } catch (e) {
      print('❌ Error updating streak: $e');
    }
  }

  // ========================================
  // PRELOAD ALL DATA
  // ========================================
  static Future<void> preloadAllData() async {
    try {
      await Future.wait([
        loadPrayerTimes(),
        loadSurahList(),
        loadCategories(),
        loadDummyTargets(),
        loadDzikirList(),
        loadSedekahHistory(),
      ]);
      print('✅ All JSON data preloaded successfully');
    } catch (e) {
      print('❌ Error preloading data: $e');
    }
  }
}