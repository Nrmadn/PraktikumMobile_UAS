import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// ========================================
/// QURAN PROGRESS PROVIDER
/// Mengelola progress membaca Al-Qur'an per surah
/// ========================================
class QuranProgressProvider extends ChangeNotifier {
  static const String _progressKey = 'quran_reading_progress';
  
  // Progress data: Map<surahNumber, currentAyat>
  Map<int, int> _progressMap = {};
  
  QuranProgressProvider() {
    _loadProgress();
  }

  /// Get progress untuk surah tertentu
  int getProgress(int surahNumber) {
    return _progressMap[surahNumber] ?? 0;
  }

  /// Load progress dari SharedPreferences
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? progressJson = prefs.getString(_progressKey);
      
      if (progressJson != null && progressJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(progressJson);
        _progressMap = decoded.map((key, value) => 
          MapEntry(int.parse(key), value as int)
        );
      }
      
      print('✅ Quran progress loaded: ${_progressMap.length} surah tracked');
      notifyListeners();
    } catch (e) {
      print('❌ Error loading progress: $e');
    }
  }

  /// Save progress ke SharedPreferences
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String progressJson = json.encode(
        _progressMap.map((key, value) => MapEntry(key.toString(), value))
      );
      await prefs.setString(_progressKey, progressJson);
      print('✅ Progress saved');
    } catch (e) {
      print('❌ Error saving progress: $e');
    }
  }

  /// Update progress untuk surah tertentu
  Future<void> updateProgress(int surahNumber, int currentAyat) async {
    _progressMap[surahNumber] = currentAyat;
    await _saveProgress();
    notifyListeners();
  }

  /// Reset progress untuk surah tertentu
  Future<void> resetProgress(int surahNumber) async {
    _progressMap.remove(surahNumber);
    await _saveProgress();
    notifyListeners();
  }

  /// Reset semua progress
  Future<void> resetAllProgress() async {
    _progressMap.clear();
    await _saveProgress();
    notifyListeners();
  }

  /// Cek apakah surah sudah selesai dibaca
  bool isCompleted(int surahNumber, int totalAyat) {
    final progress = _progressMap[surahNumber] ?? 0;
    return progress >= totalAyat;
  }

  /// Get persentase progress
  double getProgressPercentage(int surahNumber, int totalAyat) {
    if (totalAyat == 0) return 0.0;
    final progress = _progressMap[surahNumber] ?? 0;
    return (progress / totalAyat).clamp(0.0, 1.0);
  }

  /// Get total completed surah
  int getTotalCompleted(List<Map<String, dynamic>> surahList) {
    int completed = 0;
    for (var surah in surahList) {
      final surahNumber = surah['id'] as int;
      final totalVerses = surah['verses'] as int;
      if (isCompleted(surahNumber, totalVerses)) {
        completed++;
      }
    }
    return completed;
  }
}