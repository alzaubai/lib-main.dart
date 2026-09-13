import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';

class TournamentScreen extends StatefulWidget {
  final String userPhone;
  final bool isOwner;
  final String? pitchName;

  const TournamentScreen({
    super.key,
    required this.userPhone,
    required this.isOwner,
    this.pitchName,
  });

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat currencyFormatter = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: StreamBuilder<QuerySnapshot>(
          stream: widget.isOwner && widget.pitchName != null
              ? _firestore
                  .collection('tournaments')
                  .where('pitchName', isEqualTo: widget.pitchName)
                  .snapshots()
              : _firestore.collection('tournaments').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.emoji_events_outlined, size: 60, color: Colors.amber.shade700),
                    ),
                    const SizedBox(height: 14),
                    const Text('لا توجد بطولات نشطة حالياً',
                        style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (widget.isOwner) ...[
                      const SizedBox(height: 8),
                      const Text('اضغط على الزر بالأسفل لإنشاء بطولة جديدة وإطلاقها 🏆',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'بطولة كروية';
                final pName = data['pitchName'] ?? '';
                final teams = List<String>.from(data['teams'] ?? []);
                final maxTeams = data['maxTeams'] ?? 8;
                final fee = (data['entryFee'] as num?)?.toDouble() ?? 0.0;
                final prize = data['prize'] ?? 'كأس البطولة + جوائز عينية';
                final status = data['status'] ?? 'registering'; // registering, running, completed
                final matches = List<dynamic>.from(data['matches'] ?? []);

                final isJoined = teams.contains(widget.userPhone);
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
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'running'
                                    ? Colors.green.shade50
                                    : (status == 'completed' ? Colors.grey.shade100 : Colors.amber.shade50),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: status == 'running'
                                      ? Colors.green
                                      : (status == 'completed' ? Colors.grey : Colors.amber.shade700),
                                ),
                              ),
                              child: Text(
                                status == 'running'
                                    ? 'جارية الآن ⚽'
                                    : (status == 'completed' ? 'منتهية 🏁' : 'التسجيل مفتوح ⏳'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'running'
                                      ? Colors.green.shade900
                                      : (status == 'completed' ? Colors.grey.shade800 : Colors.amber.shade900),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('📍 الملعب: $pName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('👥 الفرق المسجلة: ${teams.length} / $maxTeams',
                                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text(
                              fee > 0 ? 'اشتراك الفريق: ${currencyFormatter.format(fee)} د.ع' : 'الدخول مجاني 🎉',
                              style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('🎁 الجائزة: $prize', style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                        const Divider(height: 22),

                        // شريط الإجراءات (دخول الكابتن / عرض القرعة والمواعيد / بدء البطولة للمالك)
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
                                label: const Text('المواجهات والمواعيد 📅', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _openBracketDialog(doc.id, title, pName, matches),
                              ),
                            ],
                            const Spacer(),
                            if (!widget.isOwner && status == 'registering') ...[
                              if (isJoined)
                                const Chip(
                                  label: Text('فريقك مسجل ✔️', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.green,
                                )
                              else if (isFull)
                                const Chip(
                                  label: Text('اكتمل العدد ❌', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  backgroundColor: Color(0xFFEEEEEE),
                                )
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _joinTournamentDialog(doc.reference, teams, maxTeams),
                                  child: const Text('تسجيل فريقي ⚽', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                            ],
                            if (widget.isOwner && status == 'registering') ...[
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.shuffle_rounded, size: 16),
                                label: const Text('إجراء القرعة وبدء البطولة ⚡', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: teams.length >= 2
                                    ? () => _generateBracketAndStart(doc.reference, teams, pName, doc.id)
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
              },
            );
          },
        ),
        floatingActionButton: widget.isOwner
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إنشاء بطولة جديدة 🏆', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _openCreateTournamentSheet(context),
              )
            : null,
      ),
    );
  }

  // نافذة عرض جدول المواجهات والمواعيد بالتاريخ والساعة
  void _openBracketDialog(String tournamentId, String title, String pitchName, List<dynamic> matches) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Directionality(
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
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                          const Text('جدول المواجهات والتوقيت الزمني لكل مباراة', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('tournaments').doc(tournamentId).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final tData = snap.data!.data() as Map<String, dynamic>? ?? {};
                      final currentMatches = List<dynamic>.from(tData['matches'] ?? []);

                      if (currentMatches.isEmpty) {
                        return const Center(child: Text('لم يتم توليد المباريات'));
                      }

                      return ListView.builder(
                        itemCount: currentMatches.length,
                        itemBuilder: (context, idx) {
                          final match = currentMatches[idx] as Map<String, dynamic>;
                          final matchId = match['id'] ?? '';
                          final teamA = match['teamA'] ?? 'بانتظار المتأهل';
                          final teamB = match['teamB'] ?? 'بانتظار المتأهل';
                          final winner = match['winner'];
                          final matchDate = match['date'] ?? '';
                          final matchTime = match['time'] ?? '';
                          final round = match['round'] ?? 'مباراة دور';
                          final hasSchedule = matchDate.toString().isNotEmpty && matchTime.toString().isNotEmpty;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: winner != null
                                    ? Colors.green.shade400
                                    : (hasSchedule ? Colors.blue.shade300 : Colors.grey.shade300),
                                width: 1.2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  // شريط الوقت والتاريخ الواضح
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: hasSchedule ? Colors.blue.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: hasSchedule ? Colors.blue.shade200 : Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          hasSchedule ? Icons.alarm_on_rounded : Icons.schedule_rounded,
                                          size: 16,
                                          color: hasSchedule ? Colors.blue.shade800 : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            hasSchedule
                                                ? '📅 التاريخ: $matchDate  |  ⏰ الوقت: $matchTime'
                                                : 'لم يُحدد الموعد بعد من قِبل إدارة الملعب ⏳',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: hasSchedule ? Colors.blue.shade900 : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        if (widget.isOwner && winner == null)
                                          InkWell(
                                            onTap: () => _openScheduleSheet(
                                              tournamentId,
                                              matchId,
                                              teamA,
                                              teamB,
                                              matchDate,
                                              matchTime,
                                              currentMatches,
                                              pitchName,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1B5E20),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                hasSchedule ? 'تغيير ⏱️' : 'تحديد موعد 📅',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: winner == teamA ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: winner == teamA ? Colors.green : Colors.grey.shade300),
                                          ),
                                          child: Text(
                                            teamA,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: winner == teamA ? Colors.green.shade900 : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                        child: Text('⚔️ VS ⚔️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: winner == teamB ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: winner == teamB ? Colors.green : Colors.grey.shade300),
                                          ),
                                          child: Text(
                                            teamB,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: winner == teamB ? Colors.green.shade900 : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // خيارات المالك لتسجيل الفائز
                                  if (widget.isOwner && winner == null && teamA != 'بانتظار المتأهل' && teamB != 'بانتظار المتأهل') ...[
                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('حسم المباراة: ', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 6),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                          onPressed: () => _declareWinner(tournamentId, matchId, teamA, currentMatches),
                                          child: Text('فوز $teamA', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 6),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                          onPressed: () => _declareWinner(tournamentId, matchId, teamB, currentMatches),
                                          child: Text('فوز $teamB', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ] else if (winner != null) ...[
                                    const SizedBox(height: 6),
                                    Text('الفائز المتأهل: $winner 🏆',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نافذة جدولة وحجز موعد مباراة البطولة
  void _openScheduleSheet(
    String tournamentId,
    String matchId,
    String teamA,
    String teamB,
    String curDate,
    String curTime,
    List<dynamic> allMatches,
    String pitchName,
  ) {
    DateTime selectedDate = curDate.isNotEmpty ? (DateTime.tryParse(curDate) ?? DateTime.now()) : DateTime.now();
    final slots = buildPitchSlots(60);
    String selectedSlot = slots.contains(curTime) ? curTime : slots.first;

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
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 14),
                Text('تحديد موعد مباراة: $teamA ⚔️ $teamB',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20))),
                const SizedBox(height: 14),
                ListTile(
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF1B5E20)),
                  title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  trailing: const Text('تغيير 📅', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (p != null) setS(() => selectedDate = p);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSlot,
                  decoration: const InputDecoration(labelText: 'توقيت الساعة', border: OutlineInputBorder()),
                  items: slots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setS(() => selectedSlot = v!),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                    final times = selectedSlot.split(' - ');
                    final sTime = times[0].trim();
                    final eTime = times.length > 1 ? times[1].trim() : '';

                    // 1. تحديث الموعد بالبطولة
                    final updatedMatches = allMatches.map((m) {
                      if (m['id'] == matchId) {
                        final copy = Map<String, dynamic>.from(m);
                        copy['date'] = dateStr;
                        copy['time'] = selectedSlot;
                        return copy;
                      }
                      return m;
                    }).toList();

                    await _firestore.collection('tournaments').doc(tournamentId).update({
                      'matches': updatedMatches,
                    });

                    // 2. قفل وحجز الساعة في جدول حجوزات الملعب تلقائياً
                    await _firestore.collection('bookings').doc('tour_${tournamentId}_$matchId').set({
                      'pitchName': pitchName,
                      'teamOne': teamA,
                      'teamTwo': teamB,
                      'date': dateStr,
                      'startTime': sTime,
                      'endTime': eTime,
                      'price': 0.0,
                      'status': 'tournament_match',
                      'tournamentId': tournamentId,
                      'matchId': matchId,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تثبيت موعد المباراة وحجزها في الجدول بنجاح ⚽'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: const Text('تثبيت الموعد وقفل الساعة بالجدول 🔒', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // تصعيد الفائز
  Future<void> _declareWinner(String tournamentId, String matchId, String winningTeam, List<dynamic> allMatches) async {
    final updatedMatches = allMatches.map((m) {
      if (m['id'] == matchId) {
        final copy = Map<String, dynamic>.from(m);
        copy['winner'] = winningTeam;
        return copy;
      }
      return m;
    }).toList();

    for (var i = 0; i < updatedMatches.length; i++) {
      if (updatedMatches[i]['nextMatchId'] == matchId) {
        if (updatedMatches[i]['teamA'] == 'بانتظار المتأهل') {
          updatedMatches[i]['teamA'] = winningTeam;
        } else if (updatedMatches[i]['teamB'] == 'بانتظار المتأهل') {
          updatedMatches[i]['teamB'] = winningTeam;
        }
      }
    }

    await _firestore.collection('tournaments').doc(tournamentId).update({
      'matches': updatedMatches,
    });
  }

  // تسجيل فريق الكابتن في البطولة
  void _joinTournamentDialog(DocumentReference docRef, List<String> currentTeams, int maxTeams) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تسجيل فريق في البطولة ⚽'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم فريقك الرسمي', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final tName = nameCtrl.text.trim();
                if (tName.isNotEmpty) {
                  await docRef.update({
                    'teams': FieldValue.arrayUnion([tName]),
                  });
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('تأكيد الاشتراك', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // إجراء القرعة العشوائية وبدء البطولة
  Future<void> _generateBracketAndStart(DocumentReference docRef, List<String> teams, String pitchName, String tId) async {
    final shuffled = List<String>.from(teams)..shuffle();
    final List<Map<String, dynamic>> generatedMatches = [];

    int matchIndex = 1;
    for (int i = 0; i < shuffled.length; i += 2) {
      final teamA = shuffled[i];
      final teamB = (i + 1 < shuffled.length) ? shuffled[i + 1] : 'باي (تأهل تلقائي)';
      generatedMatches.add({
        'id': 'm_$matchIndex',
        'teamA': teamA,
        'teamB': teamB,
        'winner': teamB.contains('تأهل تلقائي') ? teamA : null,
        'date': '',
        'time': '',
        'round': 'الدور الأول',
      });
      matchIndex++;
    }

    await docRef.update({
      'status': 'running',
      'matches': generatedMatches,
    });
  }

  // شيت إنشاء بطولة جديدة لصاحب الملعب
  void _openCreateTournamentSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '50000');
    final prizeCtrl = TextEditingController(text: 'كأس البطولة + 250,000 د.ع');
    int maxTeams = 8;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.only(top: 16, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 16),
                  const Text('إطلاق بطولة جديدة بالملعب 🏆',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 14),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم البطولة', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: maxTeams,
                          decoration: const InputDecoration(labelText: 'عدد الفرق', border: OutlineInputBorder()),
                          items: [4, 8, 16].map((n) => DropdownMenuItem(value: n, child: Text('$n فرق'))).toList(),
                          onChanged: (v) => setM(() => maxTeams = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'اشتراك الفريق (د.ع)', border: OutlineInputBorder())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: prizeCtrl, decoration: const InputDecoration(labelText: 'الجوائز', border: OutlineInputBorder())),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isNotEmpty) {
                        await _firestore.collection('tournaments').add({
                          'title': titleCtrl.text.trim(),
                          'pitchName': widget.pitchName,
                          'maxTeams': maxTeams,
                          'entryFee': double.tryParse(feeCtrl.text.trim()) ?? 0.0,
                          'prize': prizeCtrl.text.trim(),
                          'status': 'registering',
                          'teams': [],
                          'matches': [],
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('نشر البطولة وفتح التسجيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
