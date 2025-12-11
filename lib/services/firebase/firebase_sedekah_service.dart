import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSedekahService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference get _sedekahCollection =>
      _firestore.collection('sedekah');

  /// CREATE SEDEKAH
  static Future<bool> createSedekah({
    required String userId,
    required int jumlah,
    required String keterangan,
    String? category,
  }) async {
    try {
      final docRef = _sedekahCollection.doc();
      
      await docRef.set({
        'id': docRef.id,
        'userId': userId,
        'jumlah': jumlah,
        'keterangan': keterangan,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Sedekah created: Rp$jumlah');
      return true;
    } catch (e) {
      print('❌ Error creating sedekah: $e');
      return false;
    }
  }

  /// GET SEDEKAH BY USER ID
  static Future<List<Map<String, dynamic>>> getSedekahByUserId(
    String userId,
  ) async {
    try {
      final snapshot = await _sedekahCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error getting sedekah: $e');
      return [];
    }
  }

  /// GET TOTAL SEDEKAH BULAN INI
  static Future<int> getTotalSedekahThisMonth(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final snapshot = await _sedekahCollection
          .where('userId', isEqualTo: userId)
          .where('timestamp',
              isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .where('timestamp',
              isLessThanOrEqualTo: endOfMonth.toIso8601String())
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['jumlah'] as num).toInt();
      }

      return total;
    } catch (e) {
      print('❌ Error calculating total: $e');
      return 0;
    }
  }

  /// DELETE SEDEKAH
  static Future<bool> deleteSedekah(String sedekahId) async {
    try {
      await _sedekahCollection.doc(sedekahId).delete();
      print('✅ Sedekah deleted: $sedekahId');
      return true;
    } catch (e) {
      print('❌ Error deleting sedekah: $e');
      return false;
    }
  }
}