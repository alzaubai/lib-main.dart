import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إرسال طلب حجز جديد
  static Future<void> createBookingRequest({
    required String pitchName,
    required String teamOne,
    required String teamTwo,
    required String phone,
    required String dateStr,
    required String startTime,
    required String endTime,
    required double price,
  }) async {
    await _firestore.collection('bookings').add({
      'pitchName': pitchName,
      'teamOne': teamOne,
      'teamTwo': teamTwo,
      'phone': phone,
      'date': dateStr,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'status': 'pending',
      'seenByPlayer': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// إلغاء أو سحب حجز من قبل اللاعب
  static Future<void> cancelBookingByPlayer({
    required DocumentReference docRef,
    required String currentStatus,
    required String teamName,
  }) async {
    if (currentStatus == 'pending') {
      await docRef.delete();
    } else {
      await docRef.update({
        'status': 'rejected',
        'cancelledByPlayer': true,
        'cancellationSeenByOwner': false,
        'seenByPlayer': true,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellingTeamName': teamName,
        'rejectionReason': 'تم الإلغاء برغبة الكابتن',
      });
    }
  }

  /// تعليم حجوزات التبويب كمقروءة للاعب
  static Future<void> markBookingsAsSeen({
    required String userPhone,
    required List<String> statuses,
  }) async {
    try {
      final snap = await _firestore
          .collection('bookings')
          .where('phone', isEqualTo: userPhone)
          .where('status', whereIn: statuses)
          .where('seenByPlayer', isEqualTo: false)
          .get();

      for (var doc in snap.docs) {
        await doc.reference.update({'seenByPlayer': true});
      }
    } catch (_) {}
  }
}
