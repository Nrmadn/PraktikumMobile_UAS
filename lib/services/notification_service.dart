import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

/// SERVICE NOTIFIKASI SIMPEL
/// Fitur: Notifikasi Motivasi 4x/hari + Notifikasi Sholat 5x/hari
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // SharedPreferences keys (sama dengan di SettingScreen)
  static const String _prayerNotifKey = 'prayer_notification_enabled';
  static const String _motivationNotifKey = 'motivation_notification_enabled';

  // ========================================
  // 🚀 INITIALIZE NOTIFICATION
  // ========================================
  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permission for Android 13+
    await _requestPermissions();
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Bisa tambahkan navigasi ke screen tertentu kalau perlu
  }

  // ========================================
  // 📅 SCHEDULE SEMUA NOTIFIKASI
  // ========================================
  Future<void> scheduleAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final prayerEnabled = prefs.getBool(_prayerNotifKey) ?? true;
    final motivationEnabled = prefs.getBool(_motivationNotifKey) ?? true;

    // Cancel semua notifikasi dulu
    await cancelAllNotifications();

    // Schedule ulang kalau enabled
    if (motivationEnabled) {
      await _scheduleMotivationNotifications();
    }

    if (prayerEnabled) {
      await _schedulePrayerNotifications();
    }

    print('✅ Notifikasi berhasil dijadwalkan!');
  }

  // ========================================
  // 💬 NOTIFIKASI MOTIVASI (4x sehari)
  // ========================================
  Future<void> _scheduleMotivationNotifications() async {
    final List<Map<String, dynamic>> motivations = [
      {
        'id': 100,
        'hour': 6,
        'minute': 0,
        'title': '🌅 Selamat Pagi!',
        'body': 'Semangat beribadah hari ini! Mulai dengan sholat Subuh 💪',
      },
      {
        'id': 101,
        'hour': 12,
        'minute': 0,
        'title': '☀️ Selamat Siang!',
        'body': 'Jangan lupa istirahat dan sholat Dzuhur ya 🕌',
      },
      {
        'id': 102,
        'hour': 15,
        'minute': 30,
        'title': '🌤️ Selamat Sore!',
        'body': 'Waktunya sholat Ashar. Semangat terus! 🤲',
      },
      {
        'id': 103,
        'hour': 20,
        'minute': 0,
        'title': '🌙 Selamat Malam!',
        'body': 'Jangan lupa sholat Isya sebelum tidur. Istirahat yang cukup ya 😴',
      },
    ];

    for (var motivation in motivations) {
      await _scheduleDailyNotification(
        id: motivation['id'],
        hour: motivation['hour'],
        minute: motivation['minute'],
        title: motivation['title'],
        body: motivation['body'],
      );
    }
  }

  // ========================================
  // 🕌 NOTIFIKASI SHOLAT (5x sehari)
  // ========================================
  Future<void> _schedulePrayerNotifications() async {
    // Jadwal sholat contoh (kamu bisa ambil dari API atau database)
    // Ini jadwal untuk Surabaya (sesuaikan dengan lokasi user)
    final List<Map<String, dynamic>> prayers = [
      {
        'id': 1,
        'hour': 4,
        'minute': 30,
        'title': '🌄 Waktu Sholat Subuh',
        'body': 'Saatnya bangun dan sholat Subuh. Jangan sampai terlewat! 🕌',
      },
      {
        'id': 2,
        'hour': 11,
        'minute': 50,
        'title': '☀️ Waktu Sholat Dzuhur',
        'body': 'Waktunya sholat Dzuhur telah tiba. Yuk istirahat sejenak 🙏',
      },
      {
        'id': 3,
        'hour': 15,
        'minute': 10,
        'title': '🌤️ Waktu Sholat Ashar',
        'body': 'Jangan lupa sholat Ashar. Semangat! 💪',
      },
      {
        'id': 4,
        'hour': 17,
        'minute': 50,
        'title': '🌅 Waktu Sholat Maghrib',
        'body': 'Waktu Maghrib telah tiba. Ayo segera sholat 🤲',
      },
      {
        'id': 5,
        'hour': 19,
        'minute': 10,
        'title': '🌙 Waktu Sholat Isya',
        'body': 'Jangan lewatkan sholat Isya malam ini 🕌',
      },
    ];

    for (var prayer in prayers) {
      await _scheduleDailyNotification(
        id: prayer['id'],
        hour: prayer['hour'],
        minute: prayer['minute'],
        title: prayer['title'],
        body: prayer['body'],
      );
    }
  }

  // ========================================
  // 🔔 SCHEDULE DAILY NOTIFICATION
  // ========================================
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notification_channel_$id',
          'Daily Notifications',
          channelDescription: 'Daily prayer and motivation reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true, // Pakai default system sound
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Get next instance of time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Kalau waktunya sudah lewat hari ini, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // ========================================
  // 🗑️ CANCEL NOTIFICATIONS
  // ========================================
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ Semua notifikasi dibatalkan');
  }

  Future<void> cancelMotivationNotifications() async {
    // Cancel IDs 100-103 (motivation)
    for (int i = 100; i <= 103; i++) {
      await _notifications.cancel(i);
    }
    print('🗑️ Notifikasi motivasi dibatalkan');
  }

  Future<void> cancelPrayerNotifications() async {
    // Cancel IDs 1-5 (prayer)
    for (int i = 1; i <= 5; i++) {
      await _notifications.cancel(i);
    }
    print('🗑️ Notifikasi sholat dibatalkan');
  }

  // ========================================
  // 🧪 TEST NOTIFICATION (untuk testing)
  // ========================================
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '🧪 Test Notifikasi',
      'Notifikasi berhasil berfungsi! ✅',
      details,
    );
  }
}