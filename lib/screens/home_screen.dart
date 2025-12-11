import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:targetibadah_gamifikasi/services/firebase/firebase_target_service.dart';
import '../constants.dart';
import '../models/target_ibadah_model.dart';
import '../models/prayer_time_model.dart';
import '../services/json_service.dart';
import '../services/target_service.dart';
import '../services/prayer_api_service.dart';
import '../services/gamification_service.dart';
import '../widgets/bottom_navigation.dart';
import '../providers/theme_provider.dart';
import 'dart:async'; // ✅ TAMBAH INI

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //  VARIABLES
  int selectedNavIndex = 0;
  String userName = 'User';
  bool isLoadingUser = true;
  bool isLoadingData = true;
  Timer? _countdownTimer; // ✅ TAMBAH INI
  Duration? _remainingDuration; // ✅ TAMBAH INI
  PrayerTime? _currentPrayerTime;
  String selectedCity = 'Malang';
  String selectedCountry = 'Indonesia';

  // Data dari JSON
  Map<String, String> prayerTimes = {};
  List<TargetIbadah> targets = [];
  List<Map<String, dynamic>> categories = [];
  Map<String, String> nextPrayerInfo = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadJsonData();
  }

  // ✅ TAMBAH METHOD INI
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // LOAD USER DATA dari SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userName = prefs.getString('userName') ?? 'User';
        isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  Future<void> _loadJsonData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      // ✅ LOAD FIREBASE DATA DULU (PRIORITAS)
      final todayTargets = await FirebaseTargetService.getTargetsByDate(
        userId: userId,
        date: DateTime.now(),
      );

      final categoriesList = await JsonService.getCategoriesList();

// ✅ Filter untuk menghapus kategori "Lainnya"
      final filteredCategories =
          categoriesList.where((cat) => cat['name'] != 'Lainnya').toList();

      setState(() {
        targets = todayTargets;
        categories = filteredCategories; // ✅ Gunakan yang sudah difilter
        isLoadingData = false;
      });

      // ✅ LOAD PRAYER TIMES DI BACKGROUND (TIDAK BLOCKING)
      _loadPrayerTimesAsync();
    } catch (e) {
      print('Error loading JSON data: $e');
      setState(() {
        isLoadingData = false;
      });
    }
  }

