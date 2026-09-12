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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('لا توجد بطولات نشطة حالياً', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (widget.isOwner) ...[
                      const SizedBox(height: 8),
                      const Text('اضغط الزر أدناه لإنشاء بطولة جديدة لملعبك', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ]
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                bool isWideScreen = constraints.maxWidth > 600;

                if (isWideScreen) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) => _buildTournamentCard(docs[index]),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => _buildTournamentCard(docs[index]),
                );
              },
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
    final type = data['type'] ?? 'خروج المغلوب (Knockout)';
    final pitch = data['pitchName'] ?? '';
    final teams = List<String>.from(data['teams'] ?? []);
    final maxTeams = data['maxTeams'] ?? 8;
    final isStarted = data['isStarted'] == true;
    final champion = data['champion'] ?? '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)))),
                Chip(
                  label: Text(type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.amber.shade100,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('الملعب المنظم: $pitch', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text('الجوائز: $prize', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13)),
            Text('اشتراك الفريق: ${currencyFormatter.format(fee)} د.ع', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.group, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('الفرق المسجلة: ${teams.length} / $maxTeams', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            if (champion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                    const SizedBox(width: 8),
                    Expanded(child: Text('بطل البطولة المتوج: $champion 🏆', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900))),
                  ],
                ),
              ),
            ],
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!isStarted && teams.length < maxTeams)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                    icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
                    label: Text(widget.isOwner ? 'إضافة فريق يدوياً' : 'تسجيل فريقي', style: const TextStyle(color: Colors.white)),
                    onPressed: () => _showRegisterTeamDialog(context, doc.reference, teams, maxTeams),
                  ),
                if (widget.isOwner && !isStarted) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => doc.reference.delete(),
                    child: const Text('حذف'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                    onPressed: () => _startTournament(doc.reference, teams),
                    child: const Text('إطلاق القرعة', style: TextStyle(color: Colors.white)),
                  ),
                ],
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B5E20)),
                  icon: const Icon(Icons.account_tree_rounded),
                  label: Text(isStarted ? 'عرض الشجرة' : 'التفاصيل والفرق'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TournamentDetailsScreen(tournamentId: doc.id, isOwner: widget.isOwner),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateTournamentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final prizeCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '25000');
    int maxTeams = 8;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('إطلاق بطولة جديدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم البطولة (مثال: كأس الصيف)')),
                  const SizedBox(height: 10),
                  TextField(controller: prizeCtrl, decoration: const InputDecoration(labelText: 'الجوائز (مثال: 500 ألف + كأس)')),
                  const SizedBox(height: 10),
                  TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رسوم الاشتراك (د.ع)')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: maxTeams,
                    decoration: const InputDecoration(labelText: 'عدد الفرق المشاركة'),
                    items: const [
                      DropdownMenuItem(value: 4, child: Text('4 فرق')),
                      DropdownMenuItem(value: 8, child: Text('8 فرق')),
                      DropdownMenuItem(value: 16, child: Text('16 فريق')),
                    ],
                    onChanged: (v) => setDlgState(() => maxTeams = v ?? 8),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    await _firestore.collection('tournaments').add({
                      'name': nameCtrl.text.trim(),
                      'prize': prizeCtrl.text.trim().isEmpty ? 'كأس البطولة' : prizeCtrl.text.trim(),
                      'fee': double.tryParse(feeCtrl.text.trim()) ?? 25000.0,
                      'maxTeams': maxTeams,
                      'pitchName': widget.pitchName ?? 'ملعب رياضي',
                      'teams': [],
                      'isStarted': false,
                      'champion': '',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('إنشاء ونشر', style: TextStyle(color: Colors.white)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(widget.isOwner ? 'إضافة اسم الفريق المشارك' : 'تسجيل فريق في البطولة'),
          content: TextField(
            controller: teamCtrl,
            decoration: const InputDecoration(labelText: 'اسم الفريق', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final tName = teamCtrl.text.trim();
                if (tName.isNotEmpty && teams.length < maxTeams) {
                  teams.add(tName);
                  await docRef.update({'teams': teams});
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الفريق بنجاح!'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('تأكيد الإضافة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTournament(DocumentReference docRef, List<String> teams) async {
    if (teams.length < 2) return;
    
    teams.shuffle();

    List<Map<String, dynamic>> matches = [];
    for (int i = 0; i < teams.length; i += 2) {
      if (i + 1 < teams.length) {
        matches.add({
          'team1': teams[i],
          'team2': teams[i + 1],
          'score1': null,
          'score2': null,
          'winner': '',
          'round': 'الدور الأول',
          'matchIndex': matches.length,
        });
      }
    }

    await docRef.update({
      'isStarted': true,
      'matches': matches,
    });
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
        backgroundColor: const Color(0xFFF4F6F8),
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
            final teams = List<String>.from(data['teams'] ?? []);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (champion.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade700, width: 2)),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 50),
                        const SizedBox(height: 8),
                        const Text('مبارك التتويج بالبطولة الكبرى!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('الفريق البطل: $champion 🏆', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (matches.isEmpty) ...[
                  const Text('الفرق المسجلة حتى الآن:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  ...teams.map((t) => Card(child: ListTile(leading: const Icon(Icons.sports_soccer), title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold))))),
                ] else ...[
                  const Text('مباريات الشجرة والمواجهات:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final m = matches[index];
                      final t1 = m['team1'] ?? 'فريق 1';
                      final t2 = m['team2'] ?? 'فريق 2';
                      final s1 = m['score1'];
                      final s2 = m['score2'];
                      final winner = m['winner'] ?? '';

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            children: [
                              Text(m['round'] ?? 'مباراة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t1,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: winner == t1 ? Colors.green.shade800 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                      s1 != null && s2 != null ? '$s1 - $s2' : 'ضد',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      t2,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: winner == t2 ? Colors.green.shade800 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.isOwner && winner.isEmpty) ...[
                                const Divider(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                                  onPressed: () => _showEnterScoreDialog(context, index, matches),
                                  child: const Text('إدخال النتيجة وتحديد الفائز', style: TextStyle(color: Colors.white)),
                                ),
                              ] else if (winner.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('الفائز المتأهل: $winner ✔️', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEnterScoreDialog(BuildContext context, int matchIndex, List<Map<String, dynamic>> matches) {
    final s1Ctrl = TextEditingController();
    final s2Ctrl = TextEditingController();
    final m = matches[matchIndex];

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('نتيجة (${m['team1']} ضد ${m['team2']})'),
          content: Row(
            children: [
              Expanded(child: TextField(controller: s1Ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: m['team1']))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
              Expanded(child: TextField(controller: s2Ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: m['team2']))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                int score1 = int.tryParse(s1Ctrl.text.trim()) ?? 0;
                int score2 = int.tryParse(s2Ctrl.text.trim()) ?? 0;

                if (score1 == score2) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن التعادل في مباريات الإقصاء')));
                  return;
                }

                String matchWinner = score1 > score2 ? m['team1'] : m['team2'];

                matches[matchIndex]['score1'] = score1;
                matches[matchIndex]['score2'] = score2;
                matches[matchIndex]['winner'] = matchWinner;

                List<String> currentRoundWinners = matches.where((element) => element['winner'] != '').map((e) => e['winner'].toString()).toList();

                Map<String, dynamic> updateData = {'matches': matches};

                if (currentRoundWinners.length == 2 && matches.length == 3) {
                  matches.add({
                    'team1': currentRoundWinners[0],
                    'team2': currentRoundWinners[1],
                    'score1': null,
                    'score2': null,
                    'winner': '',
                    'round': 'المباراة النهائية الكبرى 🏆',
                    'matchIndex': matches.length,
                  });
                  updateData['matches'] = matches;
                } else if (currentRoundWinners.length == 1 && matches.last['round'].toString().contains('النهائية')) {
                  updateData['champion'] = currentRoundWinners[0];
                }

                await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update(updateData);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ وإعلان الفائز', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
