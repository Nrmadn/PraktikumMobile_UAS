import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../providers/theme_provider.dart';
import '../widgets/bottom_navigation.dart';
import '../services/notification_service.dart';

/// SETTING SCREEN - Dark Mode & Notifikasi Only
class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // ========================================
  // 📋 VARIABLES
  // ========================================
  final int selectedNavIndex = 4;
  final NotificationService _notificationService = NotificationService();

  bool prayerNotificationEnabled = true;
  bool motivationNotificationEnabled = true;
  bool isLoading = true;

  static const String _prayerNotifKey = 'prayer_notification_enabled';
  static const String _motivationNotifKey = 'motivation_notification_enabled';
  String selectedCity = 'Malang';
  String selectedCountry = 'Indonesia';

  // Daftar kota yang tersedia
  final List<Map<String, String>> availableCities = [
    {'city': 'Jakarta', 'country': 'Indonesia'},
    {'city': 'Surabaya', 'country': 'Indonesia'},
    {'city': 'Bandung', 'country': 'Indonesia'},
    {'city': 'Malang', 'country': 'Indonesia'},
    {'city': 'Yogyakarta', 'country': 'Indonesia'},
    {'city': 'Semarang', 'country': 'Indonesia'},
    {'city': 'Medan', 'country': 'Indonesia'},
    {'city': 'Makassar', 'country': 'Indonesia'},
  ];

  static const String _cityKey = 'selected_city';
  static const String _countryKey = 'selected_country';

  // ========================================
  // 🔄 LIFECYCLE
  // ========================================
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        prayerNotificationEnabled = prefs.getBool(_prayerNotifKey) ?? true;
        motivationNotificationEnabled =
            prefs.getBool(_motivationNotifKey) ?? true;
        selectedCity = prefs.getString(_cityKey) ?? 'Malang';
        selectedCountry = prefs.getString(_countryKey) ?? 'Indonesia';
        isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveLocationSetting(String city, String country) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cityKey, city);
      await prefs.setString(_countryKey, country);

      setState(() {
        selectedCity = city;
        selectedCountry = country;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Lokasi diubah ke $city'),
            backgroundColor: successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan lokasi'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  void _showCitySelectionDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusNormal),
        ),
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: isDark ? primaryColorLight : primaryColor,
            ),
            const SizedBox(width: paddingSmall),
            Text(
              'Pilih Lokasi',
              style: TextStyle(
                color: isDark ? darkTextColor : textColor,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableCities.length,
            itemBuilder: (context, index) {
              final cityData = availableCities[index];
              final city = cityData['city']!;
              final isSelected = city == selectedCity;

              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isDark ? primaryColorLight : primaryColor,
                ),
                title: Text(
                  city,
                  style: TextStyle(
                    color: isDark ? darkTextColor : textColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedTileColor: (isDark ? primaryColorLight : primaryColor)
                    .withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadiusSmall),
                ),
                onTap: () {
                  _saveLocationSetting(city, cityData['country']!);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? primaryColorLight : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 💾 SAVE SETTINGS & SCHEDULE NOTIFICATIONS
  // ========================================
  Future<void> _savePrayerNotificationSetting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prayerNotifKey, value);

      setState(() {
        prayerNotificationEnabled = value;
      });

      if (value) {
        await _notificationService.scheduleAllNotifications();
      } else {
        await _notificationService.cancelPrayerNotifications();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '✅ Notifikasi Sholat Diaktifkan'
                  : '❌ Notifikasi Sholat Dinonaktifkan',
            ),
            backgroundColor: successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving prayer notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan pengaturan'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveMotivationNotificationSetting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_motivationNotifKey, value);

      setState(() {
        motivationNotificationEnabled = value;
      });

      if (value) {
        await _notificationService.scheduleAllNotifications();
      } else {
        await _notificationService.cancelMotivationNotifications();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '✅ Notifikasi Motivasi Diaktifkan'
                  : '❌ Notifikasi Motivasi Dinonaktifkan',
            ),
            backgroundColor: successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving motivation notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan pengaturan'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  // ========================================
  // 🧪 TEST NOTIFICATION
  // ========================================
  Future<void> _testNotification() async {
    await _notificationService.showTestNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Notifikasi test dikirim!'),
          backgroundColor: successColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ========================================
  // 🎯 NAVIGATION HANDLER
  // ========================================
  void handleNavigation(int index) {
    if (index == selectedNavIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
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
        break;
    }
  }

  void _showAppInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusNormal),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: isDark ? primaryColorLight : primaryColor,
            ),
            const SizedBox(width: paddingSmall),
            Text(
              'Versi Aplikasi',
              style: TextStyle(
                color: isDark ? darkTextColor : textColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('App Name:', 'Muslim Daily Tracker', isDark),
            const SizedBox(height: paddingSmall),
            _buildInfoRow('Version:', '1.0.0', isDark),
            const SizedBox(height: paddingSmall),
            _buildInfoRow('Build:', '001', isDark),
            const SizedBox(height: paddingSmall),
            _buildInfoRow('Release:', 'December 2024', isDark),
            const SizedBox(height: paddingMedium),
            Text(
              'Aplikasi untuk membantu tracking ibadah harian Anda.',
              style: TextStyle(
                fontSize: fontSizeSmall,
                color: isDark ? darkTextColorLight : textColorLight,
                height: 1.5,
              ),
            ),
          ],
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

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: isDark ? darkTextColorLight : textColorLight,
          ),
        ),
        const SizedBox(width: paddingSmall),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSizeSmall,
              color: isDark ? darkTextColor : textColor,
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // 🎨 BUILD UI
  // ========================================
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final isDark = themeProvider.isDarkMode;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========================================
                // 🎨 APPEARANCE SECTION
                // ========================================
                const SizedBox(height: paddingLarge),

