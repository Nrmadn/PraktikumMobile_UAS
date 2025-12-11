import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service untuk mengambil data Al-Qur'an dari Quran API Gading Dev
/// API Documentation: https://github.com/gadingnst/quran-api
///
/// Features:
/// - Daftar semua surah (114 surah)
/// - Detail surah dengan terjemahan Indonesia & tafsir
/// - Ayat per ayat dengan audio
/// - Simple & fast API
class QuranApiService {
  static const String _baseUrl = 'https://api.quran.gading.dev';

  /// 📖 GET ALL SURAH LIST (with auto fallback)
  /// Returns list of 114 surah dengan info dasar
  static Future<List<Map<String, dynamic>>> getAllSurah({
    bool useFallback = true,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/surah');

      print('🌐 Fetching surah list from: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          final List<dynamic> surahList = jsonData['data'];

          print('✅ Fetched ${surahList.length} surah from API');

          return surahList.map((surah) {
            return {
              'number': surah['number'] ?? 0,
              'name': surah['name']?['transliteration']?['id'] ?? 'Unknown',
              'nameArabic': surah['name']?['short'] ?? '',
              'translation': surah['name']?['translation']?['id'] ?? '',
              'totalVerses': surah['numberOfVerses'] ?? 0,
              'place': surah['revelation']?['id'] ?? 'Mekkah',
              'type': surah['revelation']?['id']?.toLowerCase() ?? 'mekah',
            };
          }).toList();
        }
      }

      print('❌ Failed to fetch surah list from API');
      if (useFallback) {
        print('📦 Using fallback surah list');
        return _getFallbackSurahList();
      }
      return [];
    } catch (e) {
      print('❌ Exception in getAllSurah: $e');
      if (useFallback) {
        print('📦 Using fallback surah list');
        return _getFallbackSurahList();
      }
      return [];
    }
  }

  /// 📦 FALLBACK: Basic surah list
  static List<Map<String, dynamic>> _getFallbackSurahList() {
    return List.generate(114, (index) {
      final number = index + 1;
      return {
        'number': number,
        'name': 'Surah $number',
        'nameArabic': '',
        'translation': 'Loading...',
        'totalVerses': 0,
        'place': 'Mekkah',
        'type': 'mekah',
      };
    });
  }

  /// 📖 GET SURAH BY NUMBER
  /// Returns detail surah dengan semua ayat + terjemahan
  static Future<Map<String, dynamic>?> getSurahByNumber(int number) async {
    try {
      if (number < 1 || number > 114) {
        print('❌ Invalid surah number: $number');
        return null;
      }

      final url = Uri.parse('$_baseUrl/surah/$number');

      print('🌐 Fetching surah $number from: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          final surahData = jsonData['data'];

          if (!surahData.containsKey('verses')) {
            print('❌ Field "verses" not found!');
            return null;
          }

          final List<dynamic> versesList = surahData['verses'] as List<dynamic>;

          // ✅ PARSING VERSES - sesuai struktur API gading.dev
          final verses = versesList.map((verse) {
            final verseMap = verse as Map<String, dynamic>;

            return {
              'number': verseMap['number']?['inSurah'] ?? 0,
              'text': {
                'arab': verseMap['text']?['arab'] ?? '',
                'transliteration': {
                  'en': verseMap['text']?['transliteration']?['en'] ?? '',
                },
              },
              'translation': {'id': verseMap['translation']?['id'] ?? ''},
              'audio': {'primary': verseMap['audio']?['primary'] ?? ''},
            };
          }).toList();

          print(
            '✅ Fetched ${surahData['name']?['transliteration']?['id']} with ${verses.length} verses',
          );

          return {
            'number': surahData['number'] ?? 0,
            'name': surahData['name']?['transliteration']?['id'] ?? '',
            'nameArabic': surahData['name']?['short'] ?? '',
            'translation': surahData['name']?['translation']?['id'] ?? '',
            'totalVerses': surahData['numberOfVerses'] ?? 0,
            'place': surahData['revelation']?['id'] ?? 'Mekkah',
            'type': (surahData['revelation']?['id'] ?? 'Makkiyyah').toString(),
            'verses': verses,
          };
        }
      }

      print('❌ Failed to fetch surah $number');
      return null;
    } catch (e, stackTrace) {
      print('❌ Exception in getSurahByNumber: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// 📖 GET SINGLE AYAT
  /// Get ayat tertentu dari surah
  static Future<Map<String, dynamic>?> getAyat({
    required int surahNumber,
    required int ayatNumber,
  }) async {
    try {
      final surahData = await getSurahByNumber(surahNumber);

      if (surahData == null) return null;

      final List<dynamic> verses = surahData['verses'];

      if (ayatNumber < 1 || ayatNumber > verses.length) {
        print('❌ Invalid ayat number: $ayatNumber');
        return null;
      }

      return verses[ayatNumber - 1];
    } catch (e) {
      print('❌ Exception in getAyat: $e');
      return null;
    }
  }

  /// 🔍 SEARCH SURAH BY NAME
  /// Cari surah berdasarkan nama (case-insensitive)
  static Future<List<Map<String, dynamic>>> searchSurah(String query) async {
    try {
      final allSurah = await getAllSurah();

      if (query.isEmpty) return allSurah;

      final lowerQuery = query.toLowerCase();

      return allSurah.where((surah) {
        final name = surah['name'].toString().toLowerCase();
        final translation = surah['translation'].toString().toLowerCase();
        return name.contains(lowerQuery) || translation.contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('❌ Exception in searchSurah: $e');
      return [];
    }
  }

  /// 📊 GET READING STATISTICS
  /// Helper untuk track progress baca Al-Qur'an
  static Map<String, dynamic> getReadingStatistics({
    required List<int> completedSurah,
  }) {
    const totalSurah = 114;
    const totalAyat = 6236; // Total ayat dalam Al-Qur'an

    final completedCount = completedSurah.length;
    final percentage = (completedCount / totalSurah * 100).toStringAsFixed(1);

    return {
      'totalSurah': totalSurah,
      'completedSurah': completedCount,
      'remainingSurah': totalSurah - completedCount,
      'percentage': percentage,
      'totalAyat': totalAyat,
    };
  }

  /// 🎯 GET POPULAR SURAH
  /// Surah yang sering dibaca
  static const List<Map<String, dynamic>> popularSurah = [
    {'number': 1, 'name': 'Al-Fatihah', 'reason': 'Pembuka Al-Qur\'an'},
    {'number': 36, 'name': 'Yasin', 'reason': 'Jantungnya Al-Qur\'an'},
    {'number': 18, 'name': 'Al-Kahfi', 'reason': 'Dibaca hari Jumat'},
    {'number': 56, 'name': 'Al-Waqi\'ah', 'reason': 'Surah Rezeki'},
    {'number': 67, 'name': 'Al-Mulk', 'reason': 'Penyelamat dari siksa kubur'},
    {'number': 2, 'name': 'Al-Baqarah', 'reason': 'Surah terpanjang'},
  ];

  /// 🌙 GET JUZ LIST
  /// Info 30 juz dalam Al-Qur'an
  static const List<Map<String, dynamic>> juzInfo = [
    {'juz': 1, 'startSurah': 1, 'endSurah': 2, 'startAyat': 1, 'endAyat': 141},
    {
      'juz': 2,
      'startSurah': 2,
      'endSurah': 2,
      'startAyat': 142,
      'endAyat': 252,
    },
    {'juz': 3, 'startSurah': 2, 'endSurah': 3, 'startAyat': 253, 'endAyat': 92},
    // ... dst sampai juz 30
  ];
}
