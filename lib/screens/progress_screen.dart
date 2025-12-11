import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/json_service.dart';
import '../widgets/bottom_navigation.dart';
import '../services/firebase/firebase_target_service.dart'; // ✅ TAMBAH
import '../utils/app_localizations.dart';

/// PROGRESS SCREEN dengan Data Real dari Firebase & Dark Mode Support
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final int selectedNavIndex = 1;
  int currentLevel = 1;
  int totalPoints = 0;
  int pointsForNextLevel = 500;
  bool isLoading = true;

  List<Map<String, dynamic>> dailyProgress = [];
  List<Map<String, dynamic>> categoryStats = [];
  List<Map<String, dynamic>> achievements = [];
  Map<String, dynamic> streakInfo = {};
  String motivationalMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserStats();
    _loadJsonData();
  }

  Future<void> _loadUserStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLevel = prefs.getInt('userLevel') ?? 1;
      totalPoints = prefs.getInt('userPoints') ?? 0;
    });
  }

  // ✅ UPDATED: Load data REAL dari Firebase + JSON
  Future<void> _loadJsonData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      // Load data static dari JSON
      final results = await Future.wait([
        JsonService.getAchievementsList(),
        JsonService.getMotivationalMessage(),
      ]);

      final achievements = results[0] as List<Map<String, dynamic>>;
      final motivationalMessage = results[1] as String;

      // ✅ LOAD REAL DATA DARI FIREBASE
      if (userId.isNotEmpty) {
        // Get all targets dari Firebase
        final allTargets =
            await FirebaseTargetService.getTargetsByUserId(userId);

        print('📊 Loaded ${allTargets.length} targets from Firebase');

        // ✅ HITUNG DAILY PROGRESS (7 hari terakhir)
        final dailyProgress = _calculateDailyProgress(allTargets);

        // ✅ HITUNG CATEGORY STATS (real-time)
        final categoryStats = await _calculateCategoryStats(userId, allTargets);

        // ✅ HITUNG STREAK INFO
        final streakInfo = _calculateStreakInfo(allTargets);

        setState(() {
          this.dailyProgress = dailyProgress;
          this.categoryStats = categoryStats;
          this.achievements = achievements;
          this.streakInfo = streakInfo;
          this.motivationalMessage = motivationalMessage;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // ✅ HITUNG PROGRESS 7 HARI TERAKHIR (FIREBASE DATA)
  List<Map<String, dynamic>> _calculateDailyProgress(List<dynamic> allTargets) {
    final today = DateTime.now();
    final List<Map<String, dynamic>> progress = [];
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));

      // Filter targets untuk hari ini
      final dayTargets = allTargets.where((target) {
        final targetDate = target.targetDate;
        return targetDate.year == date.year &&
            targetDate.month == date.month &&
            targetDate.day == date.day;
      }).toList();

      final total = dayTargets.length;
      final completed = dayTargets.where((t) => t.isCompleted).length;
      final percentage = total > 0 ? ((completed / total) * 100).round() : 0;

      progress.add({
        'day': days[date.weekday % 7],
        'date': '${date.day}/${date.month}',
        'completed': completed,
        'total': total,
        'percentage': percentage,
      });
    }

    print('📈 Daily progress calculated: ${progress.length} days');
    return progress;
  }

  // ✅ HITUNG STATISTIK PER KATEGORI (FIREBASE DATA)
  Future<List<Map<String, dynamic>>> _calculateCategoryStats(
    String userId,
    List<dynamic> allTargets,
  ) async {
    final categories = await JsonService.getCategoriesList();
    final List<Map<String, dynamic>> stats = [];

    for (var category in categories) {
      final categoryName = category['name'].toString();

      // Filter targets by category dari Firebase
      final categoryTargets =
          allTargets.where((t) => t.category == categoryName).toList();

      final total = categoryTargets.length;
      final completed = categoryTargets.where((t) => t.isCompleted).length;
      final percentage = total > 0 ? ((completed / total) * 100).round() : 0;

      stats.add({
        'name': categoryName,
        'icon': category['icon'],
        'color': category['color'],
        'completed': completed,
        'total': total,
        'percentage': percentage,
      });
    }

    print('📊 Category stats calculated: ${stats.length} categories');
    return stats;
  }

  // ✅ HITUNG STREAK INFO (FIREBASE DATA)
  Map<String, dynamic> _calculateStreakInfo(List<dynamic> allTargets) {
    if (allTargets.isEmpty) {
      return {
        'currentStreak': 0,
        'longestStreak': 0,
      };
    }

    // Group by date and check if all completed
    final Map<String, List<dynamic>> targetsByDate = {};

    for (var target in allTargets) {
      final dateKey =
          '${target.targetDate.year}-${target.targetDate.month}-${target.targetDate.day}';
      targetsByDate.putIfAbsent(dateKey, () => []);
      targetsByDate[dateKey]!.add(target);
    }

    // Sort dates (newest first)
    final sortedDates = targetsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (var dateKey in sortedDates) {
      final dayTargets = targetsByDate[dateKey]!;
      final allCompleted =
          dayTargets.isNotEmpty && dayTargets.every((t) => t.isCompleted);

      if (allCompleted) {
        final parts = dateKey.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        if (lastDate == null) {
          // First completed day
          tempStreak = 1;
          currentStreak = 1;
        } else {
          // Check if consecutive
          final difference = lastDate.difference(date).inDays;
          if (difference == 1) {
            tempStreak++;
            currentStreak = tempStreak;
          } else {
            tempStreak = 1;
          }
        }

        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }

        lastDate = date;
      } else {
        if (lastDate != null) {
          tempStreak = 0;
        }
      }
    }

    print(
        '🔥 Streak calculated: current=$currentStreak, longest=$longestStreak');

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  // ✅ REFRESH DATA
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _loadUserStats();
    await _loadJsonData();
  }

  void handleNavigation(int index) {
    if (index == selectedNavIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home').then((_) {
          _refreshData();
        });
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/progress_home').then((_) {
          _refreshData();
        });
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile').then((_) {
          _refreshData();
        });
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/setting').then((_) {
          _refreshData();
        });
        break;
    }
  }

  double getProgressToNextLevel() {
    return totalPoints / pointsForNextLevel;
  }

  int getPointsNeeded() {
    return pointsForNextLevel - totalPoints;
  }

  double getWeeklyAverage() {
    if (dailyProgress.isEmpty) return 0.0;
    int totalPercentage =
        dailyProgress.fold(0, (sum, item) => sum + (item['percentage'] as int));
    return totalPercentage / dailyProgress.length;
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'mosque':
        return Icons.mosque;
      case 'menu_book':
        return Icons.menu_book;
      case 'favorite':
        return Icons.favorite;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.stars;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(progressTitle),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.primaryColor,
              ),
              const SizedBox(height: paddingMedium),
              Text(
                '🔄 Memuat data dari Firebase...',
                style: TextStyle(
                  color: isDark ? darkTextColorLight : textColorLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    double progressPercentage = getProgressToNextLevel() * 100;
    int pointsNeeded = getPointsNeeded();
    double weeklyAvg = getWeeklyAverage();
    int currentStreak = streakInfo['currentStreak'] ?? 0;
    int longestStreak = streakInfo['longestStreak'] ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).progressTitle),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: AppLocalizations.of(context).refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: paddingMedium),

                  // LEVEL & POINTS SECTION
                  _buildLevelSection(
                      isDark, currentStreak, progressPercentage, pointsNeeded),

                  const SizedBox(height: paddingLarge),

                  // STREAK SECTION
                  _buildStreakSection(isDark, currentStreak, longestStreak),

                  const SizedBox(height: paddingNormal),

                  // DAILY PROGRESS CHART
                  _buildDailyProgressSection(isDark, weeklyAvg),

                  const SizedBox(height: paddingLarge),

                  // CATEGORY STATISTICS
                  _buildCategoryStatsSection(isDark),

                  const SizedBox(height: paddingLarge),

                  // ACHIEVEMENTS
                  _buildAchievementSection(isDark),

                  const SizedBox(height: paddingLarge),

                  // MOTIVATION BOX
                  _buildMotivationBox(isDark),

                  const SizedBox(height: paddingMedium),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: selectedNavIndex,
        onTap: handleNavigation,
      ),
    );
  }

  // [SEMUA METHOD _build... TETAP SAMA SEPERTI SEBELUMNYA]
  // Saya skip karena terlalu panjang, tapi semua method build UI tetap sama

  Widget _buildLevelSection(bool isDark, int currentStreak,
      double progressPercentage, int pointsNeeded) {
    return Container(
      padding: const EdgeInsets.all(paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [primaryColorLight, primaryColorDark]
              : [primaryColor, primaryColorDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: textColorWhite, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Level',
                        style: TextStyle(color: textColorWhite, fontSize: 10),
                      ),
                      Text(
                        '$currentLevel',
                        style: const TextStyle(
                          color: textColorWhite,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ibadah Konsisten',
                        style: TextStyle(
                          color: textColorWhite,
                          fontSize: fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalPoints Poin',
                        style: const TextStyle(
                          color: textColorWhite,
                          fontSize: fontSizeNormal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currentStreak hari streak',
                            style: const TextStyle(
                              color: accentColor,
                              fontSize: fontSizeSmall,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: paddingNormal),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress ke Level Berikutnya:',
                    style: TextStyle(
                      color: textColorWhite,
                      fontSize: fontSizeSmall,
                    ),
                  ),
                  Text(
                    '${progressPercentage.toStringAsFixed(0)}% ($pointsNeeded poin)',
                    style: const TextStyle(
                      color: textColorWhite,
                      fontSize: fontSizeSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: paddingSmall),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: getProgressToNextLevel(),
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(
      bool isDark, int currentStreak, int longestStreak) {
    return Container(
      padding: const EdgeInsets.all(paddingNormal),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(paddingSmall),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(borderRadiusSmall),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: textColorWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: paddingNormal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak Hari Berturut-turut! 🔥',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: isDark ? darkTextColor : textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Terbaik: $longestStreak hari',
                  style: TextStyle(
                    fontSize: fontSizeSmall,
                    color: isDark ? darkTextColorLight : textColorLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgressSection(bool isDark, double weeklyAvg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress 7 Hari Terakhir',
              style: TextStyle(
                fontSize: fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: isDark ? darkTextColor : textColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: paddingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadiusSmall),
              ),
              child: Text(
                'Rata-rata: ${weeklyAvg.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: isDark ? primaryColorLight : primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: paddingNormal),
        Container(
          padding: const EdgeInsets.all(paddingMedium),
          decoration: BoxDecoration(
            color: isDark ? darkCardBackgroundColor : cardBackgroundColor,
            borderRadius: BorderRadius.circular(borderRadiusNormal),
            border: Border.all(
              color: isDark ? darkBorderColor : borderColor,
            ),
          ),
          child: SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyProgress.map((day) {
                final percentage = day['percentage'] as int;
                final isToday = day == dailyProgress.last;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? (isDark ? primaryColorLight : primaryColor)
                                : (isDark
                                    ? darkTextColorLight
                                    : textColorLight),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: double.infinity,
                          height: (percentage / 100) * 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isToday
                                  ? [primaryColor, primaryColorDark]
                                  : percentage >= 75
                                      ? [successColor, const Color(0xFF388E3C)]
                                      : percentage >= 50
                                          ? [
                                              accentColor,
                                              const Color(0xFFFFA000)
                                            ]
                                          : [
                                              errorColor,
                                              const Color(0xFFD32F2F)
                                            ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day['day'],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? (isDark ? primaryColorLight : primaryColor)
                                : (isDark
                                    ? darkTextColorLight
                                    : textColorLight),
                          ),
                        ),
                        Text(
                          '${day['completed']}/${day['total']}',
                          style: TextStyle(
                            fontSize: 8,
                            color: isDark
                                ? darkTextColorLighter
                                : textColorLighter,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStatsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Per Kategori',
          style: TextStyle(
            fontSize: fontSizeLarge,
            fontWeight: FontWeight.w600,
            color: isDark ? darkTextColor : textColor,
          ),
        ),
        const SizedBox(height: paddingNormal),
        Column(
          children: categoryStats.map((category) {
            final percentage = category['percentage'] as int;
            final color = _getColorFromHex(category['color'].toString());
            final icon = _getIconFromName(category['icon'].toString());

            return Padding(
              padding: const EdgeInsets.only(bottom: paddingMedium),
              child: Container(
                padding: const EdgeInsets.all(paddingMedium),
                decoration: BoxDecoration(
                  color: isDark ? darkCardBackgroundColor : cardBackgroundColor,
                  borderRadius: BorderRadius.circular(borderRadiusNormal),
                  border: Border.all(
                    color: isDark ? darkBorderColor : borderColor,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(paddingSmall),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(borderRadiusSmall),
                          ),
                          child: Icon(icon, color: color, size: iconSizeNormal),
                        ),
                        const SizedBox(width: paddingNormal),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['name'].toString(),
                                style: TextStyle(
                                  fontSize: fontSizeMedium,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? darkTextColor : textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${category['completed']}/${category['total']} selesai',
                                style: TextStyle(
                                  fontSize: fontSizeSmall,
                                  color: isDark
                                      ? darkTextColorLight
                                      : textColorLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: paddingSmall,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(borderRadiusSmall),
                          ),
                          child: Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: paddingNormal),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor:
                            isDark ? darkDividerColor : dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAchievementSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pencapaian',
              style: TextStyle(
                fontSize: fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: isDark ? darkTextColor : textColor,
              ),
            ),
            Text(
              '${achievements.where((a) => a['unlocked']).length}/${achievements.length} terbuka',
              style: TextStyle(
                fontSize: fontSizeSmall,
                color: isDark ? darkTextColorLight : textColorLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: paddingNormal),
        Column(
          children: achievements.map((achievement) {
            final unlocked = achievement['unlocked'] as bool;
            final color = _getColorFromHex(achievement['color'].toString());
            final icon = _getIconFromName(achievement['icon'].toString());

            return Padding(
              padding: const EdgeInsets.only(bottom: paddingNormal),
              child: Container(
                padding: const EdgeInsets.all(paddingMedium),
                decoration: BoxDecoration(
                  color: unlocked
                      ? color.withOpacity(0.1)
                      : (isDark
                          ? darkCardBackgroundColor
                          : cardBackgroundColor),
                  borderRadius: BorderRadius.circular(borderRadiusNormal),
                  border: Border.all(
                    color: unlocked
                        ? color
                        : (isDark ? darkBorderColor : borderColor),
                    width: unlocked ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? color
                            : (isDark ? darkDividerColor : dividerColor),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: unlocked
                            ? textColorWhite
                            : (isDark ? darkTextColorLight : textColorLight),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement['title'].toString(),
                            style: TextStyle(
                              fontSize: fontSizeNormal,
                              fontWeight: FontWeight.w600,
                              color: unlocked
                                  ? (isDark ? darkTextColor : textColor)
                                  : (isDark
                                      ? darkTextColorLight
                                      : textColorLight),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement['description'].toString(),
                            style: TextStyle(
                              fontSize: fontSizeSmall,
                              color: unlocked
                                  ? (isDark
                                      ? darkTextColorLight
                                      : textColorLight)
                                  : (isDark
                                      ? darkTextColorLighter
                                      : textColorLighter),
                            ),
                          ),
                          if (unlocked && achievement['unlockedDate'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: paddingSmall),
                              child: Text(
                                'Didapat: ${achievement['unlockedDate']}',
                                style: TextStyle(
                                  fontSize: fontSizeSmall,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      unlocked ? Icons.check_circle : Icons.lock,
                      color: unlocked
                          ? color
                          : (isDark ? darkTextColorLighter : textColorLighter),
                      size: iconSizeNormal,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMotivationBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [infoColor.withOpacity(0.1), infoColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        border: Border.all(color: infoColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb,
            color: infoColor,
            size: iconSizeMedium,
          ),
          const SizedBox(width: paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💪 Motivasi Hari Ini:',
                  style: TextStyle(
                    fontSize: fontSizeNormal,
                    fontWeight: FontWeight.w600,
                    color: isDark ? darkTextColor : textColor,
                  ),
                ),
                const SizedBox(height: paddingSmall),
                Text(
                  motivationalMessage.isEmpty
                      ? 'Terus semangat menjalankan ibadah!'
                      : motivationalMessage,
                  style: TextStyle(
                    fontSize: fontSizeSmall,
                    color: isDark ? darkTextColorLight : textColorLight,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
        title: Text(
          'Tentang Poin & Level',
          style: TextStyle(
            color: isDark ? darkTextColor : textColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cara Mendapat Poin:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSizeMedium,
                  color: isDark ? darkTextColor : textColor,
                ),
              ),
              const SizedBox(height: paddingSmall),
              Text(
                '• Selesaikan target: +10 poin\n'
                '• Selesaikan semua target hari ini: +50 poin\n'
                '• Streak 7 hari: +100 poin\n'
                '• Unlock achievement: +50 poin',
                style: TextStyle(
                  color: isDark ? darkTextColorLight : textColorLight,
                ),
              ),
              const SizedBox(height: paddingMedium),
              Text(
                'Level:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSizeMedium,
                  color: isDark ? darkTextColor : textColor,
                ),
              ),
              const SizedBox(height: paddingSmall),
              Text(
                'Level 1: 0-500 poin\n'
                'Level 2: 500-1500 poin\n'
                'Level 3: 1500-3000 poin\n'
                'Level 4: 3000-5000 poin\n'
                'Level 5: 5000+ poin',
                style: TextStyle(
                  color: isDark ? darkTextColorLight : textColorLight,
                ),
              ),
              const SizedBox(height: paddingMedium),
              Container(
                padding: const EdgeInsets.all(paddingSmall),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(borderRadiusSmall),
                  border: Border.all(color: successColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_done,
                      color: successColor,
                      size: 16,
                    ),
                    const SizedBox(width: paddingSmall),
                    Expanded(
                      child: Text(
                        'Data disinkronkan dengan Firebase secara real-time',
                        style: TextStyle(
                          fontSize: fontSizeSmall,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                color: isDark ? primaryColorLight : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
