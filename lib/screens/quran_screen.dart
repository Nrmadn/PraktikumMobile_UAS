import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:targetibadah_gamifikasi/screens/surah_detail_screen.dart';
import '../constants.dart';
import '../services/json_service.dart';
import '../services/quran_api_service.dart';
import '../widgets/bottom_navigation.dart';
import '../providers/quran_progress_provider.dart';
import '../providers/theme_provider.dart'; // ⬅️ TAMBAHKAN

class QuranScreen extends StatefulWidget {
  const QuranScreen({Key? key}) : super(key: key);

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  int selectedNavIndex = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> surahList = [];
  Map<String, String> readingTips = {};

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    try {
      print('📡 Fetching Quran data...');

      final surahListApi = await QuranApiService.getAllSurah(useFallback: true);

      print('📊 Raw API data: ${surahListApi.length} surah received');

      setState(() {
        surahList = surahListApi.map((surah) {
          final verses = surah['totalVerses'] ?? 0;
          
          return {
            'id': surah['number'] ?? 0,
            'name': surah['name'] ?? 'Unknown',
            'arabicName': surah['nameArabic'] ?? '',
            'verses': verses,
            'place': surah['place'] ?? 'Mekkah',
          };
        }).toList();

        readingTips = {
          'title': '📖 Tips Membaca',
          'description':
              'Target membaca 2-3 halaman setiap hari untuk menyelesaikan Al-Qur\'an dalam satu bulan.',
        };

        isLoading = false;
      });

      print('✅ Quran data loaded: ${surahList.length} surah');
    } catch (e) {
      print('❌ Error loading Quran data: $e');

      try {
        final results = await Future.wait([
          JsonService.getSurahList(),
          JsonService.getReadingTips(),
        ]);

        setState(() {
          surahList = results[0] as List<Map<String, dynamic>>;
          readingTips = results[1] as Map<String, String>;
          isLoading = false;
        });

        print('✅ Loaded from JSON fallback');
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
        setState(() {
          isLoading = false;
        });
      }
    }
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

