import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: const Text('البطولات والدوريات الشعبية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            if (widget.isOwner)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                tooltip: 'إنشاء بطولة جديدة',
                onPressed: () => _openCreateTournamentDialog(context),
              ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: widget.isOwner && widget.pitchName != null
              ? _firestore.collection('tournaments').where('pitchName', isEqualTo: widget.pitchName).snapshots()
              : _firestore.collection('tournaments').snapshots(),
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
                    Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('لا توجد بطولات قائمة حالياً', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    if (widget.isOwner) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('أنشئ بطولة أو دوري الآن', style: TextStyle(color: Colors.white)),
                        onPressed: () => _openCreateTournamentDialog(context),
                      ),
                    ],
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'بطولة كروية';
                final pitch = data['pitchName'] ?? '';
                final system = data['system'] ?? 'knockout'; // knockout or league
                final teamsMax = data['teamsMax'] ?? 8;
                final List joinedTeams = data['teams'] ?? [];
                final fee = data['entryFee'] ?? 0;
                final prize = data['prize'] ?? 'كأس البطولة ومكافأة';
                final status = data['status'] ?? 'registration'; // registration, running, completed

                final bool isFull = joinedTeams.length >= teamsMax;
                final bool isUserJoined = joinedTeams.any((t) => t['phone'] == widget.userPhone);

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: status == 'registration' ? Colors.blue.shade50 : (status == 'running' ? Colors.green.shade50 : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status == 'registration' ? 'التسجيل مفتوح' : (status == 'running' ? 'جارية الآن' : 'منتهية'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: status == 'registration' ? Colors.blue.shade900 : (status == 'running' ? Colors.green.shade900 : Colors.grey.shade700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                system == 'knockout' ? 'نظام: تسقيط خروج مغلوب' : 'نظام: دوري نقاط (الكل ضد الكل)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('الملعب: $pitch', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('الجائزة: $prize  |  الاشتراك: $fee د.ع', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Icon(Icons.people, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('الفرق المشاركة: ${joinedTeams.length} / $teamsMax', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (widget.isOwner && status == 'registration') ...[
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(horizontal: 8)),
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('إضافة فريق يدوياً', style: TextStyle(fontSize: 12)),
                                onPressed: isFull ? null : () => _openAddManualTeamDialog(context, doc.reference, joinedTeams),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (!widget.isOwner && status == 'registration') ...[
                              if (isUserJoined)
                                const Chip(label: Text('فريقك مسجل ✔️', style: TextStyle(color: Colors.green, fontSize: 11)))
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: isFull ? Colors.grey : const Color(0xFF1B5E20)),
                                  onPressed: isFull ? null : () => _joinTournamentDialog(context, doc.reference, joinedTeams),
                                  child: const Text('تسجيل فريقي', style: TextStyle(color: Colors.white)),
                                ),
                            ],
                            if (widget.isOwner && status == 'registration' && joinedTeams.length >= 2) ...[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                                onPressed: () => _startTournamentAndBuildMatches(doc.reference, joinedTeams, system),
                                child: const Text('بدء وجدولة المباريات', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                            if (status != 'registration') ...[
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                                icon: const Icon(Icons.table_chart, size: 16, color: Colors.white),
                                label: Text(system == 'league' ? 'جدول الترتيب والمباريات' : 'شجرة المواجهات', style: const TextStyle(color: Colors.white)),
                                onPressed: () => _openMatchesAndTableScreen(context, doc, system),
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
      ),
    );
  }

  void _openCreateTournamentDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final prizeCtrl = TextEditingController(text: 'كأس المركز الأول ومكافأة مالية');
    final feeCtrl = TextEditingController(text: '25000');
    String chosenSystem = 'knockout';
    int teamsMax = 8;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إنشاء منافسة رياضية جديدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم البطولة / الدوري', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: chosenSystem,
                    decoration: const InputDecoration(labelText: 'نظام المنافسة', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'knockout', child: Text('تسقيط فردي (خروج المغلوب)')),
                      DropdownMenuItem(value: 'league', child: Text('دوري عام (الكل ضد الكل بنقاط)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          chosenSystem = val;
                          if (val == 'league' && teamsMax > 10) teamsMax = 6;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: teamsMax,
                    decoration: const InputDecoration(labelText: 'الحد الأقصى لعدد الفرق', border: OutlineInputBorder()),
                    items: chosenSystem == 'knockout'
                        ? const [
                            DropdownMenuItem(value: 8, child: Text('8 فرق')),
                            DropdownMenuItem(value: 16, child: Text('16 فريقاً')),
                          ]
                        : const [
                            DropdownMenuItem(value: 4, child: Text('4 فرق')),
                            DropdownMenuItem(value: 6, child: Text('6 فرق')),
                            DropdownMenuItem(value: 8, child: Text('8 فرق')),
                            DropdownMenuItem(value: 10, child: Text('10 فرق')),
                          ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => teamsMax = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'اشتراك الفريق (د.ع)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: prizeCtrl, decoration: const InputDecoration(labelText: 'الجوائز والمكافآت', border: OutlineInputBorder())),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty) {
                    await _firestore.collection('tournaments').add({
                      'title': titleCtrl.text.trim(),
                      'pitchName': widget.pitchName ?? 'الملعب',
                      'system': chosenSystem,
                      'teamsMax': teamsMax,
                      'entryFee': double.tryParse(feeCtrl.text.trim()) ?? 0,
                      'prize': prizeCtrl.text.trim(),
                      'teams': [],
                      'matches': [],
                      'status': 'registration',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('نشر البطولة', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddManualTeamDialog(BuildContext context, DocumentReference docRef, List currentTeams) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة فريق يدوياً (تسجيل من الملعب)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الفريق', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتف الكابتن (اختياري)', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final tName = nameCtrl.text.trim();
                if (tName.isNotEmpty) {
                  final updated = List.from(currentTeams);
                  updated.add({
                    'teamName': tName,
                    'phone': phoneCtrl.text.trim().isEmpty ? 'سجل حضورياً' : phoneCtrl.text.trim(),
                    'joinedAt': DateTime.now().toIso8601String(),
                  });
                  await docRef.update({'teams': updated});
                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('إضافة وتثبيت الفريق', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _joinTournamentDialog(BuildContext context, DocumentReference docRef, List currentTeams) async {
    final playerDoc = await _firestore.collection('players').doc(widget.userPhone).get();
    final teamName = playerDoc.data()?['teamName'] ?? 'فريق الكابتن';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد تسجيل الفريق بالبطولة'),
          content: Text('هل تريد تسجيل ($teamName) في هذه المنافسة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final updated = List.from(currentTeams);
                updated.add({
                  'teamName': teamName,
                  'phone': widget.userPhone,
                  'joinedAt': DateTime.now().toIso8601String(),
                });
                await docRef.update({'teams': updated});
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('تأكيد التسجيل', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _startTournamentAndBuildMatches(DocumentReference docRef, List teams, String system) async {
    final shuffled = List.from(teams)..shuffle();
    final List<Map<String, dynamic>> generatedMatches = [];
    int matchId = 1;

    if (system == 'knockout') {
      for (int i = 0; i < shuffled.length; i += 2) {
        if (i + 1 < shuffled.length) {
          generatedMatches.add({
            'matchId': matchId++,
            'round': 'الدور الأول',
            'teamA': shuffled[i]['teamName'],
            'teamB': shuffled[i + 1]['teamName'],
            'scoreA': 0,
            'scoreB': 0,
            'isDone': false,
            'winner': null,
          });
        }
      }
    } else {
      // الدوري العام: Round-Robin الكل يلعب ضد الكل
      for (int i = 0; i < shuffled.length; i++) {
        for (int j = i + 1; j < shuffled.length; j++) {
          generatedMatches.add({
            'matchId': matchId++,
            'round': 'مباراة دوري',
            'teamA': shuffled[i]['teamName'],
            'teamB': shuffled[j]['teamName'],
            'scoreA': 0,
            'scoreB': 0,
            'isDone': false,
            'winner': null,
          });
        }
      }
    }

    await docRef.update({
      'status': 'running',
      'matches': generatedMatches,
    });
  }

  void _openMatchesAndTableScreen(BuildContext context, DocumentSnapshot doc, String system) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentDetailsScreen(
          tournamentDoc: doc,
          isOwner: widget.isOwner,
          system: system,
        ),
      ),
    );
  }
}

class TournamentDetailsScreen extends StatefulWidget {
  final DocumentSnapshot tournamentDoc;
  final bool isOwner;
  final String system;

  const TournamentDetailsScreen({
    super.key,
    required this.tournamentDoc,
    required this.isOwner,
    required this.system,
  });

  @override
  State<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.system == 'league' ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.tournamentDoc.reference.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final title = data['title'] ?? '';
        final List matches = data['matches'] ?? [];
        final List teams = data['teams'] ?? [];

        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1B5E20),
              title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              bottom: widget.system == 'league'
                  ? TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.amberAccent,
                      labelColor: Colors.white,
                      tabs: const [
                        Tab(icon: Icon(Icons.leaderboard), text: 'جدول ترتيب النقاط'),
                        Tab(icon: Icon(Icons.sports_soccer), text: 'جدول المباريات والنتائج'),
                      ],
                    )
                  : null,
            ),
            body: widget.system == 'league'
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLeagueTable(teams, matches),
                      _buildMatchesList(matches),
                    ],
                  )
                : _buildMatchesList(matches),
          ),
        );
      },
    );
  }

  Widget _buildLeagueTable(List teams, List matches) {
    // حساب جدول النقاط والإحصائيات لكل فريق
    final Map<String, Map<String, int>> stats = {};

    for (var t in teams) {
      final name = t['teamName'] as String;
      stats[name] = {'played': 0, 'won': 0, 'drawn': 0, 'lost': 0, 'gf': 0, 'ga': 0, 'pts': 0};
    }

    for (var m in matches) {
      if (m['isDone'] == true) {
        final tA = m['teamA'];
        final tB = m['teamB'];
        final sA = m['scoreA'] as int;
        final sB = m['scoreB'] as int;

        if (stats.containsKey(tA) && stats.containsKey(tB)) {
          stats[tA]!['played'] = stats[tA]!['played']! + 1;
          stats[tB]!['played'] = stats[tB]!['played']! + 1;
          stats[tA]!['gf'] = stats[tA]!['gf']! + sA;
          stats[tB]!['gf'] = stats[tB]!['gf']! + sB;
          stats[tA]!['ga'] = stats[tA]!['ga']! + sB;
          stats[tB]!['ga'] = stats[tB]!['ga']! + sA;

          if (sA > sB) {
            stats[tA]!['won'] = stats[tA]!['won']! + 1;
            stats[tA]!['pts'] = stats[tA]!['pts']! + 3;
            stats[tB]!['lost'] = stats[tB]!['lost']! + 1;
          } else if (sB > sA) {
            stats[tB]!['won'] = stats[tB]!['won']! + 1;
            stats[tB]!['pts'] = stats[tB]!['pts']! + 3;
            stats[tA]!['lost'] = stats[tA]!['lost']! + 1;
          } else {
            stats[tA]!['drawn'] = stats[tA]!['drawn']! + 1;
            stats[tB]!['drawn'] = stats[tB]!['drawn']! + 1;
            stats[tA]!['pts'] = stats[tA]!['pts']! + 1;
            stats[tB]!['pts'] = stats[tB]!['pts']! + 1;
          }
        }
      }
    }

    // ترتيب الفرق حسب النقاط، ثم فارق الأهداف
    final sortedTeams = stats.keys.toList()
      ..sort((a, b) {
        final ptsComp = stats[b]!['pts']!.compareTo(stats[a]!['pts']!);
        if (ptsComp != 0) return ptsComp;
        final gdA = stats[a]!['gf']! - stats[a]!['ga']!;
        final gdB = stats[b]!['gf']! - stats[b]!['ga']!;
        return gdB.compareTo(gdA);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
          5: FlexColumnWidth(1),
          6: FlexColumnWidth(1.2),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.green.shade800),
            children: const [
              Padding(padding: EdgeInsets.all(8), child: Text('#', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('الفريق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('لعب', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('فاز', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('تعادل', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('خسر', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('نقاط', textAlign: TextAlign.center, style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))),
            ],
          ),
          ...sortedTeams.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final tName = entry.value;
            final st = stats[tName]!;

            return TableRow(
              decoration: BoxDecoration(color: idx == 1 ? Colors.amber.shade50 : (idx % 2 == 0 ? Colors.grey.shade50 : Colors.white)),
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text('$idx', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: const EdgeInsets.all(8), child: Text(tName, style: TextStyle(fontWeight: FontWeight.bold, color: idx == 1 ? Colors.brown : Colors.black))),
                Padding(padding: const EdgeInsets.all(8), child: Text('${st['played']}', textAlign: TextAlign.center)),
                Padding(padding: const EdgeInsets.all(8), child: Text('${st['won']}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.green))),
                Padding(padding: const EdgeInsets.all(8), child: Text('${st['drawn']}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.orange))),
                Padding(padding: const EdgeInsets.all(8), child: Text('${st['lost']}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                Padding(padding: const EdgeInsets.all(8), child: Text('${st['pts']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMatchesList(List matches) {
    if (matches.isEmpty) return const Center(child: Text('لا توجد مباريات بعد'));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: matches.length,
      itemBuilder: (context, idx) {
        final m = matches[idx] as Map<String, dynamic>;
        final teamA = m['teamA'] ?? 'فريق 1';
        final teamB = m['teamB'] ?? 'فريق 2';
        final scoreA = m['scoreA'] ?? 0;
        final scoreB = m['scoreB'] ?? 0;
        final bool isDone = m['isDone'] == true;
        final winner = m['winner'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDone ? Colors.grey.shade50 : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text('مباراة #${m['matchId']} (${m['round']})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(teamA, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: winner == teamA ? Colors.green : Colors.black)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                      child: Text('$scoreA - $scoreB', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text(teamB, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: winner == teamB ? Colors.green : Colors.black)),
                    ),
                  ],
                ),
                if (isDone && winner != null) ...[
                  const SizedBox(height: 6),
                  Text('الفائز: $winner 🏆', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
                if (widget.isOwner) ...[
                  const Divider(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: Text(isDone ? 'تعديل النتيجة' : 'تسجيل النتيجة', style: const TextStyle(color: Colors.white)),
                    onPressed: () => _openSetResultDialog(context, idx, matches, teamA, teamB),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSetResultDialog(BuildContext context, int matchIndex, List matches, String teamA, String teamB) {
    final scoreACtrl = TextEditingController(text: '${matches[matchIndex]['scoreA'] ?? 0}');
    final scoreBCtrl = TextEditingController(text: '${matches[matchIndex]['scoreB'] ?? 0}');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل وحفظ النتيجة'),
          content: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(teamA, style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextField(controller: scoreACtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center),
                  ],
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('ضد', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(teamB, style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextField(controller: scoreBCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final scA = int.tryParse(scoreACtrl.text.trim()) ?? 0;
                final scB = int.tryParse(scoreBCtrl.text.trim()) ?? 0;

                if (widget.system == 'knockout' && scA == scB) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نظام خروج المغلوب يتطلب فائزاً (ركلات ترجيح)')));
                  return;
                }

                final updatedMatches = List.from(matches);
                updatedMatches[matchIndex]['scoreA'] = scA;
                updatedMatches[matchIndex]['scoreB'] = scB;
                updatedMatches[matchIndex]['isDone'] = true;
                updatedMatches[matchIndex]['winner'] = scA > scB ? teamA : (scB > scA ? teamB : 'تعادل');

                await widget.tournamentDoc.reference.update({'matches': updatedMatches});
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('تأكيد وحفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
