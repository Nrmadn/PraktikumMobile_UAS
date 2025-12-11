import 'package:flutter/material.dart';

/// Translations untuk semua screens - Bahasa Indonesia Only
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // ========================================
  // GENERAL
  // ========================================
  String get appName => 'Muslim Daily Tracker';
  String get appDescription => 'Aplikasi untuk membantu tracking ibadah harian Muslim';
  String get loading => 'Memuat...';
  String get refresh => 'Muat Ulang';
  String get search => 'Cari';
  String get close => 'Tutup';
  String get ok => 'OK';
  String get yes => 'Ya';
  String get no => 'Tidak';

  // ========================================
  // NAVIGATION
  // ========================================
  String get home => 'Beranda';
  String get progress => 'Progress';
  String get schedule => 'Jadwal';
  String get profile => 'Profil';
  String get settings => 'Pengaturan';

  // ========================================
  // HOME SCREEN
  // ========================================
  String get greetingMorning => 'Selamat Pagi';
  String get greetingAfternoon => 'Selamat Siang';
  String get greetingEvening => 'Selamat Sore';
  String get greetingNight => 'Selamat Malam';
  String get todaySchedule => 'Jadwal Hari Ini';
  String get prayerTimes => 'Waktu Sholat';
  String get quickActions => 'Aksi Cepat';
  String get dailyQuote => 'Quotes Harian';
  String get viewAll => 'Lihat Semua';
  String get noScheduleToday => 'Tidak ada jadwal hari ini';
  String get viewDetail => 'Lihat Detail';
  String get manageTargets => 'Kelola Target';
  String get addTarget => 'Tambah Target';
  String get todayTargets => 'Target Hari Ini';
  String get noTargetsToday => 'Tidak ada target untuk hari ini';
  String get targetCompleted => '✅ Target diselesaikan!';
  String get targetCancelled => 'Target dibatalkan';
  String get allTargetsCompleted => 'Luar biasa! Semua target hari ini selesai! 🎉';
  String get targetsOf => 'dari';
  String get targetsCompleted => 'target selesai';
  String get prayerScheduleNotAvailable => 'Jadwal sholat tidak tersedia';
  String get nextPrayerIn => 'Sholat Berikutnya:';
  String get categoriesLabel => 'Kategori';
  String get categoriesNotAvailable => 'Kategori tidak tersedia';
  String get failedToLoadData => 'Gagal memuat data:';
  String get failedToUpdateTarget => 'Gagal mengupdate target:';

  // ========================================
  // PRAYER NAMES
  // ========================================
  String get fajr => 'Subuh';
  String get dhuhr => 'Dzuhur';
  String get asr => 'Ashar';
  String get maghrib => 'Maghrib';
  String get isha => 'Isya';
  String get sunrise => 'Terbit';
  String get nextPrayer => 'Sholat Berikutnya';

  // ========================================
  // PROGRESS SCREEN
  // ========================================
  String get yourProgress => 'Progress Anda';
  String get dailyTarget => 'Target Harian';
  String get weeklyStats => 'Statistik Mingguan';
  String get monthlyStats => 'Statistik Bulanan';
  String get completed => 'Selesai';
  String get remaining => 'Tersisa';
  String get todayProgress => 'Progress Hari Ini';
  String get prayersCompleted => 'Sholat Selesai';
  String get quranRead => 'Baca Quran';
  String get dhikrCount => 'Jumlah Dzikir';
  String get streak => 'Streak';
  String get days => 'Hari';
  String get keepItUp => 'Pertahankan!';
  String get progressTitle => 'Progress & Statistik';
  String get refreshData => 'Refresh Data';
  String get consistentWorship => 'Ibadah Konsisten';
  String get dayStreak => 'hari streak';
  String get progressNextLevel => 'Progress ke Level Berikutnya:';
  String get consecutiveDays => 'Hari Berturut-turut! 🔥';
  String get best => 'Terbaik:';
  String get progress7Days => 'Progress 7 Hari Terakhir';
  String get average => 'Rata-rata:';
  String get categoryStats => 'Statistik Per Kategori';
  String get achievements => 'Pencapaian';
  String get unlocked => 'terbuka';
  String get unlockedDate => 'Didapat:';
  String get motivationToday => '💪 Motivasi Hari Ini:';
  String get keepSpirit => 'Terus semangat menjalankan ibadah!';
  String get aboutPointsLevel => 'Tentang Poin & Level';
  String get howToGetPoints => 'Cara Mendapat Poin:';
  String get completeTarget => 'Selesaikan target: +10 poin';
  String get completeAllToday => 'Selesaikan semua target hari ini: +50 poin';
  String get streak7Days => 'Streak 7 hari: +100 poin';
  String get unlockAchievement => 'Unlock achievement: +50 poin';
  String get levelSystem => 'Level:';
  String get level1 => 'Level 1: 0-500 poin';
  String get level2 => 'Level 2: 500-1500 poin';
  String get level3 => 'Level 3: 1500-3000 poin';
  String get level4 => 'Level 4: 3000-5000 poin';
  String get level5 => 'Level 5: 5000+ poin';
  String get dayConsecutive => 'Hari Berturut-turut! 🔥';

  // ========================================
  // SCHEDULE SCREEN
  // ========================================
  String get todaysSchedule => 'Jadwal Hari Ini';
  String get upcoming => 'Akan Datang';
  String get completedTasks => 'Tugas Selesai';
  String get addSchedule => 'Tambah Jadwal';
  String get editSchedule => 'Edit Jadwal';
  String get deleteSchedule => 'Hapus Jadwal';
  String get markAsComplete => 'Tandai Selesai';
  String get scheduleTime => 'Waktu Jadwal';
  String get scheduleDescription => 'Deskripsi Jadwal';
  String get noSchedules => 'Belum ada jadwal';

  // ========================================
  // PROFILE
  // ========================================
  String get profileTitle => 'Profil Saya';
  String get editProfile => 'Edit Profil';
  String get changePassword => 'Ubah Password';
  String get logout => 'Keluar';
  String get logoutConfirm => 'Apakah Anda yakin ingin keluar dari aplikasi?';
  String get achievement => 'Pencapaian';
  String get level => 'Level';
  String get points => 'Poin';
  String get memberSince => 'Bergabung Sejak';
  String get statistics => 'Statistik';

  // ========================================
  // SETTINGS
  // ========================================
  String get settingTitle => 'Pengaturan';
  String get appearance => 'Tampilan';
  String get darkMode => 'Mode Gelap';
  String get darkModeDesc => 'Kurangi kelelahan mata di malam hari';
  String get lightModeDesc => 'Aktifkan mode gelap untuk kenyamanan mata';
  String get notifications => 'Notifikasi';
  String get prayerNotification => 'Notifikasi Sholat';
  String get prayerNotificationDesc => 'Dapatkan notifikasi saat waktu sholat tiba';
  String get motivationNotification => 'Notifikasi Motivasi';
  String get motivationNotificationDesc => 'Dapatkan pesan motivasi setiap pagi';
  String get language => 'Bahasa';
  String get about => 'Tentang';
  String get appVersion => 'Versi Aplikasi';
  String get termsAndConditions => 'Syarat & Ketentuan';
  String get privacyPolicy => 'Kebijakan Privasi';

  // ========================================
  // FORM
  // ========================================
  String get save => 'Simpan';
  String get cancel => 'Batal';
  String get delete => 'Hapus';
  String get edit => 'Edit';
  String get add => 'Tambah';
  String get fullName => 'Nama Lengkap';
  String get email => 'Email';
  String get password => 'Password';
  String get oldPassword => 'Password Lama';
  String get newPassword => 'Password Baru';
  String get confirmPassword => 'Konfirmasi Password Baru';
  String get title => 'Judul';
  String get description => 'Deskripsi';
  String get date => 'Tanggal';
  String get time => 'Waktu';

  // ========================================
  // AUTH SCREEN
  // ========================================
  String get login => 'Masuk';
  String get register => 'Daftar';
  String get welcomeBack => 'Selamat Datang Kembali';
  String get createAccount => 'Buat Akun Baru';
  String get forgotPassword => 'Lupa Password?';
  String get dontHaveAccount => 'Belum punya akun?';
  String get alreadyHaveAccount => 'Sudah punya akun?';
  String get signInWith => 'Masuk dengan';

  // ========================================
  // MESSAGES
  // ========================================
  String get darkModeEnabled => '🌙 Mode gelap diaktifkan';
  String get lightModeEnabled => '☀️ Mode terang diaktifkan';
  String get profileUpdated => '✅ Profil berhasil diperbarui';
  String get passwordChanged => '✅ Password berhasil diubah';
  String get logoutSuccess => 'Anda berhasil keluar';
  String get languageChanged => 'Bahasa diubah menjadi';
  String get scheduleAdded => '✅ Jadwal berhasil ditambahkan';
  String get scheduleUpdated => '✅ Jadwal berhasil diperbarui';
  String get scheduleDeleted => '✅ Jadwal berhasil dihapus';
  String get taskCompleted => '✅ Tugas berhasil diselesaikan';

  // ========================================
  // ERRORS
  // ========================================
  String get error => 'Error';
  String get nameRequired => 'Nama tidak boleh kosong';
  String get emailRequired => 'Email tidak boleh kosong';
  String get emailInvalid => 'Email tidak valid';
  String get passwordRequired => 'Password tidak boleh kosong';
  String get passwordMismatch => 'Konfirmasi password tidak cocok';
  String get passwordTooShort => 'Password baru minimal 6 karakter';
  String get oldPasswordWrong => 'Password lama tidak sesuai';
  String get titleRequired => 'Judul tidak boleh kosong';
  String get descriptionRequired => 'Deskripsi tidak boleh kosong';
  String get somethingWentWrong => 'Terjadi kesalahan. Silakan coba lagi.';
}

// Delegate untuk localization
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'id';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}