// ========================================
// 📍 LOCATION SECTION
// ========================================
                _buildSectionTitle('Lokasi', isDark),
                const SizedBox(height: paddingNormal),

                GestureDetector(
                  onTap: () => _showCitySelectionDialog(context, isDark),
                  child: _buildSettingItem(
                    isDark: isDark,
                    title: 'Lokasi Sholat',
                    subtitle: 'Saat ini: $selectedCity, $selectedCountry',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),

                const SizedBox(height: paddingNormal),

                _buildSectionTitle('Tampilan', isDark),
                const SizedBox(height: paddingNormal),

                _buildSettingItem(
                  isDark: isDark,
                  title: 'Mode Gelap',
                  subtitle: isDark
                      ? 'Kurangi kelelahan mata di malam hari'
                      : 'Aktifkan mode gelap untuk kenyamanan mata',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) async {
                      await themeProvider.toggleTheme();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? '🌙 Mode gelap diaktifkan'
                                  : '☀️ Mode terang diaktifkan',
                            ),
                            backgroundColor: successColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    activeColor: primaryColorLight,
                  ),
                ),

                const SizedBox(height: paddingLarge),

                // ========================================
                // 🔔 NOTIFICATION SECTION
                // ========================================
                _buildSectionTitle('Notifikasi', isDark),
                const SizedBox(height: paddingNormal),

                // Prayer Notification
                _buildSettingItem(
                  isDark: isDark,
                  title: 'Notifikasi Sholat',
                  subtitle: 'Dapatkan notifikasi saat waktu sholat tiba',
                  trailing: Switch(
                    value: prayerNotificationEnabled,
                    onChanged: _savePrayerNotificationSetting,
                    activeColor: primaryColorLight,
                  ),
                ),

                const SizedBox(height: paddingNormal),

                // Motivation Notification
                _buildSettingItem(
                  isDark: isDark,
                  title: 'Notifikasi Motivasi',
                  subtitle: 'Dapatkan pesan motivasi setiap pagi',
                  trailing: Switch(
                    value: motivationNotificationEnabled,
                    onChanged: _saveMotivationNotificationSetting,
                    activeColor: primaryColorLight,
                  ),
                ),

                const SizedBox(height: paddingNormal),

                // Test Notification Button
                ElevatedButton.icon(
                  onPressed: _testNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('🧪 Test Notifikasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? primaryColorLight : primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                    ),
                  ),
                ),

                const SizedBox(height: paddingLarge),

                // ========================================
                // ℹ️ ABOUT SECTION
                // ========================================
                _buildSectionTitle('Tentang', isDark),
                const SizedBox(height: paddingNormal),

                GestureDetector(
                  onTap: () => _showAppInfoDialog(context, isDark),
                  child: _buildSettingItem(
                    isDark: isDark,
                    title: 'Versi Aplikasi',
                    subtitle: 'Version 1.0.0 • Build 001',
                    trailing: const Icon(Icons.info_outline, size: 20),
                  ),
                ),

                const SizedBox(height: paddingNormal),

                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDark
                            ? darkCardBackgroundColor
                            : cardBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(borderRadiusNormal),
                        ),
                        title: Text(
                          'Syarat & Ketentuan',
                          style: TextStyle(
                            color: isDark ? darkTextColor : textColor,
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: Text(
                            'Syarat dan ketentuan penggunaan aplikasi akan ditampilkan di sini.\n\n'
                            '1. Pengguna wajib menggunakan aplikasi dengan bijak\n'
                            '2. Data pribadi akan dijaga kerahasiaannya\n'
                            '3. Aplikasi ini gratis dan tanpa iklan\n\n'
                            'Fitur lengkap akan tersedia di versi mendatang.',
                            style: TextStyle(
                              fontSize: fontSizeSmall,
                              color:
                                  isDark ? darkTextColorLight : textColorLight,
                              height: 1.5,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Tutup',
                              style: TextStyle(
                                color:
                                    isDark ? primaryColorLight : primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: _buildSettingItem(
                    isDark: isDark,
                    title: 'Syarat & Ketentuan',
                    subtitle: 'Baca syarat dan ketentuan',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),

                const SizedBox(height: paddingNormal),

                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDark
                            ? darkCardBackgroundColor
                            : cardBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(borderRadiusNormal),
                        ),
                        title: Text(
                          'Kebijakan Privasi',
                          style: TextStyle(
                            color: isDark ? darkTextColor : textColor,
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: Text(
                            'Kebijakan privasi aplikasi:\n\n'
                            '1. Kami tidak mengumpulkan data pribadi Anda\n'
                            '2. Semua data tersimpan lokal di perangkat\n'
                            '3. Tidak ada tracking atau analytics\n'
                            '4. Aplikasi tidak memerlukan koneksi internet\n\n'
                            'Privasi Anda adalah prioritas kami.',
                            style: TextStyle(
                              fontSize: fontSizeSmall,
                              color:
                                  isDark ? darkTextColorLight : textColorLight,
                              height: 1.5,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Tutup',
                              style: TextStyle(
                                color:
                                    isDark ? primaryColorLight : primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: _buildSettingItem(
                    isDark: isDark,
                    title: 'Kebijakan Privasi',
                    subtitle: 'Baca kebijakan privasi',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),

                const SizedBox(height: paddingLarge),

                // ========================================
                // 💡 INFO BOX
                // ========================================
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
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: infoColor,
                            size: 20,
                          ),
                          const SizedBox(width: paddingSmall),
                          Text(
                            'Tips Pengaturan',
                            style: TextStyle(
                              fontSize: fontSizeNormal,
                              fontWeight: FontWeight.w600,
                              color: isDark ? darkTextColor : textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: paddingSmall),
                      Text(
                        '• Ubah lokasi anda sesuai lokasi anda saat ini\n'
                        '• Aktifkan notifikasi sholat untuk pengingat waktu sholat\n'
                        '• Mode gelap lebih hemat baterai\n'
                        '• Gunakan tombol Test Notifikasi untuk cek apakah berfungsi\n'
                        '• Semua pengaturan tersimpan otomatis',
                        style: TextStyle(
                          fontSize: fontSizeSmall,
                          height: 1.5,
                          color: isDark ? darkTextColorLight : textColorLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: paddingLarge),

                // ========================================
                // 📱 BUILD INFO
                // ========================================
                Container(
                  padding: const EdgeInsets.all(paddingMedium),
                  decoration: BoxDecoration(
                    color: isDark ? darkSurfaceColor : dividerColor,
                    borderRadius: BorderRadius.circular(borderRadiusNormal),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Muslim Daily Tracker',
                          style: TextStyle(
                            fontSize: fontSizeNormal,
                            fontWeight: FontWeight.w600,
                            color: isDark ? darkTextColor : textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Build 001 • © 2024',
                          style: TextStyle(
                            fontSize: fontSizeSmall,
                            color: isDark ? darkTextColorLight : textColorLight,
                          ),
                        ),
                      ],
                    ),
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

  // ========================================
  // 🛠️ HELPER WIDGETS
  // ========================================

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSizeLarge,
        fontWeight: FontWeight.w600,
        color: isDark ? primaryColorLight : primaryColor,
      ),
    );
  }

  Widget _buildSettingItem({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? darkCardBackgroundColor : cardBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        border: Border.all(
          color: isDark ? darkBorderColor : borderColor,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSizeNormal,
                    fontWeight: FontWeight.w600,
                    color: isDark ? darkTextColor : textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: fontSizeSmall,
                    color: isDark ? darkTextColorLight : textColorLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: paddingMedium),
          trailing,
        ],
      ),
    );
  }
}
