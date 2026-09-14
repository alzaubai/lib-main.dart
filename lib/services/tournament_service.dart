import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// استبعاد فريق من البطولة مع إرسال إشعار رسمي بالسبب
  static Future<void> removeTeamWithReason({
    required String tournamentId,
    required String tournamentName,
    required Map<String, dynamic> teamData,
    required String reason,
  }) async {
    final teamPhone = (teamData['phone'] ?? '').toString().trim();
    final teamName = teamData['name'] ?? teamData['teamName'] ?? 'الفريق';

    // 1. حذف الفريق من مصفوفة الفرق المسجلة في وثيقة البطولة
    final tournamentRef = _firestore.collection('tournaments').doc(tournamentId);
    await tournamentRef.update({
      'teams': FieldValue.arrayRemove([teamData]),
      'registeredTeamsCount': FieldValue.increment(-1),
    });

    // 2. إرسال إشعار مباشر في سجل تنبيهات الكابتن إذا كان له رقم هاتف
    if (teamPhone.isNotEmpty) {
      await _firestore.collection('notifications').add({
        'userPhone': teamPhone,
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

  /// تثبيت القرعة وإرسال إشعارات مواعيد المباريات لجميع الكباتن المسجلين
  static Future<void> confirmDrawAndNotifyTeams({
    required String tournamentId,
    required String tournamentName,
    required List<Map<String, dynamic>> fixtures, // المباريات المجدولة
  }) async {
    final batch = _firestore.batch();

    // 1. تحديث حالة البطولة إلى: القرعة مثبتة
    final tournamentRef = _firestore.collection('tournaments').doc(tournamentId);
    batch.update(tournamentRef, {
      'status': 'draw_confirmed',
      'fixtures': fixtures,
      'drawConfirmedAt': FieldValue.serverTimestamp(),
    });

    // 2. تدوين إشعار لكل فريق بموعد مباراته وخصمه
    for (var match in fixtures) {
      final team1Phone = (match['team1Phone'] ?? '').toString().trim();
      final team2Phone = (match['team2Phone'] ?? '').toString().trim();
      final date = match['date'] ?? '';
      final time = match['time'] ?? '';
      final team1Name = match['team1Name'] ?? 'فريق';
      final team2Name = match['team2Name'] ?? 'فريق';

      // إشعار الكابتن الأول
      if (team1Phone.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userPhone': team1Phone,
          'type': 'tournament_match_scheduled',
          'title': 'تحديد موعد مباراتك في البطولة',
          'tournamentName': tournamentName,
          'opponent': team2Name,
          'matchDate': date,
          'matchTime': time,
          'seen': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // إشعار الكابتن الثاني
      if (team2Phone.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userPhone': team2Phone,
          'type': 'tournament_match_scheduled',
          'title': 'تحديد موعد مباراتك في البطولة',
          'tournamentName': tournamentName,
          'opponent': team1Name,
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
