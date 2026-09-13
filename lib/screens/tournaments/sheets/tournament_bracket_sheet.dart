import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';

class TournamentBracketSheet extends StatelessWidget {
  final String tournamentId;
  final String tournamentTitle;
  final String pitchName;
  final bool isOwner;

  const TournamentBracketSheet({
    super.key,
    required this.tournamentId,
    required this.tournamentTitle,
    required this.pitchName,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F6F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournamentTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1B5E20),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'جدول المواجهات والتوقيت الزمني للأدوار الإقصائية',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tournaments')
                    .doc(tournamentId)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                    );
                  }

                  if (!snap.hasData || !snap.data!.exists) {
                    return const Center(child: Text('بيانات البطولة غير متوفرة'));
                  }

                  final tData = snap.data!.data() as Map<String, dynamic>? ?? {};
                  final currentMatches = List<dynamic>.from(tData['matches'] ?? []);
                  final status = tData['status'] ?? 'registering';
                  final champion = tData['champion'];

                  if (currentMatches.isEmpty) {
                    return const Center(
                      child: Text(
                        'لم يتم توليد مباريات القرعة بعد',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  return ListView(
                    children: [
                      // لافتة تتويج البطل في أعلى الشجرة إذا انتهت البطولة
                      if (status == 'completed' && champion != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade200, Colors.amber.shade50],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.shade600, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'تم اختتام البطولة وتتويج البطل رسمياً!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '🥇 بطل الكأس: $champion 🥇',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // قائمة المباريات
                      ...currentMatches.map((matchData) {
                        final match = Map<String, dynamic>.from(matchData);
                        final matchId = match['id'] ?? '';
                        final teamA = match['teamA'] ?? 'بانتظار المتأهل';
                        final teamB = match['teamB'] ?? 'بانتظار المتأهل';
                        final winner = match['winner'];
                        final matchDate = match['date'] ?? '';
                        final matchTime = match['time'] ?? '';
                        final round = match['round'] ?? 'مباراة دور';
                        final hasSchedule =
                            matchDate.toString().isNotEmpty && matchTime.toString().isNotEmpty;

                        final isFinal = matchId == 'final_match';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isFinal
                                  ? Colors.amber.shade600
                                  : (winner != null
                                      ? Colors.green.shade400
                                      : (hasSchedule
                                          ? Colors.blue.shade300
                                          : Colors.grey.shade300)),
                              width: isFinal ? 1.8 : 1.2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isFinal
                                            ? Colors.amber.shade100
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isFinal
                                              ? Colors.amber.shade400
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        '🏆 $round',
                                        style: TextStyle(
                                          color: isFinal
                                              ? Colors.amber.shade900
                                              : Colors.grey.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (winner != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'انتهت ✔️',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // شريط الموعد والتوقيت
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: hasSchedule
                                        ? Colors.blue.shade50
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        hasSchedule
                                            ? Icons.alarm_on_rounded
                                            : Icons.schedule_rounded,
                                        size: 16,
                                        color: hasSchedule
                                            ? Colors.blue.shade800
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          hasSchedule
                                              ? '📅 $matchDate  |  ⏰ $matchTime'
                                              : 'الموعد يُحدد لاحقاً ⏳',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: hasSchedule
                                                ? Colors.blue.shade900
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      if (isOwner && winner == null)
                                        InkWell(
                                          onTap: () => _openScheduleDialog(
                                            context,
                                            tournamentId,
                                            matchId,
                                            teamA,
                                            teamB,
                                            matchDate,
                                            matchTime,
                                            currentMatches,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B5E20),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              hasSchedule ? 'تعديل ⏱️' : 'تحديد موعد 📅',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // بطاقة المواجهة بين الفريقين
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: winner == teamA
                                              ? Colors.green.shade50
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: winner == teamA
                                                ? Colors.green
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          teamA,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: winner == teamA
                                                ? Colors.green.shade900
                                                : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '⚔️ VS ⚔️',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: winner == teamB
                                              ? Colors.green.shade50
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: winner == teamB
                                                ? Colors.green
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          teamB,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: winner == teamB
                                                ? Colors.green.shade900
                                                : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // أزرار المالك لحسم الفائز وتصعيده
                                if (isOwner &&
                                    winner == null &&
                                    !teamA.contains('بانتظار') &&
                                    !teamB.contains('بانتظار')) ...[
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'حسم الفائز: ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor: const Color(0xFF1B5E20),
                                          side: const BorderSide(color: Color(0xFF1B5E20)),
                                        ),
                                        onPressed: () => _declareWinner(
                                          context,
                                          tournamentId,
                                          matchId,
                                          teamA,
                                          currentMatches,
                                        ),
                                        child: Text(
                                          isFinal ? 'تتويج $teamA باللقب 🏆' : 'فوز $teamA',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor: const Color(0xFF1B5E20),
                                          side: const BorderSide(color: Color(0xFF1B5E20)),
                                        ),
                                        onPressed: () => _declareWinner(
                                          context,
                                          tournamentId,
                                          matchId,
                                          teamB,
                                          currentMatches,
                                        ),
                                        child: Text(
                                          isFinal ? 'تتويج $teamB باللقب 🏆' : 'فوز $teamB',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (winner != null) ...[
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      isFinal
                                          ? '🎉 بطل الكأس المتوّج: $winner 🎉'
                                          : 'الفائز المتأهل للدور القادم: $winner ✔️',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isFinal ? Colors.amber.shade900 : Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // نافذة تحديد وتثبيت موعد المباراة للمالك وقفلها بجدول الحجوزات
  void _openScheduleDialog(
    BuildContext context,
    String tId,
    String mId,
    String tA,
    String tB,
    String curDate,
    String curTime,
    List<dynamic> allMatches,
  ) {
    DateTime selDate = curDate.isNotEmpty
        ? (DateTime.tryParse(curDate) ?? DateTime.now())
        : DateTime.now();
    final slots = buildPitchSlots(60);
    String selSlot = slots.contains(curTime) ? curTime : slots.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'تحديد موعد مباراة: $tA ⚔️ $tB',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF1B5E20)),
                  title: Text(
                    'التاريخ: ${DateFormat('yyyy-MM-dd').format(selDate)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Text(
                    'تغيير 📅',
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: selDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (p != null) setS(() => selDate = p);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selSlot,
                  decoration: const InputDecoration(
                    labelText: 'الوقت',
                    border: OutlineInputBorder(),
                  ),
                  items: slots
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (v) => setS(() => selSlot = v!),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final dateStr = DateFormat('yyyy-MM-dd').format(selDate);
                    final times = selSlot.split(' - ');
                    final sTime = times[0].trim();
                    final eTime = times.length > 1 ? times[1].trim() : '';

                    final updatedMatches = allMatches.map((m) {
                      if (m['id'] == mId) {
                        final c = Map<String, dynamic>.from(m);
                        c['date'] = dateStr;
                        c['time'] = selSlot;
                        return c;
                      }
                      return m;
                    }).toList();

                    await FirebaseFirestore.instance
                        .collection('tournaments')
                        .doc(tId)
                        .update({'matches': updatedMatches});

                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .doc('tour_${tId}_$mId')
                        .set({
                      'pitchName': pitchName,
                      'teamOne': tA,
                      'teamTwo': tB,
                      'date': dateStr,
                      'startTime': sTime,
                      'endTime': eTime,
                      'price': 0.0,
                      'status': 'tournament_match',
                      'tournamentId': tId,
                      'matchId': mId,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text(
                    'تثبيت وقفل الساعة بالجدول 🔒',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // حسم الفائز وتصعيده آلياً أو إنهاء البطولة إذا كان النهائي
  Future<void> _declareWinner(
    BuildContext context,
    String tId,
    String mId,
    String winningTeam,
    List<dynamic> allMatches,
  ) async {
    // 1. تحديث نتيجة المباراة الحالية
    final updated = allMatches.map((m) {
      if (m['id'] == mId) {
        final c = Map<String, dynamic>.from(m);
        c['winner'] = winningTeam;
        return c;
      }
      return m;
    }).toList();

    // 2. إذا كانت المباراة هي النهائي، يتم اختتام البطولة وتتويج البطل
    if (mId == 'final_match') {
      await FirebaseFirestore.instance.collection('tournaments').doc(tId).update({
        'status': 'completed',
        'champion': winningTeam,
        'matches': updated,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ألف مبروك! تم اختتام البطولة وتتويج ($winningTeam) باللقب! 🏆'),
            backgroundColor: Colors.amber.shade900,
          ),
        );
      }
      return;
    }

    // 3. إذا كانت في الأدوار الإقصائية (دور الـ 16 أو ربع النهائي أو نصف النهائي) -> تصعيد الفائز
    for (var i = 0; i < updated.length; i++) {
      final targetMatchId = updated[i]['id'];

      for (var prev in updated) {
        if (prev['nextMatchId'] == targetMatchId && prev['winner'] != null) {
          if (prev['nextMatchSlot'] == 'teamA') {
            updated[i]['teamA'] = prev['winner'];
          } else if (prev['nextMatchSlot'] == 'teamB') {
            updated[i]['teamB'] = prev['winner'];
          }
        }
      }
    }

    // 4. حفظ التحديث في Firestore
    await FirebaseFirestore.instance.collection('tournaments').doc(tId).update({
      'matches': updated,
    });
  }
}
