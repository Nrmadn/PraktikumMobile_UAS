import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_time_model.dart';

/// Service untuk mengambil jadwal sholat dari Aladhan API
/// API Documentation: https://aladhan.com/prayer-times-api
/// 
/// Endpoint yang digunakan:
/// - GET /v1/timingsByCity/:date
/// - Query params: city, country, method
class PrayerApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1';
  
  // Method 20 = Islamic Society of North America (ISNA)
  // Bisa diganti sesuai kebutuhan
  static const int _calculationMethod = 20;

  /// 📅 GET PRAYER TIMES BY CITY (with auto fallback)
  /// 
  /// Parameters:
  /// - city: Nama kota (e.g., "Malang")
  /// - country: Nama negara (e.g., "Indonesia")
  /// - date: Tanggal (optional, default today)
  /// - useFallback: Otomatis gunakan fallback jika API gagal (default: true)
  static Future<PrayerTime?> getPrayerTimesByCity({
    required String city,
    required String country,
    DateTime? date,
    bool useFallback = true,
  }) async {
    try {
      // Format tanggal: DD-MM-YYYY
      final targetDate = date ?? DateTime.now();
      final dateStr = '${targetDate.day.toString().padLeft(2, '0')}-'
          '${targetDate.month.toString().padLeft(2, '0')}-'
          '${targetDate.year}';

      // Build URL
      final url = Uri.parse(
        '$_baseUrl/timingsByCity/$dateStr'
        '?city=$city'
        '&country=$country'
        '&method=$_calculationMethod',
      );

      print('🌐 Fetching prayer times from: $url');

      // Make HTTP Request
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      // Check response status
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        // Check API response code
        if (jsonData['code'] == 200 && jsonData['status'] == 'OK') {
          final data = jsonData['data'];
          
          // Parse timings
          final timings = data['timings'];
          final dateInfo = data['date'];
          
          // Parse date safely - API returns format: DD-MM-YYYY
          DateTime parsedDate;
          try {
            final gregDate = dateInfo['gregorian'];
            final dateStr = gregDate['date'] ?? '';
            // Format: DD-MM-YYYY -> convert to DateTime
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              parsedDate = DateTime(
                int.parse(parts[2]), // year
                int.parse(parts[1]), // month
                int.parse(parts[0]), // day
              );
            } else {
              parsedDate = targetDate;
            }
          } catch (e) {
            print('⚠️ Error parsing date, using target date: $e');
            parsedDate = targetDate;
          }
          
          // Create PrayerTime object
          final prayerTime = PrayerTime(
            fajr: _cleanTime(timings['Fajr']),
            dhuhr: _cleanTime(timings['Dhuhr']),
            asr: _cleanTime(timings['Asr']),
            maghrib: _cleanTime(timings['Maghrib']),
            isha: _cleanTime(timings['Isha']),
            date: parsedDate,
            timezone: data['meta']?['timezone'] ?? 'Asia/Jakarta',
          );

          print('✅ Prayer times fetched successfully from API');
          return prayerTime;
        } else {
          print('❌ API Error: ${jsonData['status']}');
          if (useFallback) return _getFallbackPrayerTimes();
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        if (useFallback) return _getFallbackPrayerTimes();
        return null;
      }
    } catch (e) {
      print('❌ Exception in getPrayerTimesByCity: $e');
      if (useFallback) {
        print('📦 Using fallback prayer times from JSON');
        return _getFallbackPrayerTimes();
      }
      return null;
    }
  }

  /// 📦 FALLBACK: Get prayer times from local JSON
  static Future<PrayerTime?> _getFallbackPrayerTimes() async {
    try {
      // Gunakan waktu sholat default untuk Indonesia
      return PrayerTime(
        fajr: '04:30',
        dhuhr: '12:00',
        asr: '15:15',
        maghrib: '18:00',
        isha: '19:15',
        date: DateTime.now(),
        timezone: 'Asia/Jakarta',
      );
    } catch (e) {
      print('❌ Error in fallback: $e');
      return null;
    }
  }

  /// 📅 GET PRAYER TIMES FOR MULTIPLE DAYS
  static Future<List<PrayerTime>> getPrayerTimesForMonth({
    required String city,
    required String country,
    required int month,
    required int year,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/calendarByCity/$year/$month'
        '?city=$city'
        '&country=$country'
        '&method=$_calculationMethod',
      );

      print('🌐 Fetching monthly prayer times from: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        if (jsonData['code'] == 200) {
          final List<dynamic> monthData = jsonData['data'];
          
          return monthData.map((dayData) {
            final timings = dayData['timings'];
            final dateInfo = dayData['date']['gregorian'];
            
            return PrayerTime(
              fajr: _cleanTime(timings['Fajr']),
              dhuhr: _cleanTime(timings['Dhuhr']),
              asr: _cleanTime(timings['Asr']),
              maghrib: _cleanTime(timings['Maghrib']),
              isha: _cleanTime(timings['Isha']),
              date: DateTime.parse(dateInfo['date']),
              timezone: dayData['meta']['timezone'],
            );
          }).toList();
        }
      }
      
      print('❌ Failed to fetch monthly prayer times');
      return [];
    } catch (e) {
      print('❌ Exception in getPrayerTimesForMonth: $e');
      return [];
    }
  }

  /// 🕌 GET NEXT PRAYER INFO
  /// Returns nama sholat berikutnya dan countdown
  static PrayerTimeItem? getNextPrayer(PrayerTime prayerTime) {
    return prayerTime.getNextPrayerTime();
  }

  /// ⏱️ GET TIME UNTIL NEXT PRAYER
  static Duration? getTimeUntilNextPrayer(PrayerTime prayerTime) {
    return prayerTime.getTimeUntilNextPrayer();
  }

  /// 🧹 HELPER: Clean time format
  /// API returns time with timezone like "04:30 (WIB)"
  /// We only need "04:30"
  static String _cleanTime(String time) {
    // Remove timezone info in parentheses
    return time.split(' ')[0];
  }

  /// 🔄 RETRY MECHANISM
  /// Retry request jika gagal
  static Future<PrayerTime?> getPrayerTimesWithRetry({
    required String city,
    required String country,
    DateTime? date,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      final result = await getPrayerTimesByCity(
        city: city,
        country: country,
        date: date,
      );
      
      if (result != null) {
        return result;
      }
      
      attempt++;
      if (attempt < maxRetries) {
        print('🔄 Retrying... Attempt $attempt');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    print('❌ Failed after $maxRetries attempts');
    return null;
  }

  /// 📍 POPULAR CITIES IN INDONESIA
  static const Map<String, String> popularCities = {
    'Jakarta': 'Indonesia',
    'Surabaya': 'Indonesia',
    'Bandung': 'Indonesia',
    'Medan': 'Indonesia',
    'Semarang': 'Indonesia',
    'Makassar': 'Indonesia',
    'Palembang': 'Indonesia',
    'Tangerang': 'Indonesia',
    'Depok': 'Indonesia',
    'Bekasi': 'Indonesia',
    'Malang': 'Indonesia',
    'Yogyakarta': 'Indonesia',
  };
}