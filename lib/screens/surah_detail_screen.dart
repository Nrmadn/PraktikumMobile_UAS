import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../services/quran_api_service.dart';
import '../providers/quran_progress_provider.dart';
import '../providers/theme_provider.dart'; // ⬅️ TAMBAHKAN

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final String surahNameArabic;
  final int totalVerses;

  const SurahDetailScreen({
    Key? key,
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.totalVerses,
  }) : super(key: key);

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic>? surahData;
  
  final ScrollController _scrollController = ScrollController();
  int _currentVisibleAyat = 0;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _loadSurahDetail();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      _updateProgressBasedOnScroll();
      
      if (_scrollController.offset > 500 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 500 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });
  }

  void _updateProgressBasedOnScroll() {
    if (surahData == null) return;

    final verses = surahData!['verses'] as List;
    final scrollPosition = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (maxScroll > 0) {
      final progress = (scrollPosition / maxScroll * verses.length).ceil();
      final newVisibleAyat = progress.clamp(0, verses.length);

      if (newVisibleAyat != _currentVisibleAyat) {
        setState(() => _currentVisibleAyat = newVisibleAyat);
        
        final progressProvider = Provider.of<QuranProgressProvider>(
          context,
          listen: false,
        );
        progressProvider.updateProgress(widget.surahNumber, newVisibleAyat);
      }
    }
  }

  Future<void> _loadSurahDetail() async {
    try {
      final data = await QuranApiService.getSurahByNumber(widget.surahNumber);

      if (mounted) {
        setState(() {
          surahData = data;
          isLoading = false;
        });

        final progressProvider = Provider.of<QuranProgressProvider>(
          context,
          listen: false,
        );
        _currentVisibleAyat = progressProvider.getProgress(widget.surahNumber);
      }
    } catch (e) {
      print('Error loading surah: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showResetConfirmation() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
        title: Text(
          'Reset Progress',
          style: TextStyle(color: isDark ? darkTextColor : textColor),
        ),
        content: Text(
          'Apakah Anda yakin ingin mereset progress membaca ${widget.surahName}?',
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
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final progressProvider = Provider.of<QuranProgressProvider>(
        context,
        listen: false,
      );
      await progressProvider.resetProgress(widget.surahNumber);
      
      setState(() => _currentVisibleAyat = 0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Progress berhasil direset'),
            backgroundColor: successColor,
          ),
        );
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⬅️ GET THEME STATE
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
      appBar: AppBar(
        title: Text(widget.surahName),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Progress',
            onPressed: _showResetConfirmation,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : surahData == null
              ? Center(
                  child: Text(
                    'Gagal memuat data',
                    style: TextStyle(
                      color: isDark ? darkTextColorLight : textColorLight,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        _buildProgressHeader(isDark),
                        
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Padding(
                              padding: const EdgeInsets.all(paddingMedium),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSurahHeader(isDark),

                                  const SizedBox(height: paddingLarge),

                                  if (widget.surahNumber != 9 && 
                                      widget.surahNumber != 1)
                                    _buildBismillah(isDark),

                                  const SizedBox(height: paddingMedium),

                                  if (surahData!['verses'] != null)
                                    ...List.generate(
                                      (surahData!['verses'] as List).length,
                                      (index) {
                                        final ayat = surahData!['verses'][index];
                                        return _buildAyatCard(ayat, index + 1, isDark);
                                      },
                                    ),

                                  const SizedBox(height: paddingXLarge),

                                  if (_currentVisibleAyat >= widget.totalVerses)
                                    _buildCompletionCard(isDark),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_showScrollToTop)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _scrollToTop,
                          backgroundColor: isDark ? primaryColorLight : primaryColor,
                          child: const Icon(Icons.arrow_upward),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildProgressHeader(bool isDark) {
    return Consumer<QuranProgressProvider>(
      builder: (context, progressProvider, child) {
        final progress = progressProvider.getProgress(widget.surahNumber);
        final percentage = progressProvider.getProgressPercentage(
          widget.surahNumber,
          widget.totalVerses,
        );
        final isCompleted = progressProvider.isCompleted(
          widget.surahNumber,
          widget.totalVerses,
        );

        return Container(
          padding: const EdgeInsets.all(paddingMedium),
          decoration: BoxDecoration(
            color: isCompleted 
                ? successColor.withOpacity(0.1) 
                : (isDark ? primaryColorLight : primaryColor).withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: isCompleted ? successColor : (isDark ? primaryColorLight : primaryColor),
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress Membaca',
                        style: TextStyle(
                          fontSize: fontSizeSmall,
                          color: isDark ? darkTextColorLight : textColorLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$progress / ${widget.totalVerses} ayat',
                        style: TextStyle(
                          fontSize: fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: isCompleted 
                            ? successColor 
                            : (isDark ? primaryColorLight : primaryColor),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: paddingMedium,
                      vertical: paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted 
                        ? successColor 
                        : (isDark ? primaryColorLight : primaryColor),
                      borderRadius: BorderRadius.circular(borderRadiusSmall),
                    ),
                    child: Text(
                      isCompleted 
                          ? '✅ Selesai' 
                          : '${(percentage * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: textColorWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSizeSmall,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: paddingSmall),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 10,
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
        );
      },
    );
  }

  Widget _buildSurahHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(paddingLarge),
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
        children: [
          Text(
            widget.surahNameArabic,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColorWhite,
            ),
          ),
          const SizedBox(height: paddingSmall),
          Text(
            widget.surahName,
            style: const TextStyle(
              fontSize: fontSizeLarge,
              color: textColorWhite,
            ),
          ),
          const SizedBox(height: paddingSmall),
          Text(
            '${widget.totalVerses} Ayat • ${surahData!['place'] ?? ''}',
            style: const TextStyle(
              fontSize: fontSizeNormal,
              color: textColorWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillah(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(paddingMedium),
      decoration: BoxDecoration(
        color: (isDark ? primaryColorLight : primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        border: Border.all(
          color: isDark ? primaryColorLight : primaryColor,
        ),
      ),
      child: Center(
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? primaryColorLight : primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAyatCard(Map<String, dynamic> ayat, int ayatNumber, bool isDark) {
    final textData = ayat['text'] as Map<String, dynamic>?;
    final translationData = ayat['translation'] as Map<String, dynamic>?;
    final transliterationData =
        textData?['transliteration'] as Map<String, dynamic>?;

    final isCurrentlyReading = ayatNumber == _currentVisibleAyat;

    return Card(
      margin: const EdgeInsets.only(bottom: paddingMedium),
      elevation: isCurrentlyReading ? 4 : 2,
      color: isCurrentlyReading 
          ? (isDark ? primaryColorLight : primaryColor).withOpacity(0.05)
          : (isDark ? darkCardBackgroundColor : cardBackgroundColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        side: BorderSide(
          color: isDark ? darkBorderColor : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nomor Ayat
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: paddingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isCurrentlyReading 
                  ? (isDark ? primaryColorLight : primaryColorDark)
                  : (isDark ? primaryColorLight : primaryColor),
                borderRadius: BorderRadius.circular(borderRadiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$ayatNumber',
                    style: const TextStyle(
                      color: textColorWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCurrentlyReading) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.visibility,
                      color: textColorWhite,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: paddingMedium),

            // Teks Arab
            Text(
              textData?['arab']?.toString() ?? '',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark ? darkTextColor : textColor,
                height: 2.0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: paddingMedium),

            // Transliterasi
            if (transliterationData?['en'] != null)
              Container(
                padding: const EdgeInsets.all(paddingSmall),
                decoration: BoxDecoration(
                  color: infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(borderRadiusSmall),
                ),
                child: Text(
                  transliterationData!['en'].toString(),
                  style: TextStyle(
                    fontSize: fontSizeNormal,
                    fontStyle: FontStyle.italic,
                    color: isDark ? darkTextColorLight : textColorLight,
                  ),
                ),
              ),

            const SizedBox(height: paddingSmall),

            // Terjemahan Indonesia
            if (translationData?['id'] != null)
              Text(
                translationData!['id'].toString(),
                style: TextStyle(
                  fontSize: fontSizeNormal,
                  color: isDark ? darkTextColor : textColor,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(paddingLarge),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        border: Border.all(color: successColor, width: 2),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: successColor,
            size: 48,
          ),
          const SizedBox(height: paddingMedium),
          const Text(
            'Alhamdulillah! 🎉',
            style: TextStyle(
              fontSize: fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: successColor,
            ),
          ),
          const SizedBox(height: paddingSmall),
          Text(
            'Anda telah menyelesaikan ${widget.surahName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSizeNormal,
              color: isDark ? darkTextColor : textColor,
            ),
          ),
        ],
      ),
    );
  }
}