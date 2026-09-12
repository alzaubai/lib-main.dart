import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  final currencyFormatter = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: const Text('بطولات ودوريات الملاعب 🏆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('tournaments').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('لا توجد بطولات نشطة حالياً'));

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: docs.length,
              itemBuilder: (context, index) => _buildTournamentCard(docs[index]),
            );
          },
        ),
        floatingActionButton: widget.isOwner
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF1B5E20),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('إطلاق بطولة جديدة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: () => _openCreateTournamentDialog(context),
              )
            : null,
      ),
    );
  }

  Widget _buildTournamentCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'بطولة';
    final prize = data['prize'] ?? 'كأس وميداليات';
    final fee = (data['fee'] as num?)?.toDouble() ?? 25000.0;
    final system = data['tournamentSystem'] ?? 'خروج المغلوب (Knockout)';
    final pitch = data['pitchName'] ?? '';
    final teams = List<String>.from(data['teams'] ?? []);
    final maxTeams = data['maxTeams'] ?? 8;
    final isStarted = data['isStarted'] == true;
    final champion = data['champion'] ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)))),
                Chip(label: Text(system, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
            Text('الملعب: $pitch | الجوائز: $prize'),
            Text('اشتراك الفريق: ${currencyFormatter.format(fee)} د.ع'),
            Text('الفرق المسجلة: ${teams.length} / $maxTeams'),
            if (champion.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text('البطل المتوج: $champion 🏆', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isStarted && teams.length < maxTeams)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                    onPressed: () => _showRegisterTeamDialog(context, doc.reference, teams, maxTeams),
                    child: Text(widget.isOwner ? 'إضافة فريق' : 'تسجيل فريقي', style: const TextStyle(color: Colors.white)),
                  ),
                if (widget.isOwner && !isStarted && teams.length >= 4)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                    onPressed: () => _startTournament(doc.reference, teams),
                    child: const Text('إطلاق القرعة', style: TextStyle(color: Colors.white)),
                  ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournamentId: doc.id, isOwner: widget.isOwner))),
                  child: const Text('عرض المباريات 🌳'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateTournamentDialog(BuildContext context) async {
    final pitchDoc = await _firestore.collection('pitches').doc(widget.pitchName).get();
    final pData = pitchDoc.data() ?? {};
    final nameCtrl = TextEditingController();
    final prizeCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '25000');
    int maxTeams = 8;
    String tournamentSystem = 'خروج المغلوب (Knockout)';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إطلاق بطولة جديدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم البطولة')),
                  TextField(controller: prizeCtrl, decoration: const InputDecoration(labelText: 'الجوائز الكبرى')),
                  TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رسوم الاشتراك')),
                  DropdownButtonFormField<int>(
                    value: maxTeams,
                    decoration: const InputDecoration(labelText: 'عدد الفرق'),
                    items: const [
                      DropdownMenuItem(value: 4, child: Text('4 فرق')),
                      DropdownMenuItem(value: 8, child: Text('8 فرق')),
                    ],
                    onChanged: (v) => setDlgState(() => maxTeams = v ?? 8),
                  ),
                  DropdownButtonFormField<String>(
                    value: tournamentSystem,
                    decoration: const InputDecoration(labelText: 'نظام المنافسة'),
                    items: const [
                      DropdownMenuItem(value: 'خروج المغلوب (Knockout)', child: Text('خروج المغلوب')),
                      DropdownMenuItem(value: 'نظام الدوري / نقاط', child: Text('نظام الدوري (نقاط)')),
                    ],
                    onChanged: (v) => setDlgState(() => tournamentSystem = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    await _firestore.collection('tournaments').add({
                      'name': nameCtrl.text.trim(),
                      'prize': prizeCtrl.text.trim(),
                      'fee': double.tryParse(feeCtrl.text.trim()) ?? 25000.0,
                      'maxTeams': maxTeams,
                      'pitchName': widget.pitchName ?? 'ملعب رياضي',
                      'pitchType': pData['pitchType'] ?? 'سباعي (7 ضد 7)',
                      'surfaceType': pData['surfaceType'] ?? 'ثيل 🌿',
                      'tournamentSystem': tournamentSystem,
                      'teams': [],
                      'isStarted': false,
                      'champion': '',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('إنشاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegisterTeamDialog(BuildContext context, DocumentReference docRef, List<String> teams, int maxTeams) {
    final teamCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل اسم الفريق'),
          content: TextField(controller: teamCtrl, decoration: const InputDecoration(labelText: 'اسم الفريق')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (teamCtrl.text.isNotEmpty && teams.length < maxTeams) {
                  teams.add(teamCtrl.text.trim());
                  await docRef.update({'teams': teams});
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTournament(DocumentReference docRef, List<String> teams) async {
    teams.shuffle();
    List<Map<String, dynamic>> matches = [];
    for (int i = 0; i < teams.length; i += 2) {
      matches.add({
        'team1': teams[i],
        'team2': teams[i + 1],
        'score1': null,
        'score2': null,
        'winner': '',
        'round': teams.length == 8 ? 'ربع النهائي' : 'نصف النهائي',
        'matchIndex': matches.length,
      });
    }
    await docRef.update({'isStarted': true, 'matches': matches});
  }
}

class TournamentDetailsScreen extends StatefulWidget {
  final String tournamentId;
  final bool isOwner;
  const TournamentDetailsScreen({super.key, required this.tournamentId, required this.isOwner});

  @override
  State<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: const Text('شجرة مواجهات البطولة 🌳', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) return const Center(child: Text('البطولة غير موجودة'));

            final matches = List<Map<String, dynamic>>.from(data['matches'] ?? []);
            final champion = data['champion'] ?? '';

            return ListView(
              padding: const EdgeInsets.all(14),
              children: [
                if (champion.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text('الفريق البطل: $champion 🏆', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown))),
                  ),
                const SizedBox(height: 10),
                ...matches.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final m = entry.value;
                  final s1 = m['score1'];
                  final s2 = m['score2'];
                  final winner = m['winner'] ?? '';

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text(m['round'], style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: Text(m['team1'], textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: winner == m['team1'] ? Colors.green : Colors.black))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                child: Text(s1 != null && s2 != null ? '$s1 - $s2' : 'ضد', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: Text(m['team2'], textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: winner == m['team2'] ? Colors.green : Colors.black))),
                            ],
                          ),
                          if (widget.isOwner && winner.isEmpty) ...[
                            const Divider(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                              onPressed: () => _enterScoreDialog(context, idx, matches),
                              child: const Text('تسجيل النتيجة وتحديد الفائز', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  void _enterScoreDialog(BuildContext context, int matchIndex, List<Map<String, dynamic>> matches) {
    final s1 = TextEditingController();
    final s2 = TextEditingController();
    final m = matches[matchIndex];

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('${m['team1']} ضد ${m['team2']}'),
          content: Row(
            children: [
              Expanded(child: TextField(controller: s1, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: m['team1']))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: s2, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: m['team2']))),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final sc1 = int.tryParse(s1.text.trim()) ?? 0;
                final sc2 = int.tryParse(s2.text.trim()) ?? 0;
                if (sc1 == sc2) return;

                matches[matchIndex]['score1'] = sc1;
                matches[matchIndex]['score2'] = sc2;
                matches[matchIndex]['winner'] = sc1 > sc2 ? m['team1'] : m['team2'];

                final currentRound = m['round'];
                final currentRoundMatches = matches.where((match) => match['round'] == currentRound).toList();
                final allFinished = currentRoundMatches.every((match) => match['winner'] != '');

                Map<String, dynamic> updateData = {'matches': matches};

                if (allFinished) {
                  final winners = currentRoundMatches.map((match) => match['winner'].toString()).toList();
                  if (winners.length == 4) {
                    matches.add({'team1': winners[0], 'team2': winners[1], 'score1': null, 'score2': null, 'winner': '', 'round': 'نصف النهائي'});
                    matches.add({'team1': winners[2], 'team2': winners[3], 'score1': null, 'score2': null, 'winner': '', 'round': 'نصف النهائي'});
                  } else if (winners.length == 2 && currentRound != 'المباراة النهائية 🏆') {
                    matches.add({'team1': winners[0], 'team2': winners[1], 'score1': null, 'score2': null, 'winner': '', 'round': 'المباراة النهائية 🏆'});
                  } else if (winners.length == 1 || currentRound == 'المباراة النهائية 🏆') {
                    updateData['champion'] = matches.last['winner'];
                  }
                  updateData['matches'] = matches;
                }

                await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update(updateData);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
