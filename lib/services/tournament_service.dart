import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
