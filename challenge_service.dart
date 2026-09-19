import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeResult {
  final bool success;
  final String? errorMessage;

  ChallengeResult({required this.success, this.errorMessage});
}

class ChallengeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// نشر تحدي مفتوح جديد يشوفه كل اللاعبين
  static Future<bool> createChallenge({
    required String pitchName,
    required String creatorPhone,
    required String creatorTeamName,
    required String dateStr,
    required String startTime,
    required String endTime,
    required double pricePerTeam,
    String governorate = 'بغداد',
  }) async {
    try {
      await _firestore.collection('challenges').add({
        'pitchName': pitchName,
        'creatorPhone': creatorPhone,
        'creatorTeamName': creatorTeamName,
        'opponentTeamName': '',
        'acceptedByPhone': '',
        'date': dateStr,
        'startTime': startTime,
        'endTime': endTime,
        'pricePerTeam': pricePerTeam,
        'governorate': governorate,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// إلغاء التحدي من قبل صاحبه (قبل قبوله)
  static Future<void> cancelChallenge(String challengeId) async {
    await _firestore.collection('challenges').doc(challengeId).update({
      'status': 'cancelled',
    });
  }

  /// قبول تحدي: يتحقق من عدم تعارض الوقت، وينشئ حجز مؤكد، ويحدث حالة التحدي
  static Future<ChallengeResult> acceptChallenge({
    required String challengeId,
    required String pitchName,
    required String dateStr,
    required String startTime,
    required String endTime,
    required String creatorTeamName,
    required double pricePerTeam,
    required String acceptedByPhone,
    required String acceptedTeamName,
  }) async {
    try {
      // 1. التأكد إن التحدي مازال مفتوح (لتفادي قبوله مرتين بنفس اللحظة)
      final challengeRef = _firestore.collection('challenges').doc(challengeId);
      final challengeSnap = await challengeRef.get();
      if (!challengeSnap.exists || (challengeSnap.data()?['status'] ?? '') != 'open') {
        return ChallengeResult(success: false, errorMessage: 'عذراً، تم قبول هذا التحدي أو إلغاؤه للتو');
      }

      // 2. التأكد إن الوقت غير محجوز فعلياً بجدول الملعب
      final conflictSnap = await _firestore
          .collection('bookings')
          .where('pitchName', isEqualTo: pitchName)
          .where('date', isEqualTo: dateStr)
          .where('startTime', isEqualTo: startTime)
          .get();

      final isConflicting = conflictSnap.docs.any((d) {
        final st = (d.data()['status'] ?? '').toString();
        final isDeleted = d.data()['isDeleted'] == true;
        return !isDeleted && st != 'rejected' && st != 'cancelled';
      });

      if (isConflicting) {
        return ChallengeResult(success: false, errorMessage: 'عذراً، هذا الوقت أصبح محجوزاً بجدول الملعب');
      }

      // 3. إنشاء الحجز المؤكد مباشرة (اتفاق متبادل بين الفريقين)
      final batch = _firestore.batch();
      final bookingRef = _firestore.collection('bookings').doc();
      batch.set(bookingRef, {
        'pitchName': pitchName,
        'teamOne': creatorTeamName,
        'teamTwo': acceptedTeamName,
        'phone': acceptedByPhone,
        'date': dateStr,
        'startTime': startTime,
        'endTime': endTime,
        'price': pricePerTeam * 2,
        'status': 'confirmed',
        'isDeleted': false,
        'seenByPlayer': true,
        'fromChallenge': true,
        'challengeId': challengeId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(challengeRef, {
        'status': 'accepted',
        'opponentTeamName': acceptedTeamName,
        'acceptedByPhone': acceptedByPhone,
        'bookingId': bookingRef.id,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      final creatorPhone = (challengeSnap.data()?['creatorPhone'] ?? '').toString();
      if (creatorPhone.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userPhone': creatorPhone,
          'type': 'challenge_accepted',
          'title': 'تم قبول تحديك! ⚽',
          'opponentTeamName': acceptedTeamName,
          'pitchName': pitchName,
          'matchDate': dateStr,
          'matchTime': startTime,
          'seen': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return ChallengeResult(success: true);
    } catch (e) {
      return ChallengeResult(success: false, errorMessage: 'حدث خطأ أثناء قبول التحدي');
    }
  }
}
