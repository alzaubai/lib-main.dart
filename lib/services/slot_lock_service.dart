import 'package:cloud_firestore/cloud_firestore.dart';

class SlotLockService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// فحص وحجز قفل مؤقت للساعة لمدة 5 دقائق
  static Future<bool> acquireTemporaryLock({
    required String pitchName,
    required String dateStr,
    required String timeSlot,
    required String userPhone,
  }) async {
    final lockDocId = '${pitchName}_${dateStr}_${timeSlot.replaceAll(' ', '')}';
    final lockRef = _firestore.collection('slot_locks').doc(lockDocId);

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(lockRef);
      final now = DateTime.now();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final lockedBy = data['lockedBy']?.toString() ?? '';
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

        // إذا كان القفل لا يزال سارياً ومحجوزاً من مستخدم آخر، نرفض العملية
        if (expiresAt != null && expiresAt.isAfter(now) && lockedBy != userPhone) {
          return false;
        }
      }

      // تسجيل أو تجديد القفل لمدة 5 دقائق كاملة
      transaction.set(lockRef, {
        'pitchName': pitchName,
        'date': dateStr,
        'timeSlot': timeSlot,
        'lockedBy': userPhone,
        'lockedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 5))),
      });

      return true;
    });
  }

  /// تحرير القفل المؤقت في حال تراجع اللاعب أو إلغاء الاختيار
  static Future<void> releaseLock({
    required String pitchName,
    required String dateStr,
    required String timeSlot,
    required String userPhone,
  }) async {
    try {
      final lockDocId = '${pitchName}_${dateStr}_${timeSlot.replaceAll(' ', '')}';
      final lockRef = _firestore.collection('slot_locks').doc(lockDocId);
      final snap = await lockRef.get();

      if (snap.exists && snap.data()?['lockedBy'] == userPhone) {
        await lockRef.delete();
      }
    } catch (_) {}
  }
}
