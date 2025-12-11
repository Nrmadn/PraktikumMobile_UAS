import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk mengelola theme (Light/Dark Mode)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoading => _isLoading;

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  /// Load theme dari SharedPreferences
  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _isLoading = false;
      
      print('✅ Theme loaded: ${isDark ? 'Dark' : 'Light'}');
      notifyListeners();
    } catch (e) {
      print('❌ Error loading theme: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle theme (Light <-> Dark)
  Future<void> toggleTheme() async {
    try {
      _themeMode = _themeMode == ThemeMode.light 
          ? ThemeMode.dark 
          : ThemeMode.light;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
      
      print('✅ Theme changed to: ${isDarkMode ? 'Dark' : 'Light'}');
      notifyListeners();
    } catch (e) {
      print('❌ Error toggling theme: $e');
    }
  }

  /// Set theme explicitly
  Future<void> setTheme(bool isDark) async {
    try {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
      
      notifyListeners();
    } catch (e) {
      print('❌ Error setting theme: $e');
    }
  }
}