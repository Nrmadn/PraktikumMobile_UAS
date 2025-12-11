import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk mengelola bahasa aplikasi
/// Support: Indonesia, English, Arabic
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  
  Locale _locale = const Locale('id', 'ID'); // Default: Bahasa Indonesia
  bool _isLoading = true;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  
  // Helper getters
  String get currentLanguage {
    switch (_locale.languageCode) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      default:
        return 'Bahasa Indonesia';
    }
  }

  LocaleProvider() {
    _loadLocaleFromPreferences();
  }

  /// Load bahasa dari SharedPreferences
  Future<void> _loadLocaleFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey) ?? 'id';
      
      _locale = _getLocaleFromCode(languageCode);
      _isLoading = false;
      
      print('✅ Locale loaded: $languageCode');
      notifyListeners();
    } catch (e) {
      print('❌ Error loading locale: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set bahasa
  Future<void> setLocale(String languageCode) async {
    try {
      _locale = _getLocaleFromCode(languageCode);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
      
      print('✅ Locale changed to: $languageCode');
      notifyListeners();
    } catch (e) {
      print('❌ Error setting locale: $e');
    }
  }

  /// Convert language code ke Locale
  Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'en':
        return const Locale('en', 'US');
      case 'id':
      default:
        return const Locale('id', 'ID');
    }
  }

  /// Get language code dari Locale
  String getLanguageCode() {
    return _locale.languageCode;
  }
  
  /// Get language code dari nama bahasa
  String getLanguageCodeFromName(String name) {
    switch (name) {
      case 'English':
        return 'en';
      case 'Bahasa Indonesia':
      default:
        return 'id';
    }
  }
}