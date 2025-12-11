import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/target_ibadah_model.dart';

/// Service untuk mengelola CRUD Target Ibadah
/// Menyimpan data di SharedPreferences (local storage)
/// 
/// Flow:
/// 1. Load targets dari SharedPreferences
/// 2. Jika kosong, load dari JSON dummy (first time)
/// 3. Save/Update/Delete akan update SharedPreferences
class TargetService {
  static const String _targetsKey = 'user_targets';
  static const String _lastTargetIdKey = 'last_target_id';

  /// 📖 GET ALL TARGETS untuk user tertentu
  static Future<List<TargetIbadah>> getTargetsByUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? targetsJson = prefs.getString(_targetsKey);

      if (targetsJson == null || targetsJson.isEmpty) {
        return [];
      }

      final List<dynamic> targetsList = json.decode(targetsJson);
      final allTargets = targetsList
          .map((json) => TargetIbadah.fromJson(json))
          .toList();

      // Filter hanya target milik user ini
      return allTargets.where((target) => target.userId == userId).toList();
    } catch (e) {
      print('❌ Error getting targets: $e');
      return [];
    }
  }

  /// 📖 GET TARGET BY ID
  static Future<TargetIbadah?> getTargetById(String targetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? targetsJson = prefs.getString(_targetsKey);

      if (targetsJson == null) return null;

      final List<dynamic> targetsList = json.decode(targetsJson);
      final targets = targetsList
          .map((json) => TargetIbadah.fromJson(json))
          .toList();

      return targets.firstWhere(
        (target) => target.id == targetId,
        orElse: () => TargetIbadah(
          id: '',
          userId: '',
          name: '',
          category: '',
          note: '',
          isCompleted: false,
          targetDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print('❌ Error getting target by ID: $e');
      return null;
    }
  }

  /// ➕ CREATE NEW TARGET
  static Future<bool> createTarget({
    required String userId,
    required String name,
    required String category,
    required String note,
    required DateTime targetDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate ID baru
      final newId = await _generateTargetId();

      // Buat target baru
      final newTarget = TargetIbadah(
        id: newId,
        userId: userId,
        name: name,
        category: category,
        note: note,
        isCompleted: false,
        targetDate: targetDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Load existing targets
      final existingTargets = await _getAllTargets();

      // Tambahkan target baru
      existingTargets.add(newTarget);

      // Save ke SharedPreferences
      final success = await _saveAllTargets(existingTargets);

      if (success) {
        print('✅ Target berhasil dibuat: $name');
      }

      return success;
    } catch (e) {
      print('❌ Error creating target: $e');
      return false;
    }
  }

  /// 🔄 UPDATE EXISTING TARGET
  static Future<bool> updateTarget({
    required String targetId,
    String? name,
    String? category,
    String? note,
    DateTime? targetDate,
    bool? isCompleted,
  }) async {
    try {
      // Load all targets
      final targets = await _getAllTargets();

      // Cari target yang akan diupdate
      final targetIndex = targets.indexWhere((t) => t.id == targetId);

      if (targetIndex == -1) {
        print('❌ Target tidak ditemukan: $targetId');
        return false;
      }

      // Update target dengan data baru
      final updatedTarget = targets[targetIndex].copyWith(
        name: name,
        category: category,
        note: note,
        targetDate: targetDate,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
        completedAt: isCompleted == true ? DateTime.now() : null,
      );

      // Replace target lama dengan yang baru
      targets[targetIndex] = updatedTarget;

      // Save ke SharedPreferences
      final success = await _saveAllTargets(targets);

      if (success) {
        print('✅ Target berhasil diupdate: $name');
      }

      return success;
    } catch (e) {
      print('❌ Error updating target: $e');
      return false;
    }
  }

  /// 🗑️ DELETE TARGET
  static Future<bool> deleteTarget(String targetId) async {
    try {
      // Load all targets
      final targets = await _getAllTargets();

      // Remove target dengan ID tertentu
      final initialLength = targets.length;
      targets.removeWhere((target) => target.id == targetId);

      if (targets.length == initialLength) {
        print('❌ Target tidak ditemukan: $targetId');
        return false;
      }

      // Save ke SharedPreferences
      final success = await _saveAllTargets(targets);

      if (success) {
        print('✅ Target berhasil dihapus: $targetId');
      }

      return success;
    } catch (e) {
      print('❌ Error deleting target: $e');
      return false;
    }
  }

  /// ✅ TOGGLE TARGET COMPLETION
  static Future<bool> toggleTargetCompletion(String targetId) async {
    try {
      final targets = await _getAllTargets();
      final targetIndex = targets.indexWhere((t) => t.id == targetId);

      if (targetIndex == -1) return false;

      final currentStatus = targets[targetIndex].isCompleted;
      final updatedTarget = targets[targetIndex].copyWith(
        isCompleted: !currentStatus,
        completedAt: !currentStatus ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );

      targets[targetIndex] = updatedTarget;

      return await _saveAllTargets(targets);
    } catch (e) {
      print('❌ Error toggling target completion: $e');
      return false;
    }
  }

  /// 📅 GET TARGETS BY DATE
  static Future<List<TargetIbadah>> getTargetsByDate({
    required String userId,
    required DateTime date,
  }) async {
    final allTargets = await getTargetsByUserId(userId);

    return allTargets.where((target) {
      return target.targetDate.year == date.year &&
          target.targetDate.month == date.month &&
          target.targetDate.day == date.day;
    }).toList();
  }

  /// 📊 GET COMPLETED TARGETS COUNT
  static Future<int> getCompletedTargetsCount(String userId) async {
    final targets = await getTargetsByUserId(userId);
    return targets.where((t) => t.isCompleted).length;
  }

  /// 📊 GET TODAY'S TARGETS COUNT
  static Future<int> getTodayTargetsCount(String userId) async {
    final today = DateTime.now();
    final todayTargets = await getTargetsByDate(userId: userId, date: today);
    return todayTargets.length;
  }

  /// 📊 GET TODAY'S COMPLETED COUNT
  static Future<int> getTodayCompletedCount(String userId) async {
    final today = DateTime.now();
    final todayTargets = await getTargetsByDate(userId: userId, date: today);
    return todayTargets.where((t) => t.isCompleted).length;
  }

  // === PRIVATE HELPER METHODS ===

  /// Load semua targets (dari semua user)
  static Future<List<TargetIbadah>> _getAllTargets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? targetsJson = prefs.getString(_targetsKey);

      if (targetsJson == null || targetsJson.isEmpty) {
        return [];
      }

      final List<dynamic> targetsList = json.decode(targetsJson);
      return targetsList
          .map((json) => TargetIbadah.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error loading all targets: $e');
      return [];
    }
  }

  /// Save semua targets ke SharedPreferences
  static Future<bool> _saveAllTargets(List<TargetIbadah> targets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetsJson = json.encode(
        targets.map((target) => target.toJson()).toList(),
      );
      return await prefs.setString(_targetsKey, targetsJson);
    } catch (e) {
      print('❌ Error saving targets: $e');
      return false;
    }
  }

  /// Generate ID unik untuk target baru
  static Future<String> _generateTargetId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int lastId = prefs.getInt(_lastTargetIdKey) ?? 0;
      lastId++;
      await prefs.setInt(_lastTargetIdKey, lastId);
      return 'target_${lastId.toString().padLeft(4, '0')}';
    } catch (e) {
      print('❌ Error generating target ID: $e');
      return 'target_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// 🗑️ CLEAR ALL TARGETS (untuk testing/reset)
  static Future<bool> clearAllTargets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_targetsKey);
      await prefs.remove(_lastTargetIdKey);
      print('✅ All targets cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing targets: $e');
      return false;
    }
  }

 /// Update status completion target
