// Data diambil dari API: https://api.aladhan.com/v1/timingsByCity
// Digunakan untuk: Prayer Time Screen, Home Screen, Notification, dll

class PrayerTime {
  String fajr; 
  String dhuhr; 
  String asr; 
  String maghrib; 
  String isha; 
  DateTime date;
  String? timezone;

  PrayerTime({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    this.timezone,
  });


  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    try {
      final timings = json['timings'] ?? {};
      
      return PrayerTime(
        fajr: timings['Fajr'] ?? '00:00',
        dhuhr: timings['Dhuhr'] ?? '00:00',
        asr: timings['Asr'] ?? '00:00',
        maghrib: timings['Maghrib'] ?? '00:00',
        isha: timings['Isha'] ?? '00:00',
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        timezone: json['timezone'],
      );
    } catch (e) {
      print('Error parsing PrayerTime: $e');
      return PrayerTime(
        fajr: '00:00',
        dhuhr: '00:00',
        asr: '00:00',
        maghrib: '00:00',
        isha: '00:00',
        date: DateTime.now(),
      );
    }
  }

  // Convert dari Object PrayerTime ke JSON
  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'date': date.toIso8601String(),
      'timezone': timezone,
    };
  }

  // Copy With - untuk membuat copy dengan beberapa field berubah
  PrayerTime copyWith({
    String? fajr,
    String? dhuhr,
    String? asr,
    String? maghrib,
    String? isha,
    DateTime? date,
    String? timezone,
  }) {
    return PrayerTime(
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      date: date ?? this.date,
      timezone: timezone ?? this.timezone,
    );
  }

  // Helper Method - Dapatkan semua waktu sholat dalam List
  List<PrayerTimeItem> getAllPrayerTimes() {
    return [
      PrayerTimeItem(name: 'Subuh', time: fajr),
      PrayerTimeItem(name: 'Dhuhur', time: dhuhr),
      PrayerTimeItem(name: 'Ashar', time: asr),
      PrayerTimeItem(name: 'Maghrib', time: maghrib),
      PrayerTimeItem(name: 'Isya', time: isha),
    ];
  }

  // Helper Method - Dapatkan sholat berikutnya
  PrayerTimeItem? getNextPrayerTime() {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final allPrayers = getAllPrayerTimes();

    for (var prayer in allPrayers) {
      if (prayer.time.compareTo(currentTime) > 0) {
        return prayer;
      }
    }

    // Jika semua sholat sudah lewat, return sholat pertama besok (Subuh)
    return allPrayers.first;
  }

  // Helper Method - Hitung selisih waktu sampai sholat berikutnya
  Duration? getTimeUntilNextPrayer() {
    final nextPrayer = getNextPrayerTime();
    if (nextPrayer == null) return null;

    final now = DateTime.now();
    final timeParts = nextPrayer.time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final prayerDateTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (prayerDateTime.isBefore(now)) {
      // Jika sudah lewat hari ini, hitung untuk besok
      return prayerDateTime.add(Duration(days: 1)).difference(now);
    }

    return prayerDateTime.difference(now);
  }

  // Override toString untuk debugging
  @override
  String toString() {
    return 'PrayerTime(Fajr: $fajr, Dhuhr: $dhuhr, Asr: $asr, Maghrib: $maghrib, Isha: $isha, date: $date)';
  }

  // Override == dan hashCode untuk perbandingan object
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerTime &&
          runtimeType == other.runtimeType &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => date.hashCode;
}

// Class ini digunakan untuk represent satu item sholat
// Digunakan untuk getAllPrayerTimes() dan getNextPrayerTime()

class PrayerTimeItem {
  String name; 
  String time; 

  PrayerTimeItem({
    required this.name,
    required this.time,
  });

  @override
  String toString() => 'PrayerTimeItem(name: $name, time: $time)';
}