  /// Show reset all progress confirmation
  Future<void> _showResetAllConfirmation() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
        title: Text(
          'Reset Semua Progress',
          style: TextStyle(color: isDark ? darkTextColor : textColor),
        ),
        content: Text(
          'Apakah Anda yakin ingin mereset semua progress membaca Al-Qur\'an?\n\nTindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: isDark ? darkTextColorLight : textColorLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: isDark ? primaryColorLight : primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
            ),
            child: const Text('Reset Semua'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final progressProvider = Provider.of<QuranProgressProvider>(
        context,
        listen: false,
      );
      await progressProvider.resetAllProgress();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Semua progress berhasil direset'),
            backgroundColor: successColor,
          ),
        );
      }
    }
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
          title: const Text('Al-Qur\'an'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
      appBar: AppBar(
        title: const Text('Al-Qur\'an'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Semua Progress',
            onPressed: _showResetAllConfirmation,
          ),
        ],
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
                  'Daftar Surah',
                  style: TextStyle(
                    fontSize: fontSizeXLarge,
                    fontWeight: FontWeight.bold,
                    color: isDark ? darkTextColor : textColor,
                  ),
                ),
                const SizedBox(height: paddingSmall),
                Text(
                  'Lacak progress membaca Al-Qur\'an Anda',
                  style: TextStyle(
                    fontSize: fontSizeNormal,
                    color: isDark ? darkTextColorLight : textColorLight,
                  ),
                ),

                const SizedBox(height: paddingMedium),

                // OVERALL PROGRESS CARD
                Consumer<QuranProgressProvider>(
                  builder: (context, progressProvider, child) {
                    final totalCompleted = progressProvider.getTotalCompleted(surahList);
                    final percentage = (totalCompleted / 114 * 100).toStringAsFixed(1);

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
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 Progress Keseluruhan',
                            style: TextStyle(
                              fontSize: fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: textColorWhite,
                            ),
                          ),
                          const SizedBox(height: paddingSmall),
                          Text(
                            '$totalCompleted / 114 Surah Selesai',
                            style: const TextStyle(
                              fontSize: fontSizeNormal,
                              color: textColorWhite,
                            ),
                          ),
                          const SizedBox(height: paddingSmall),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: totalCompleted / 114,
                              minHeight: 10,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: paddingSmall),
                          Text(
                            '$percentage% Tercapai',
                            style: const TextStyle(
                              fontSize: fontSizeSmall,
                              color: textColorWhite,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: paddingLarge),

                // SURAH LIST
                surahList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(paddingLarge),
                          child: Text(
                            'Tidak ada data surah',
                            style: TextStyle(
                              fontSize: fontSizeNormal,
                              color: isDark ? darkTextColorLight : textColorLight,
                            ),
                          ),
                        ),
                      )
                    : Consumer<QuranProgressProvider>(
                        builder: (context, progressProvider, child) {
                          return Column(
                            children: surahList.map((surah) {
                              final surahNumber = surah['id'] as int;
                              final totalVerses = surah['verses'] as int;
                              
                              final currentProgress = progressProvider.getProgress(surahNumber);
                              final progressValue = progressProvider.getProgressPercentage(
                                surahNumber,
                                totalVerses,
                              );
                              final isCompleted = progressProvider.isCompleted(
                                surahNumber,
                                totalVerses,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: paddingMedium,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SurahDetailScreen(
                                          surahNumber: surahNumber,
                                          surahName: surah['name']?.toString() ?? 'Unknown',
                                          surahNameArabic: surah['arabicName']?.toString() ?? '',
                                          totalVerses: totalVerses,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 2,
                                    color: isDark ? darkCardBackgroundColor : cardBackgroundColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        borderRadiusNormal,
                                      ),
                                      side: isCompleted 
                                          ? const BorderSide(color: successColor, width: 2)
                                          : BorderSide(
                                              color: isDark ? darkBorderColor : Colors.transparent,
                                            ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(paddingMedium),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          surah['name']?.toString() ?? 'Unknown Surah',
                                                          style: TextStyle(
                                                            fontSize: fontSizeMedium,
                                                            fontWeight: FontWeight.w600,
                                                            color: isDark ? darkTextColor : textColor,
                                                          ),
                                                        ),
                                                        if (isCompleted) ...[
                                                          const SizedBox(width: 8),
                                                          const Icon(
                                                            Icons.check_circle,
                                                            color: successColor,
                                                            size: 20,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    if (surah['arabicName'] != null &&
                                                        surah['arabicName'].toString().isNotEmpty)
                                                      Text(
                                                        surah['arabicName'].toString(),
                                                        style: TextStyle(
                                                          fontSize: fontSizeNormal,
                                                          color: isDark ? darkTextColorLight : textColorLight,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '$totalVerses ayat • ${surah['place'] ?? 'Mekkah'}',
                                                      style: TextStyle(
                                                        fontSize: fontSizeSmall,
                                                        color: isDark ? darkTextColorLight : textColorLight,
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
                                                  color: isCompleted
                                                      ? successColor.withOpacity(0.2)
                                                      : (isDark ? primaryColorLight : primaryColor).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(
                                                    borderRadiusSmall,
                                                  ),
                                                ),
                                                child: Text(
                                                  '$currentProgress/$totalVerses',
                                                  style: TextStyle(
                                                    fontSize: fontSizeSmall,
                                                    fontWeight: FontWeight.w600,
                                                    color: isCompleted 
                                                      ? successColor 
                                                      : (isDark ? primaryColorLight : primaryColor),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: paddingMedium),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: LinearProgressIndicator(
                                              value: progressValue,
                                              minHeight: 8,
                                              backgroundColor: isDark ? darkBorderColor : dividerColor,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isCompleted 
                                                  ? successColor 
                                                  : (isDark ? primaryColorLight : primaryColor),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                const SizedBox(height: paddingMedium),

                // INFO BOX - Reading Tips
                if (readingTips.isNotEmpty)
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
                          readingTips['title'] ?? '📖 Tips Membaca',
                          style: TextStyle(
                            fontSize: fontSizeNormal,
                            fontWeight: FontWeight.w600,
                            color: isDark ? darkTextColor : textColor,
                          ),
                        ),
                        const SizedBox(height: paddingSmall),
                        Text(
                          readingTips['description'] ??
                              'Target membaca 2-3 halaman setiap hari untuk menyelesaikan Al-Qur\'an dalam satu bulan.',
                          style: TextStyle(
                            fontSize: fontSizeSmall,
                            color: isDark ? darkTextColorLight : textColorLight,
                            height: 1.5,
                          ),
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
}