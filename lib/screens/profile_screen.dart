import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/bottom_navigation.dart';
import '../services/target_service.dart';
import '../services/firebase/firebase_target_service.dart'; // ✅ TAMBAH INI
import '../services/firebase/firebase_auth_service.dart'; // ✅ TAMBAH INI

// Halaman menampilkan data profil pengguna dari SharedPreferences
// ✅ SUDAH SUPPORT DARK MODE + EDIT PROFILE + CHANGE PASSWORD

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  //  VARIABLES
  final int selectedNavIndex = 3; // Profile
  bool isLoading = true;

  // Data user yang akan diisi dari SharedPreferences
  String userName = 'User';
  String userEmail = 'user@example.com';
  int userLevel = 1;
  int userPoints = 0;
  int completedTargetsToday = 0;
  int totalTargetsToday = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ✅ LOAD USER DATA + TARGET DATA
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      // Load user info dari SharedPreferences
      setState(() {
        userName = prefs.getString('userName') ?? 'User';
        userEmail = prefs.getString('userEmail') ?? 'user@example.com';
        userLevel = prefs.getInt('userLevel') ?? 1;
        userPoints = prefs.getInt('userPoints') ?? 0;
      });

      // ✅ LOAD TARGET DATA DARI FIREBASE
      if (userId.isNotEmpty) {
        print('🔵 Loading targets for user: $userId');

        // Get today's targets dari Firebase
        final todayTargets = await FirebaseTargetService.getTargetsByDate(
          userId: userId,
          date: DateTime.now(),
        );

        print('🔵 Loaded ${todayTargets.length} targets from Firebase');

        setState(() {
          totalTargetsToday = todayTargets.length;
          completedTargetsToday =
              todayTargets.where((t) => t.isCompleted).length;
          isLoading = false;
        });

        print(
            '✅ Profile data loaded: $completedTargetsToday/$totalTargetsToday completed');
      } else {
        print('⚠️ No user ID found');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading user data: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        isLoading = false;
      });
    }
  }

  // ✅ TAMBAHKAN METHOD REFRESH
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _loadUserData();
  }

  //  HANDLE NAVIGATION
  void handleNavigation(int index) {
    if (index == selectedNavIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home').then((_) {
          _refreshData(); // Refresh ketika kembali
        });
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/progress').then((_) {
          _refreshData();
        });
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/progress_home').then((_) {
          _refreshData();
        });
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/setting').then((_) {
          _refreshData();
        });
        break;
    }
  }

  // ========================================
  // ✅ EDIT PROFILE DIALOG
  // ========================================
  void _showEditProfileDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController nameController = TextEditingController(
      text: userName,
    );
    final TextEditingController emailController = TextEditingController(
      text: userEmail,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
        title: Text(
          'Edit Profil',
          style: TextStyle(
            color: isDark ? darkTextColor : textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Field
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? darkTextColor : textColor),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  labelStyle: TextStyle(
                    color: isDark ? darkTextColorLight : textColorLight,
                  ),
                  prefixIcon: Icon(
                    Icons.person,
                    color: isDark ? primaryColorLight : primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadiusNormal),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadiusNormal),
                    borderSide: BorderSide(
                      color: isDark ? darkBorderColor : borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadiusNormal),
                    borderSide: BorderSide(
                      color: isDark ? primaryColorLight : primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: paddingMedium),

              // Email Field
              TextField(
                controller: emailController,
                style: TextStyle(color: isDark ? darkTextColor : textColor),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: isDark ? darkTextColorLight : textColorLight,
                  ),
                  prefixIcon: Icon(
                    Icons.email,
                    color: isDark ? primaryColorLight : primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadiusNormal),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadiusNormal),
                    borderSide: BorderSide(
                      color: isDark ? darkBorderColor : borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadiusNormal),
                    borderSide: BorderSide(
                      color: isDark ? primaryColorLight : primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? darkTextColorLight : textColorLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();

              // Validation
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama tidak boleh kosong'),
                    backgroundColor: errorColor,
                  ),
                );
                return;
              }

              if (newEmail.isEmpty || !newEmail.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email tidak valid'),
                    backgroundColor: errorColor,
                  ),
                );
                return;
              }

              // Save to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userName', newName);
              await prefs.setString('userEmail', newEmail);

              // Update UI
              setState(() {
                userName = newName;
                userEmail = newEmail;
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Profil berhasil diperbarui'),
                  backgroundColor: successColor,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? primaryColorLight : primaryColor,
              foregroundColor: textColorWhite,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ✅ CHANGE PASSWORD DIALOG
  // ========================================
  void _showChangePasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    bool obscureOldPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor:
              isDark ? darkCardBackgroundColor : cardBackgroundColor,
          title: Text(
            'Ubah Password',
            style: TextStyle(
              color: isDark ? darkTextColor : textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Old Password Field
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOldPassword,
                  style: TextStyle(color: isDark ? darkTextColor : textColor),
                  decoration: InputDecoration(
                    labelText: 'Password Lama',
                    labelStyle: TextStyle(
                      color: isDark ? darkTextColorLight : textColorLight,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDark ? primaryColorLight : primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOldPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? darkTextColorLight : textColorLight,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureOldPassword = !obscureOldPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? darkBorderColor : borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? primaryColorLight : primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: paddingMedium),

                // New Password Field
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  style: TextStyle(color: isDark ? darkTextColor : textColor),
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    labelStyle: TextStyle(
                      color: isDark ? darkTextColorLight : textColorLight,
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: isDark ? primaryColorLight : primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? darkTextColorLight : textColorLight,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? darkBorderColor : borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? primaryColorLight : primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: paddingMedium),

                // Confirm Password Field
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  style: TextStyle(color: isDark ? darkTextColor : textColor),
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    labelStyle: TextStyle(
                      color: isDark ? darkTextColorLight : textColorLight,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_clock,
                      color: isDark ? primaryColorLight : primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? darkTextColorLight : textColorLight,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? darkBorderColor : borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? primaryColorLight : primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: isDark ? darkTextColorLight : textColorLight,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final oldPassword = oldPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                // Validation
                if (oldPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password lama tidak boleh kosong'),
                      backgroundColor: errorColor,
                    ),
                  );
                  return;
                }

                // Check old password
                final prefs = await SharedPreferences.getInstance();
                final savedPassword = prefs.getString('userPassword') ?? '';

                if (savedPassword.isNotEmpty && oldPassword != savedPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password lama tidak sesuai'),
                      backgroundColor: errorColor,
                    ),
                  );
                  return;
                }

                if (newPassword.isEmpty || newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password baru minimal 6 karakter'),
                      backgroundColor: errorColor,
                    ),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Konfirmasi password tidak cocok'),
                      backgroundColor: errorColor,
                    ),
                  );
                  return;
                }

                // Save new password
                await prefs.setString('userPassword', newPassword);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Password berhasil diubah'),
                    backgroundColor: successColor,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? primaryColorLight : primaryColor,
                foregroundColor: textColorWhite,
              ),
              child: const Text('Ubah Password'),
            ),
          ],
        ),
      ),
    );
  }

  //  HANDLE LOGOUT
  void handleLogout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
        title: Text(
          'Keluar?',
          style: TextStyle(color: isDark ? darkTextColor : textColor),
        ),
        content: Text(
          logoutConfirm,
          style: TextStyle(color: isDark ? darkTextColorLight : textColorLight),
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
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.remove('userEmail');
              await prefs.remove('userName');
              await prefs.remove('userLevel');
              await prefs.remove('userPoints');

              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Anda berhasil keluar'),
                  backgroundColor: successColor,
                  duration: Duration(seconds: 2),
                ),
              );

              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Keluar', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text(profileTitle)),
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(profileTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                //  PROFILE HEADER
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    // ✅ Gradient berbeda untuk dark mode
                    gradient: LinearGradient(
                      colors: isDark
                          ? [darkSurfaceColor, darkCardBackgroundColor]
                          : [primaryColor, primaryColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    // ✅ Tambahkan border di dark mode
                    border: isDark
                        ? Border(
                            bottom: BorderSide(
                              color: darkBorderColor,
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: paddingLarge),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: isDark
                              ? primaryColorLight.withOpacity(0.2)
                              : Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? primaryColorLight : textColorWhite,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: isDark ? primaryColorLight : textColorWhite,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: paddingMedium),

                      Text(
                        userName,
                        style: TextStyle(
                          color: isDark ? darkTextColor : textColorWhite,
                          fontSize: fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: paddingSmall),

                      Text(
                        userEmail,
                        style: TextStyle(
                          color: isDark ? darkTextColorLight : textColorWhite,
                          fontSize: fontSizeNormal,
                        ),
                      ),

                      const SizedBox(height: paddingMedium),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: paddingMedium,
                          vertical: paddingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? primaryColorLight.withOpacity(0.2)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            borderRadiusLarge,
                          ),
                          border: Border.all(
                            color: isDark ? primaryColorLight : textColorWhite,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Level $userLevel • $userPoints Poin',
                          style: TextStyle(
                            color: isDark ? darkTextColor : textColorWhite,
                            fontSize: fontSizeNormal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: paddingLarge),

//  ACHIEVEMENT SECTION
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: paddingMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            achievementLabel,
                            style: TextStyle(
                              fontSize: fontSizeLarge,
                              fontWeight: FontWeight.w600,
                              color: isDark ? darkTextColor : textColor,
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
                          borderRadius: BorderRadius.circular(
                            borderRadiusNormal,
                          ),
                          border: Border.all(
                            color: isDark ? darkBorderColor : borderColor,
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ TAMPILKAN DATA REAL-TIME DARI FIREBASE
                            Row(
                              children: [
                                Icon(
                                  totalTargetsToday == 0
                                      ? Icons.pending_actions
                                      : completedTargetsToday ==
                                              totalTargetsToday
                                          ? Icons.check_circle
                                          : Icons.pending,
                                  color: totalTargetsToday == 0
                                      ? warningColor
                                      : completedTargetsToday ==
                                              totalTargetsToday
                                          ? successColor
                                          : infoColor,
                                  size: 20,
                                ),
                                const SizedBox(width: paddingSmall),
                                Expanded(
                                  child: Text(
                                    totalTargetsToday == 0
                                        ? 'Belum ada target untuk hari ini'
                                        : '$completedTargetsToday dari $totalTargetsToday target selesai hari ini',
                                    style: TextStyle(
                                      fontSize: fontSizeMedium,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? darkTextColor : textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: paddingNormal),

                            // ✅ TAMPILKAN PROGRESS BAR HANYA JIKA ADA TARGET
                            if (totalTargetsToday > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: completedTargetsToday /
                                          totalTargetsToday,
                                      minHeight: 12,
                                      backgroundColor: isDark
                                          ? darkDividerColor
                                          : dividerColor,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        completedTargetsToday ==
                                                totalTargetsToday
                                            ? successColor
                                            : completedTargetsToday >=
                                                    totalTargetsToday / 2
                                                ? accentColor
                                                : errorColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: paddingSmall),
                                  // ✅ TAMBAH PERSENTASE
                                  Text(
                                    '${((completedTargetsToday / totalTargetsToday) * 100).toStringAsFixed(0)}% selesai',
                                    style: TextStyle(
                                      fontSize: fontSizeSmall,
                                      color: isDark
                                          ? darkTextColorLight
                                          : textColorLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: paddingNormal),

                            // ✅ PESAN DINAMIS BERDASARKAN PROGRESS
                            Container(
                              padding: const EdgeInsets.all(paddingSmall),
                              decoration: BoxDecoration(
                                color: (isDark ? infoColor : infoColor)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(borderRadiusSmall),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    color: infoColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: paddingSmall),
                                  Expanded(
                                    child: Text(
                                      _getMotivationalMessage(),
                                      style: TextStyle(
                                        fontSize: fontSizeSmall,
                                        color:
                                            isDark ? darkTextColor : textColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: paddingLarge),

                // PROFILE OPTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: paddingMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Profil',
                        style: TextStyle(
                          fontSize: fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                      const SizedBox(height: paddingNormal),

                      // ✅ Edit Profile - NOW WORKING
                      _buildProfileOption(
                        isDark: isDark,
                        icon: Icons.edit,
                        title: editProfile,
                        subtitle: 'Ubah data pribadi Anda',
                        onTap: _showEditProfileDialog,
                      ),
                      const SizedBox(height: paddingNormal),

                      // ✅ Change Password - NOW WORKING
                      _buildProfileOption(
                        isDark: isDark,
                        icon: Icons.lock,
                        title: changePassword,
                        subtitle: 'Ubah password akun Anda',
                        onTap: _showChangePasswordDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: paddingLarge),

                //  ACTION BUTTONS
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: paddingMedium,
                  ),
                  child: Column(
                    children: [
                      CustomButton(
                        text: logoutButton,
                        onPressed: handleLogout,
                        backgroundColor: errorColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: paddingLarge),

                // APP INFO
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: paddingMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tentang Aplikasi',
                        style: TextStyle(
                          fontSize: fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                      const SizedBox(height: paddingNormal),
                      Container(
                        padding: const EdgeInsets.all(paddingMedium),
                        decoration: BoxDecoration(
                          color: isDark
                              ? darkCardBackgroundColor
                              : cardBackgroundColor,
                          borderRadius: BorderRadius.circular(
                            borderRadiusNormal,
                          ),
                          border: Border.all(
                            color: isDark ? darkBorderColor : borderColor,
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appName,
                              style: TextStyle(
                                fontSize: fontSizeMedium,
                                fontWeight: FontWeight.w600,
                                color: isDark ? darkTextColor : textColor,
                              ),
                            ),
                            const SizedBox(height: paddingSmall),
                            Text(
                              'Versi 1.0.0',
                              style: TextStyle(
                                fontSize: fontSizeNormal,
                                color: isDark
                                    ? darkTextColorLight
                                    : textColorLight,
                              ),
                            ),
                            const SizedBox(height: paddingSmall),
                            Text(
                              appDescription,
                              style: TextStyle(
                                fontSize: fontSizeSmall,
                                color: isDark
                                    ? darkTextColorLight
                                    : textColorLight,
                                height: 1.5,
                              ),
                            ),
                          ],
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
      // BOTTOM NAVIGATION - HANYA SATU!
      bottomNavigationBar: BottomNavigation(
        currentIndex: selectedNavIndex,
        onTap: handleNavigation,
      ),
    ); // ← Tutup Scaffold
  } // ← Tutup method build

  // ✅ METHOD UNTUK PESAN MOTIVASI DINAMIS
  String _getMotivationalMessage() {
    if (totalTargetsToday == 0) {
      return '💡 Yuk, mulai tambahkan target ibadah untuk hari ini!';
    }

    if (completedTargetsToday == 0) {
      return '💪 Ayo semangat! Mulai selesaikan target ibadah hari ini.';
    }

    final percentage =
        (completedTargetsToday / totalTargetsToday * 100).round();

    if (percentage == 100) {
      return '🎉 Luar biasa! Semua target hari ini sudah selesai! Terus pertahankan konsistensi Anda.';
    } else if (percentage >= 75) {
      return '🔥 Hebat! Tinggal sedikit lagi untuk menyelesaikan semua target hari ini!';
    } else if (percentage >= 50) {
      return '👍 Bagus! Anda sudah menyelesaikan setengah target. Lanjutkan!';
    } else {
      return '💪 Ayo semangat! Masih ada target yang perlu diselesaikan hari ini.';
    }
  }

  // HELPER WIDGET - PROFILE OPTION
  Widget _buildProfileOption({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(paddingMedium),
        decoration: BoxDecoration(
          color: isDark ? darkCardBackgroundColor : cardBackgroundColor,
          borderRadius: BorderRadius.circular(borderRadiusNormal),
          border: Border.all(color: isDark ? darkBorderColor : borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (isDark ? primaryColorLight : primaryColor).withOpacity(
                  0.1,
                ),
                borderRadius: BorderRadius.circular(borderRadiusNormal),
              ),
              child: Icon(
                icon,
                color: isDark ? primaryColorLight : primaryColor,
                size: iconSizeNormal,
              ),
            ),
            const SizedBox(width: paddingMedium),
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
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? darkTextColorLight : textColorLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} // ← Tutup class _ProfileScreenState
