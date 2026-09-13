import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../sheets/join_tournament_sheet.dart';
import '../utils/bracket_generator.dart';

class TournamentCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final String userPhone;
  final bool isOwner;
  final VoidCallback onOpenBracket;

  const TournamentCard({
    super.key,
    required this.doc,
    required this.userPhone,
    required this.isOwner,
    required this.onOpenBracket,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final title = data['title'] ?? 'بطولة كروية';
    final pitchName = data['pitchName'] ?? '';
    final teams = List<String>.from(data['teams'] ?? []);
    final registeredPlayers = Map<String, dynamic>.from(data['registeredPlayers'] ?? {});
    final maxTeams = data['maxTeams'] ?? 8;
    final fee = (data['entryFee'] as num?)?.toDouble() ?? 0.0;
    final prize = data['prize'] ?? 'كأس البطولة';
    final status = data['status'] ?? 'registering';
    final matches = List<dynamic>.from(data['matches'] ?? []);

    // التحقق الدقيق مما إذا كان هاتف اللاعب مسجلاً مسبقاً
    final isJoined = registeredPlayers.containsKey(userPhone);
    final isFull = teams.length >= maxTeams;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: status == 'running' ? Colors.green.shade300 : Colors.amber.shade300,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'running' ? Colors.green.shade50 : (status == 'completed' ? Colors.grey.shade100 : Colors.amber.shade50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: status == 'running' ? Colors.green : (status == 'completed' ? Colors.grey : Colors.amber.shade700)),
                  ),
                  child: Text(
                    status == 'running' ? 'جارية الآن ⚽' : (status == 'completed' ? 'منتهية 🏁' : 'التسجيل مفتوح ⏳'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: status == 'running' ? Colors.green.shade900 : (status == 'completed' ? Colors.grey.shade800 : Colors.amber.shade900),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('📍 الملعب: $pitchName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('👥 الفرق المسجلة: ${teams.length} / $maxTeams', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(fee > 0 ? 'الاشتراك: ${currencyFormatter.format(fee)} د.ع' : 'مجانية 🎉', style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text('🎁 الجائزة: $prize', style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
            const Divider(height: 22),

            Row(
              children: [
                if (matches.isNotEmpty) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.account_tree_rounded, size: 16),
                    label: const Text('شجرة البطولة والمواعيد 📅', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: onOpenBracket,
                  ),
                ],
                const Spacer(),

                // تحكم تسجيل اللاعب
                if (!isOwner && status == 'registering') ...[
                  if (isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green)),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('فريقك مسجل بالبطولة ✔️', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (isFull)
                    const Chip(label: Text('اكتمل العدد ❌', style: TextStyle(fontSize: 11, color: Colors.grey)))
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => JoinTournamentSheet(tournamentRef: doc.reference, userPhone: userPhone, tournamentTitle: title),
                        );
                      },
                      child: const Text('تسجيل فريقي ⚽', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],

                // تحكم المالك ببدء البطولة والقرعة
                if (isOwner && status == 'registering') ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    icon: const Icon(Icons.shuffle_rounded, size: 16),
                    label: const Text('القرعة وجدولة المباريات ⚡', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: teams.length >= 2
                        ? () => _startTournament(context, doc.reference, teams, maxTeams, data['startDate'] ?? '', data['defaultSlot'] ?? '', pitchName, doc.id)
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('يجب تسجيل فريقين على الأقل لإجراء القرعة')),
                            );
                          },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startTournament(BuildContext context, DocumentReference ref, List<String> teams, int maxCapacity, String startDate, String defaultSlot, String pitchName, String tId) async {
    final generatedMatches = BracketGenerator.generateFullBracket(
      registeredTeams: teams,
      maxCapacity: maxCapacity,
      startDate: startDate.isNotEmpty ? startDate : DateFormat('yyyy-MM-dd').format(DateTime.now()),
      defaultSlot: defaultSlot.isNotEmpty ? defaultSlot : '08:00 م - 09:00 م',
    );

    // تثبيت المواعيد الأولى في جدول حجوزات الملعب
    final firestore = FirebaseFirestore.instance;
    for (var m in generatedMatches) {
      final date = m['date'] ?? '';
      final slot = m['time'] ?? '';
      if (date.toString().isNotEmpty && slot.toString().isNotEmpty) {
        final times = slot.toString().split(' - ');
        await firestore.collection('bookings').doc('tour_${tId}_${m['id']}').set({
          'pitchName': pitchName,
          'teamOne': m['teamA'],
          'teamTwo': m['teamB'],
          'date': date,
          'startTime': times[0].trim(),
          'endTime': times.length > 1 ? times[1].trim() : '',
          'price': 0.0,
          'status': 'tournament_match',
          'tournamentId': tId,
          'matchId': m['id'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await ref.update({
      'status': 'running',
      'matches': generatedMatches,
    });
  }
}
