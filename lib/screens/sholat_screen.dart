import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ⬅️ TAMBAHKAN
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/prayer_time_model.dart';
import '../services/json_service.dart';
import '../services/prayer_api_service.dart';
import '../widgets/bottom_navigation.dart';
import '../providers/theme_provider.dart'; // ⬅️ TAMBAHKAN
import 'dart:async'; // Tambahkan di bagian atas

class SholatScreen extends StatefulWidget {
  const SholatScreen({Key? key}) : super(key: key);

  @override
  State<SholatScreen> createState() => _SholatScreenState();
}

class _SholatScreenState extends State<SholatScreen> {
  int selectedNavIndex = 0;
  bool isLoading = true;
  Timer? _countdownTimer;
  Duration? _remainingDuration;

  Map<String, String> prayerTimes = {};
  Map<String, String> nextPrayerInfo = {};
  String selectedCity = 'Malang';
  String selectedCountry = 'Indonesia';

  // Icon mapping untuk setiap waktu sholat
  final Map<String, String> prayerIcons = {
    'Subuh': '🌙',
    'Dhuhur': '☀️',
    'Ashar': '🌤️',
    'Maghrib': '🌅',
    'Isya': '🌙',
  };

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  // LOAD DATA dari JSON
  Future<void> _loadJsonData() async {
    try {
      // Load lokasi dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('selected_city') ?? 'Malang';
      final country = prefs.getString('selected_country') ?? 'Indonesia';

      setState(() {
        selectedCity = city;
        selectedCountry = country;
      });

      print('🔡 Fetching prayer times for $city, $country...');

      // Try API with auto fallback
      final prayerTime = await PrayerApiService.getPrayerTimesByCity(
        city: city,
        country: country,
        useFallback: true,
      );
      // ... sisa code sama

      if (prayerTime != null) {
        final allPrayers = prayerTime.getAllPrayerTimes();
        final nextPrayer = prayerTime.getNextPrayerTime();

        setState(() {
          prayerTimes = Map.fromEntries(
              allPrayers.map((item) => MapEntry(item.name, item.time)));

          if (nextPrayer != null) {
            final duration = prayerTime.getTimeUntilNextPrayer();
            nextPrayerInfo = {
              'name': nextPrayer.name,
              'countdown': _formatDuration(duration),
            };
          }

          isLoading = false;
        });

        if (prayerTime != null) {
          _startCountdownTimer(prayerTime);
        }

        print('✅ Prayer times loaded: ${prayerTimes.length} prayers');
      } else {
        throw Exception('Prayer time is null');
      }
    } catch (e) {
      print('❌ Error loading prayer times: $e');
      print('📦 Using JSON fallback...');

      // Ultimate fallback to JSON
      try {
        final results = await Future.wait([
          JsonService.getPrayerTimesMap(),
          JsonService.getNextPrayerInfo(),
        ]);

        setState(() {
          prayerTimes = results[0] as Map<String, String>;
          nextPrayerInfo = results[1] as Map<String, String>;
          isLoading = false;
        });

        print('✅ Loaded from JSON fallback');
      } catch (fallbackError) {
        print('❌ Fallback failed: $fallbackError');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0h 0m 0s';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours}h ${minutes}m ${seconds}s';
  }

  void handleNavigation(int index) {
    setState(() {
      selectedNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/progress');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/progress_home');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/setting');
        break;
    }
  }

  // Format date
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

  @override
  Widget build(BuildContext context) {
    // ⬅️ GET THEME STATE
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
        appBar: AppBar(
          title: const Text('Jadwal Sholat'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get next prayer name
    final nextPrayerName = nextPrayerInfo['name'] ?? '';

    return Scaffold(
      backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
      appBar: AppBar(
        title: const Text('Jadwal Sholat'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Text(
                  'Jadwal Sholat Hari Ini',
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
                const SizedBox(height: paddingSmall),
                // ✅ TAMBAH INI - Tampilan Lokasi
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isDark ? primaryColorLight : primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$selectedCity, $selectedCountry',
                      style: TextStyle(
                        fontSize: fontSizeSmall,
                        color: isDark ? primaryColorLight : primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: paddingLarge),

                // SHOLAT TIMES LIST
                prayerTimes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(paddingLarge),
                          child: Text(
                            'Jadwal sholat tidak tersedia',
                            style: TextStyle(
                              fontSize: fontSizeNormal,
                              color:
                                  isDark ? darkTextColorLight : textColorLight,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: prayerTimes.entries.map((entry) {
                          final sholatName = entry.key;
                          final sholatTime = entry.value;
                          final isNextPrayer = sholatName == nextPrayerName;
                          final icon = prayerIcons[sholatName] ?? '🕌';

                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: paddingMedium),
                            child: Card(
                              elevation: 2,
                              color: isDark
                                  ? darkCardBackgroundColor
                                  : cardBackgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(borderRadiusNormal),
                                side: isNextPrayer
                                    ? BorderSide(
                                        color: isDark
                                            ? primaryColorLight
                                            : primaryColor,
                                        width: 2,
                                      )
                                    : BorderSide(
                                        color: isDark
                                            ? darkBorderColor
                                            : Colors.transparent,
                                      ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(borderRadiusNormal),
                                  gradient: isNextPrayer
                                      ? LinearGradient(
                                          colors: isDark
                                              ? [
                                                  primaryColorLight
                                                      .withOpacity(0.2),
                                                  primaryColorLight
                                                      .withOpacity(0.1),
                                                ]
                                              : [
                                                  primaryColor.withOpacity(0.1),
                                                  primaryColor
                                                      .withOpacity(0.05),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                ),
                                padding: const EdgeInsets.all(paddingMedium),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              icon,
                                              style:
                                                  const TextStyle(fontSize: 24),
                                            ),
                                            const SizedBox(width: paddingSmall),
                                            Text(
                                              sholatName,
                                              style: TextStyle(
                                                fontSize: fontSizeMedium,
                                                fontWeight: FontWeight.w600,
                                                color: isNextPrayer
                                                    ? (isDark
                                                        ? primaryColorLight
                                                        : primaryColor)
                                                    : (isDark
                                                        ? darkTextColor
                                                        : textColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: paddingSmall),
                                        if (isNextPrayer)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
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
                                            child: const Text(
                                              'Sholat Berikutnya',
                                              style: TextStyle(
                                                fontSize: fontSizeSmall,
                                                color: textColorWhite,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          sholatTime,
                                          style: TextStyle(
                                            fontSize: fontSizeXLarge,
                                            fontWeight: FontWeight.bold,
                                            color: isNextPrayer
                                                ? (isDark
                                                    ? primaryColorLight
                                                    : primaryColor)
                                                : (isDark
                                                    ? darkTextColor
                                                    : textColor),
                                          ),
                                        ),
                                        const SizedBox(height: paddingSmall),
                                        if (isNextPrayer &&
                                            _remainingDuration != null)
                                          Text(
                                            'dalam ${_formatDuration(_remainingDuration)}',
                                            style: TextStyle(
                                              fontSize: fontSizeSmall,
                                              color: isDark
                                                  ? primaryColorLight
                                                  : primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                const SizedBox(height: paddingMedium),

                // REMINDER SECTION
                Container(
                  padding: const EdgeInsets.all(paddingMedium),
                  decoration: BoxDecoration(
                    color: infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(borderRadiusNormal),
                    border: Border.all(color: infoColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔔 Pengingat Sholat',
                        style: TextStyle(
                          fontSize: fontSizeNormal,
                          fontWeight: FontWeight.w600,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                      const SizedBox(height: paddingSmall),
                      Text(
                        'Fitur pengingat sholat akan segera diaktifkan. Anda akan menerima notifikasi pada waktu sholat.',
                        style: TextStyle(
                          fontSize: fontSizeSmall,
                          color: isDark ? darkTextColorLight : textColorLight,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: paddingMedium),
                      Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: (value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Fitur notifikasi akan tersedia di versi lengkap'),
                                  backgroundColor: warningColor,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            activeColor:
                                isDark ? primaryColorLight : primaryColor,
                          ),
                          Text(
                            'Aktifkan notifikasi sholat',
                            style: TextStyle(
                              fontSize: fontSizeSmall,
                              color: isDark ? darkTextColor : textColor,
                            ),
                          ),
                        ],
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
      bottomNavigationBar: BottomNavigation(
        currentIndex: selectedNavIndex,
        onTap: handleNavigation,
      ),
    );
  }

  void _startCountdownTimer(PrayerTime prayerTime) {
    _countdownTimer?.cancel(); // Cancel timer sebelumnya jika ada

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final duration = prayerTime.getTimeUntilNextPrayer();
      if (duration != null && mounted) {
        setState(() {
          _remainingDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