static Future<bool> updateTargetCompletion({
  required String userId,
  required String targetId,
  required bool isCompleted,
}) async {
  try {
    print('🔵 updateTargetCompletion: userId=$userId, targetId=$targetId, isCompleted=$isCompleted');
    
    // ✅ GUNAKAN METHOD YANG SUDAH ADA
    final targets = await _getAllTargets();
    print('🔵 Total targets loaded: ${targets.length}');
    
    // Cari target yang akan diupdate
    final targetIndex = targets.indexWhere((t) => t.id == targetId && t.userId == userId);
    print('🔵 Target index: $targetIndex');
    
    if (targetIndex == -1) {
      print('❌ Target tidak ditemukan: $targetId');
      return false;
    }
    
    // Update target dengan copyWith
    final updatedTarget = targets[targetIndex].copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    
    // Replace target lama dengan yang baru
    targets[targetIndex] = updatedTarget;
    print('🔵 Target updated in list');
    
    // Save ke SharedPreferences
    final success = await _saveAllTargets(targets);
    print(success ? '✅ Target saved successfully' : '❌ Failed to save target');
    
    return success;
  } catch (e, stackTrace) {
    print('❌ Error updating target completion: $e');
    print('❌ Stack trace: $stackTrace');
    return false;
  }
}
}
