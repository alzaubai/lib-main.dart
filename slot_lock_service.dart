import 'package:cloud_firestore/cloud_firestore.dart';

class SlotLockService {
  static final _firestore = FirebaseFirestore.instance;

  /// محاولة قفل الوقت للمستخدم الحالي
  static Future<bool> lockSlot({
    required String pitchName,
    required String date,
    required String slot,
    required String userPhone,
  }) async {
    final lockId = '${pitchName}_${date}_${slot.replaceAll(' ', '')}';
    final docRef = _firestore.collection('slot_locks').doc(lockId);

    try {
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (snapshot.exists) {
          final data = snapshot.data()!;
          final lockedAt = (data['lockedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          
          // إذا القفل صارله أكثر من 5 دقائق، نعتبره منتهي ونأخذه
          if (DateTime.now().difference(lockedAt).inMinutes >= 5) {
            transaction.set(docRef, {
              'userPhone': userPhone,
              'lockedAt': FieldValue.serverTimestamp(),
            });
            return true;
          }
          
          // إذا كان مقفول لنفس المستخدم (يريد يجدد الوقت)
          if (data['userPhone'] == userPhone) {
            transaction.update(docRef, {'lockedAt': FieldValue.serverTimestamp()});
            return true;
          }
          
          return false; // مقفول من قبل مستخدم آخر حالياً
        } else {
          // الوقت متاح، يتم قفله
          transaction.set(docRef, {
            'userPhone': userPhone,
            'lockedAt': FieldValue.serverTimestamp(),
          });
          return true;
        }
      });
    } catch (e) {
      return false; // في حال فشل الاتصال، نمنع الحجز تجنباً للتعارض
    }
  }

  /// تحرير القفل (عند التراجع أو الإغلاق)
  static Future<void> releaseSlot({
    required String pitchName,
    required String date,
    required String slot,
    required String userPhone,
  }) async {
    final lockId = '${pitchName}_${date}_${slot.replaceAll(' ', '')}';
    final docRef = _firestore.collection('slot_locks').doc(lockId);
    
    try {
      final snapshot = await docRef.get();
      if (snapshot.exists && snapshot.data()?['userPhone'] == userPhone) {
        await docRef.delete();
      }
    } catch (_) {}
  }
}