// ✅ METHOD BARU - LOAD PRAYER TIMES ASYNC
  Future<void> _loadPrayerTimesAsync() async {
    try {
      // ✅ Load lokasi dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('selected_city') ?? 'Malang';
      final country = prefs.getString('selected_country') ?? 'Indonesia';

      setState(() {
        selectedCity = city;
        selectedCountry = country;
      });

      final prayerTime = await PrayerApiService.getPrayerTimesByCity(
        city: city,
        country: country,
        useFallback: true,
      ).timeout(
        const Duration(seconds: 5),
      );

      if (prayerTime != null) {
        final allPrayers = prayerTime.getAllPrayerTimes();
        final nextPrayer = prayerTime.getNextPrayerTime();

        setState(() {
          _currentPrayerTime = prayerTime; // ✅ SIMPAN OBJECT PRAYERTIME
          prayerTimes = Map.fromEntries(
              allPrayers.map((item) => MapEntry(item.name, item.time)));

          if (nextPrayer != null) {
            final duration = prayerTime.getTimeUntilNextPrayer();
            nextPrayerInfo = {
              'name': nextPrayer.name,
              'countdown': _formatDuration(duration),
            };
          }
        });

        // ✅ START COUNTDOWN TIMER
        _startCountdownTimer();
      }
    } catch (e) {
      print('Prayer API failed, using fallback: $e');
      final prayerTimesMap = await JsonService.getPrayerTimesMap();
      final nextPrayerInfoMap = await JsonService.getNextPrayerInfo();

      setState(() {
        prayerTimes = prayerTimesMap;
        nextPrayerInfo = nextPrayerInfoMap;
      });
    }
  }

  // Refresh Data
  Future<void> _refreshData() async {
    setState(() {
      isLoadingData = true;
    });
    await _loadJsonData();
  }

  // Get Greeting berdasarkan waktu
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // Helper function untuk format duration
  String _formatDuration(Duration? duration) {
    if (duration == null) return '0h 0m 0s'; // ✅ TAMBAH DETIK
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60); // ✅ TAMBAH INI
    return '${hours}h ${minutes}m ${seconds}s'; // ✅ TAMBAH DETIK
  }

  // HELPER FUNCTION - Hitung progress
  int getCompletedTargetsCount() {
    return targets.where((target) => target.isCompleted).length;
  }

  int getTodayTargetsCount() {
    return targets.length;
  }

  double getProgressPercentage() {
    final todayTargets = getTodayTargetsCount();
    if (todayTargets == 0) return 0;
    return (getCompletedTargetsCount() / todayTargets) * 100;
  }

  // HANDLE NAVIGATION
  void handleNavigation(int index) {
    if (index == 0) return;

    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/progress').then((_) {
          setState(() => selectedNavIndex = 0);
        });
        break;
      case 2:
        Navigator.pushNamed(context, '/progress_home').then((_) {
          setState(() => selectedNavIndex = 0);
          _refreshData();
        });
        break;
      case 3:
        Navigator.pushNamed(context, '/profile').then((_) {
          setState(() => selectedNavIndex = 0);
        });
        break;
      case 4:
        Navigator.pushNamed(context, '/setting').then((_) {
          setState(() => selectedNavIndex = 0);
        });
        break;
    }
  }

  // HANDLE CATEGORY NAVIGATION
  void handleCategoryTap(String categoryName) {
    if (categoryName == categoryPrayer) {
      Navigator.pushNamed(context, '/sholat');
    } else if (categoryName == categoryQuran) {
      Navigator.pushNamed(context, '/quran');
    } else if (categoryName == categoryZikir) {
      Navigator.pushNamed(context, '/dzikir');
    } else if (categoryName == categoryCharity) {
      Navigator.pushNamed(context, '/sedekah');
    }
  }

  // ✅ METHOD BARU - START COUNTDOWN TIMER
  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentPrayerTime != null && mounted) {
        final duration = _currentPrayerTime!.getTimeUntilNextPrayer();
        final nextPrayer = _currentPrayerTime!.getNextPrayerTime();

        setState(() {
          _remainingDuration = duration;
          if (nextPrayer != null && duration != null) {
            nextPrayerInfo = {
              'name': nextPrayer.name,
              'countdown': _formatDuration(duration),
            };
          }
        });
      }
    });
  }

  // HANDLE CHECKBOX
  Future<void> handleCheckboxChange(String targetId, bool isChecked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      // ✅ UPDATE MENGGUNAKAN FIREBASE
      final success = await FirebaseTargetService.updateTargetCompletion(
        userId: userId,
        targetId: targetId,
        isCompleted: isChecked,
      );

      if (success) {
        setState(() {
          final index = targets.indexWhere((t) => t.id == targetId);
          if (index != -1) {
            targets[index] = targets[index].copyWith(isCompleted: isChecked);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  isChecked ? '✅ Target diselesaikan!' : 'Target dibatalkan'),
              backgroundColor: isChecked ? successColor : warningColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        if (isChecked) {
          await GamificationService.addPoints(
            userId: userId,
            points: 10,
            reason: 'Menyelesaikan target',
          );
        }
      } else {
        throw Exception('Gagal mengupdate target');
      }
    } catch (e) {
      print('Error updating target: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // GET COLOR from HEX string
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  // GET ICON from string name
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'mosque':
        return Icons.mosque;
      case 'menu_book':
        return Icons.menu_book;
      case 'favorite':
        return Icons.favorite;
      case 'favorite_border':
        return Icons.favorite_border;
      default:
        return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    int completedCount = getCompletedTargetsCount();
    int todayCount = getTodayTargetsCount();
    double progress = getProgressPercentage();

    // Loading state
    if (isLoadingData) {
      return Scaffold(
        backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: paddingMedium),
              Text(
                'Memuat...',
                style: TextStyle(
                  color: isDark ? darkTextColor : textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GREETING SECTION
                Padding(
                  padding: const EdgeInsets.all(paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, $userName 👋',
                        style: TextStyle(
                          fontSize: fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                      const SizedBox(height: paddingSmall),
                      Text(
                        _getFormattedDate(DateTime.now()),
                        style: TextStyle(
                          fontSize: fontSizeNormal,
                          color: isDark ? darkTextColorLight : textColorLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // PRAYER TIMES CARD
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: paddingMedium),
                  child: Card(
                    elevation: 3,
                    color: isDark ? darkCardBackgroundColor : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [primaryColorLight, primaryColorDark]
                              : [primaryColor, primaryColorDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(borderRadiusNormal),
                      ),
                      padding: const EdgeInsets.all(paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ UBAH DARI Text biasa MENJADI Row dengan lokasi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Waktu Sholat',
                                style: TextStyle(
                                  color: textColorWhite,
                                  fontSize: fontSizeLarge,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: textColorWhite,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$selectedCity, $selectedCountry',
                                    style: const TextStyle(
                                      color: textColorWhite,
                                      fontSize: fontSizeSmall,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: paddingNormal),
                          prayerTimes.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Jadwal sholat tidak tersedia',
                                    style: TextStyle(color: textColorWhite),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: prayerTimes.entries.map((entry) {
                                    return Column(
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            color: textColorWhite,
                                            fontSize: fontSizeSmall,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.value,
                                          style: const TextStyle(
                                            color: textColorWhite,
                                            fontSize: fontSizeMedium,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                          const SizedBox(height: paddingMedium),
                          if (nextPrayerInfo.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(paddingSmall),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(borderRadiusSmall),
                              ),
                              child: Text(
                                'Sholat Berikutnya: ${nextPrayerInfo['name']} ${nextPrayerInfo['countdown']} ⏰',
                                style: const TextStyle(
                                  color: textColorWhite,
                                  fontSize: fontSizeSmall,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: paddingMedium),

                // PROGRESS SECTION
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress Hari Ini',
                            style: TextStyle(
                              fontSize: fontSizeLarge,
                              fontWeight: FontWeight.w600,
                              color: isDark ? darkTextColor : textColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/progress');
                            },
                            child: Text(
                              'Lihat Detail',
                              style: TextStyle(
                                fontSize: fontSizeSmall,
                                color:
                                    isDark ? primaryColorLight : primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: paddingNormal),
                      Container(
                        padding: const EdgeInsets.all(paddingMedium),
                        decoration: BoxDecoration(
                          color: isDark
                              ? darkCardBackgroundColor
                              : cardBackgroundColor,
                          borderRadius:
                              BorderRadius.circular(borderRadiusNormal),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 12,
                                backgroundColor:
                                    isDark ? darkBorderColor : dividerColor,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 75
                                      ? successColor
                                      : progress >= 50
                                          ? accentColor
                                          : errorColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: paddingNormal),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$completedCount dari $todayCount target selesai',
                                  style: TextStyle(
                                    fontSize: fontSizeMedium,
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
                                    color: progress >= 75
                                        ? successColor.withOpacity(0.1)
                                        : progress >= 50
                                            ? accentColor.withOpacity(0.1)
                                            : errorColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        borderRadiusSmall),
                                  ),
                                  child: Text(
                                    '${progress.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: fontSizeMedium,
                                      fontWeight: FontWeight.bold,
                                      color: progress >= 75
                                          ? successColor
                                          : progress >= 50
                                              ? accentColor
                                              : errorColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (progress == 100)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: paddingSmall),
                                child: Container(
                                  padding: const EdgeInsets.all(paddingSmall),
                                  decoration: BoxDecoration(
                                    color: successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        borderRadiusSmall),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.celebration,
                                          color: successColor, size: 16),
                                      SizedBox(width: paddingSmall),
                                      Expanded(
                                        child: Text(
                                          'Luar biasa! Semua target hari ini selesai! 🎉',
                                          style: TextStyle(
                                            fontSize: fontSizeSmall,
                                            color: successColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: paddingMedium),

// CATEGORY SECTION
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                      const SizedBox(height: paddingNormal),
                      categories.isEmpty
                          ? Text(
                              'Kategori tidak tersedia',
                              style: TextStyle(
                                color: isDark
                                    ? darkTextColorLight
                                    : textColorLight,
                              ),
                            )
                          : Row(
                              // ✅ UBAH ke Row untuk distribusi merata
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceEvenly, // ✅ Distribusi merata
                              children: categories.map((category) {
                                final color = _getColorFromHex(
                                    category['color'].toString());
                                final icon = _getIconFromName(
                                    category['icon'].toString());

                                return GestureDetector(
                                  onTap: () {
                                    handleCategoryTap(
                                        category['name'].toString());
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                              borderRadiusNormal),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          icon,
                                          color: textColorWhite,
                                          size: iconSizeNormal,
                                        ),
                                      ),
                                      const SizedBox(height: paddingSmall),
                                      Text(
                                        category['name'].toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: fontSizeSmall,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? darkTextColor
                                              : textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: paddingMedium),

                // TARGET LIST SECTION
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target Hari Ini',
                            style: TextStyle(
                              fontSize: fontSizeLarge,
                              fontWeight: FontWeight.w600,
                              color: isDark ? darkTextColor : textColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/progress_home');
                            },
                            child: Text(
                              'Kelola Target',
                              style: TextStyle(
                                fontSize: fontSizeSmall,
                                color:
                                    isDark ? primaryColorLight : primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: paddingNormal),
                      targets.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: paddingLarge),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.task_alt,
                                      size: 48,
                                      color: isDark
                                          ? darkTextColorLight
                                          : textColorLighter,
                                    ),
                                    const SizedBox(height: paddingNormal),
                                    Text(
                                      'Tidak ada target untuk hari ini',
                                      style: TextStyle(
                                        fontSize: fontSizeNormal,
                                        color: isDark
                                            ? darkTextColorLight
                                            : textColorLight,
                                      ),
                                    ),
                                    const SizedBox(height: paddingSmall),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                            context, '/progress_home');
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Tambah Target'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: targets.map((target) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: paddingNormal),
                                  child: Card(
                                    elevation: 1,
                                    color:
                                        isDark ? darkCardBackgroundColor : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          borderRadiusNormal),
                                    ),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(paddingMedium),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: target.isCompleted,
                                            onChanged: (value) {
                                              handleCheckboxChange(
                                                  target.id, value ?? false);
                                            },
                                            activeColor: successColor,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  target.name,
                                                  style: TextStyle(
                                                    fontSize: fontSizeMedium,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: target
                                                            .isCompleted
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : TextDecoration.none,
                                                    color: target.isCompleted
                                                        ? (isDark
                                                            ? darkTextColorLight
                                                            : textColorLight)
                                                        : (isDark
                                                            ? darkTextColor
                                                            : textColor),
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height: paddingSmall),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: paddingSmall,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? primaryColorLight
                                                        : primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            borderRadiusSmall),
                                                  ),
                                                  child: Text(
                                                    target.category,
                                                    style: const TextStyle(
                                                      color: textColorWhite,
                                                      fontSize: fontSizeSmall,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                if (target.note.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: paddingSmall),
                                                    child: Text(
                                                      target.note,
                                                      style: TextStyle(
                                                        fontSize: fontSizeSmall,
                                                        color: isDark
                                                            ? darkTextColorLight
                                                            : textColorLight,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: paddingLarge),
              ],
            ),
          ),
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigation(
        currentIndex: selectedNavIndex,
        onTap: handleNavigation,
      ),
    );
  }

  // HELPER - Format Tanggal
  String _getFormattedDate(DateTime date) {
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
