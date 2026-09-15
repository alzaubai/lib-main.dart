import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// حذف البطولة وتفريغ كافة مبارياتها من الجدول
  static Future<bool> deleteTournament(String tournamentId, String tournamentTitle) async {
    final batch = _firestore.batch();
    try {
      final bookingsByTid = await _firestore
          .collection('bookings')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      for (var bDoc in bookingsByTid.docs) {
        batch.update(bDoc.reference, {
          'isDeleted': true,
          'status': 'cancelled',
        });
      }

      final bookingsByName = await _firestore
          .collection('bookings')
          .where('tournamentTitle', isEqualTo: tournamentTitle)
          .get();

      for (var bDoc in bookingsByName.docs) {
        batch.update(bDoc.reference, {
          'isDeleted': true,
          'status': 'cancelled',
        });
      }

      batch.delete(_firestore.collection('tournaments').doc(tournamentId));
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// إضافة فريق يدوياً بواسطة المالك
  static Future<void> addTeamManually({
    required String tournamentId,
    required String teamName,
    required String phoneKey,
  }) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'teams': FieldValue.arrayUnion([teamName]),
      'registeredPlayers.$phoneKey': teamName,
    });
  }

  /// تسجيل فريق بواسطة اللاعب
  static Future<void> registerPlayerTeam({
    required String tournamentId,
    required String userPhone,
    required String teamName,
  }) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'teams': FieldValue.arrayUnion([teamName]),
      'registeredPlayers.$userPhone': teamName,
    });
  }

  /// استبعاد فريق من البطولة مع إرسال إشعار رسمي وإتاحة المقعد
  static Future<void> removeTeamWithReason({
    required String tournamentId,
    required String tournamentName,
    required String teamName,
    required String captainPhone,
    required String reason,
  }) async {
    final Map<String, dynamic> updatePayload = {
      'teams': FieldValue.arrayRemove([teamName]),
    };

    if (captainPhone.isNotEmpty) {
      updatePayload['registeredPlayers.$captainPhone'] = FieldValue.delete();
    }

    // 1. تحديث وثيقة البطولة وحذف الفريق
    await _firestore.collection('tournaments').doc(tournamentId).update(updatePayload);

    // 2. إرسال إشعار مباشر في تنبيهات اللاعب
    if (captainPhone.isNotEmpty) {
      await _firestore.collection('notifications').add({
        'userPhone': captainPhone,
        'type': 'tournament_removal',
        'title': 'استبعاد من البطولة',
        'tournamentName': tournamentName,
        'teamName': teamName,
        'reason': reason,
        'seen': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// إرسال إشعارات مواعيد المباريات لجميع الفرق بعد توليد القرعة
  static Future<void> notifyTeamsWithMatches({
    required String tournamentName,
    required List<Map<String, dynamic>> matches,
    required Map<String, dynamic> registeredPlayers,
  }) async {
    final batch = _firestore.batch();

    final Map<String, String> teamToPhone = {};
    registeredPlayers.forEach((phone, tName) {
      if (!phone.startsWith('manual_')) {
        teamToPhone[tName.toString()] = phone;
      }
    });

    for (var match in matches) {
      final teamA = match['teamA']?.toString() ?? '';
      final teamB = match['teamB']?.toString() ?? '';
      final date = match['date']?.toString() ?? '';
      final time = match['time']?.toString() ?? '';

      if (date.isEmpty || time.isEmpty) continue;

      final phoneA = teamToPhone[teamA];
      final phoneB = teamToPhone[teamB];

      if (phoneA != null && phoneA.isNotEmpty) {
        final refA = _firestore.collection('notifications').doc();
        batch.set(refA, {
          'userPhone': phoneA,
          'type': 'tournament_match_scheduled',
          'title': 'تحديد موعد مباراتك الرسمية',
          'tournamentName': tournamentName,
          'opponent': teamB,
          'matchDate': date,
          'matchTime': time,
          'seen': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (phoneB != null && phoneB.isNotEmpty) {
        final refB = _firestore.collection('notifications').doc();
        batch.set(refB, {
          'userPhone': phoneB,
          'type': 'tournament_match_scheduled',
          'title': 'تحديد موعد مباراتك الرسمية',
          'tournamentName': tournamentName,
          'opponent': teamA,
          'matchDate': date,
          'matchTime': time,
          'seen': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }
}
