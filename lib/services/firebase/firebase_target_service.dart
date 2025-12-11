import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/target_ibadah_model.dart';

class FirebaseTargetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference get _targetsCollection =>
      _firestore.collection('targets');

  /// ✅ CREATE TARGET
  static Future<bool> createTarget({
    required String userId,
    required String name,
    required String category,
    required String note,
    required DateTime targetDate,
  }) async {
    try {
      final docRef = _targetsCollection.doc(); // Auto-generate ID

      final newTarget = TargetIbadah(
        id: docRef.id,
        userId: userId,
        name: name,
        category: category,
        note: note,
        isCompleted: false,
        targetDate: targetDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newTarget.toJson());

      print('✅ Target created: $name');
      return true;
    } catch (e) {
      print('❌ Error creating target: $e');
      return false;
    }
  }

  /// ✅ GET TARGETS BY USER ID
  static Future<List<TargetIbadah>> getTargetsByUserId(String userId) async {
    try {
      final snapshot = await _targetsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('targetDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) =>
              TargetIbadah.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting targets: $e');
      return [];
    }
  }

  /// ✅ GET TARGETS BY DATE
  static Future<List<TargetIbadah>> getTargetsByDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _targetsCollection
          .where('userId', isEqualTo: userId)
          .where('targetDate',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('targetDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) =>
              TargetIbadah.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting targets by date: $e');
      return [];
    }
  }

  /// ✅ UPDATE TARGET
  /// ✅ UPDATE TARGET
  static Future<bool> updateTarget({
    required String targetId,
    String? name,
    String? category,
    String? note,
    DateTime? targetDate,
    bool? isCompleted,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (category != null) updates['category'] = category;
      if (note != null) updates['note'] = note;
      if (targetDate != null)
        updates['targetDate'] = targetDate.toIso8601String();
      if (isCompleted != null) {
        updates['isCompleted'] = isCompleted;
        if (isCompleted) {
          updates['completedAt'] = DateTime.now().toIso8601String();
        } else {
          updates['completedAt'] = null;
        }
      }

      await _targetsCollection.doc(targetId).update(updates);

      print('✅ Target updated: $targetId');
      return true;
    } catch (e) {
      print('❌ Error updating target: $e');
      return false;
    }
  }

  /// ✅ DELETE TARGET
  static Future<bool> deleteTarget(String targetId) async {
    try {
      await _targetsCollection.doc(targetId).delete();
      print('✅ Target deleted: $targetId');
      return true;
    } catch (e) {
      print('❌ Error deleting target: $e');
      return false;
    }
  }

  /// ✅ TOGGLE COMPLETION
  static Future<bool> toggleTargetCompletion(
      String targetId, bool isCompleted) async {
    return await updateTarget(
      targetId: targetId,
      isCompleted: isCompleted,
    );
  }

  /// ✅ UPDATE TARGET COMPLETION
  static Future<bool> updateTargetCompletion({
    required String userId,
    required String targetId,
    required bool isCompleted,
  }) async {
    return await updateTarget(
      targetId: targetId,
      isCompleted: isCompleted,
    );
  }
}
