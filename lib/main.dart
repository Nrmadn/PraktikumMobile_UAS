import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';  // ✅ TAMBAH
import 'firebase_options.dart';  // ✅ TAMBAH
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'constants.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'utils/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_target_screen.dart';
import 'screens/edit_target_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/setting_screen.dart';
import 'screens/progress_home_screen.dart';
import 'screens/sholat_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/sedekah_screen.dart';
import 'screens/dzikir_screen.dart';
import 'providers/quran_progress_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ INITIALIZE FIREBASE
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Initialize notifications
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.scheduleAllNotifications();
    print('✅ Notification service initialized successfully');
  } catch (e) {
    print('❌ Error initializing notifications: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => QuranProgressProvider()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

// Sisa kode MyApp tetap sama seperti sebelumnya...

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({
    required this.isLoggedIn,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,

          // ✅ Theme
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,

          // ✅ Localization
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('id', 'ID'), // Bahasa Indonesia
            Locale('en', 'US'), // English
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ✅ PENTING: Wrap builder agar provider tersedia di semua routes
          builder: (context, widget) {
            return widget ?? const SizedBox.shrink();
          },

          home: isLoggedIn ? const HomeScreen() : const SplashScreen(),

          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/add_target': (context) => const AddTargetScreen(),
            '/edit_target': (context) => const EditTargetScreen(),
            '/progress': (context) => const ProgressScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/setting': (context) => const SettingScreen(),
            '/progress_home': (context) => const ProgressHomeScreen(),
            '/sholat': (context) => const SholatScreen(),
            '/quran': (context) => const QuranScreen(),
            '/dzikir': (context) => const DzikirScreen(),
            '/sedekah': (context) => const SedekahScreen(),
          },

          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                  builder: (context) =>
                      isLoggedIn ? const HomeScreen() : const SplashScreen(),
                );
              default:
                return MaterialPageRoute(
                  builder: (context) =>
                      isLoggedIn ? const HomeScreen() : const SplashScreen(),
                );
            }
          },
        );
      },
    );
  }
}