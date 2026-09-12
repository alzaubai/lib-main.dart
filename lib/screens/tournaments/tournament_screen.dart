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
          stream: _firestore
              .collection('tournaments')
              .where('isArchived', isNotEqualTo: true)
              .snapshots(),
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
                      const Text('اضغط الزر أدناه لإطلاق بطولة جديدة لملعبك', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
    final system = data['tournamentSystem'] ?? 'خروج المغلوب (Knockout)';
    final pitch = data['pitchName'] ?? '';
    final teams = List<String>.from(data['teams'] ?? []);
    final maxTeams = data['maxTeams'] ?? 8;
    final isStarted = data['isStarted'] == true;
    final champion = data['champion'] ?? '';
    final startDate = data['startDate'] ?? 'غير محدد';
    final matchesPerDay = data['matchesPerDay'] ?? 2;

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
                  label: Text(system, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.amber.shade100,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('الملعب المنظم: $pitch', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text('تاريخ الانطلاق: $startDate (بمعدل $matchesPerDay مباراة/يوم)', style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('الجوائز الكبرى: $prize', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13)),
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
                if (widget.isOwner && !isStarted && teams.length >= 2) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => doc.reference.delete(),
                    child: const Text('حذف'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                    onPressed: () => _startTournamentAndSchedule(doc.reference, data),
                    child: const Text('إطلاق القرعة وتثبيت المواعيد 📅', style: TextStyle(color: Colors.white)),
                  ),
                ],
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B5E20)),
                  icon: const Icon(Icons.account_tree_rounded),
                  label: Text(isStarted ? 'عرض الشجرة والمباريات' : 'التفاصيل والفرق'),
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
    int matchesPerDay = 2;
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    String startTimeSlot = '08:00 م';
    String tournamentSystem = 'خروج المغلوب (Knockout)';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))
              ],
            ),
            padding: EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.shade200)),
                        child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إطلاق بطولة جديدة وجدولتها 🏆', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                          Text('حدد المواعيد لربطها بجدول الحجوزات تلقائياً', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'اسم البطولة',
                      hintText: 'مثال: كأس الصيف الليلي',
                      prefixIcon: const Icon(Icons.sports_soccer, color: Color(0xFF1B5E20)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: prizeCtrl,
                          decoration: InputDecoration(
                            labelText: 'الجوائز الكبرى',
                            prefixIcon: const Icon(Icons.card_giftcard, color: Colors.amber),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: feeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'اشتراك الفريق (د.ع)',
                            prefixIcon: const Icon(Icons.payments, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // تاريخ ووقت الانطلاق
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF1F8F1), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('جدولة انطلاق أول مباراة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                  );
                                  if (p != null) setModalState(() => startDate = p);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month, color: Color(0xFF1B5E20), size: 18),
                                      const SizedBox(width: 6),
                                      Text(DateFormat('yyyy-MM-dd').format(startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: startTimeSlot,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: ['07:00 م', '08:00 م', '09:00 م', '10:00 م', '11:00 م'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (v) => setModalState(() => startTimeSlot = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('عدد المباريات في اليوم الواحد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(
                          children: [1, 2, 3, 4].map((count) {
                            final sel = matchesPerDay == count;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ChoiceChip(
                                label: Text('$count يومياً', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.black87)),
                                selected: sel,
                                selectedColor: const Color(0xFF1B5E20),
                                onSelected: (val) {
                                  if (val) setModalState(() => matchesPerDay = count);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('عدد الفرق المشاركة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [4, 8, 12, 16].map((count) {
                      final isSelected = maxTeams == count;
                      return ChoiceChip(
                        label: Text('$count فرق', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1B5E20),
                        onSelected: (selected) {
                          if (selected) setModalState(() => maxTeams = count);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى كتابة اسم البطولة')));
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                final pName = widget.pitchName ?? 'ملعب عام';
                                final fee = double.tryParse(feeCtrl.text.trim()) ?? 25000.0;
                                final prize = prizeCtrl.text.trim().isEmpty ? 'كأس وميداليات' : prizeCtrl.text.trim();

                                await _firestore.collection('tournaments').add({
                                  'name': name,
                                  'prize': prize,
                                  'fee': fee,
                                  'maxTeams': maxTeams,
                                  'tournamentSystem': tournamentSystem,
                                  'pitchName': pName,
                                  'startDate': DateFormat('yyyy-MM-dd').format(startDate),
                                  'startTimeSlot': startTimeSlot,
                                  'matchesPerDay': matchesPerDay,
                                  'teams': [],
                                  'isStarted': false,
                                  'isArchived': false,
                                  'champion': '',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر البطولة وحفظ جدولها بنجاح 🏆'), backgroundColor: Colors.green));
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('نشر البطولة وفتح التسجيل 🚀', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(widget.isOwner ? 'إضافة اسم الفريق المشارك' : 'تسجيل فريق بالبطولة'),
          content: TextField(controller: teamCtrl, decoration: const InputDecoration(labelText: 'اسم الفريق', border: OutlineInputBorder())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final tName = teamCtrl.text.trim();
                if (tName.isNotEmpty && teams.length < maxTeams) {
                  teams.add(tName);
                  await docRef.update({'teams': teams});
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // إطلاق القرعة وحجز الساعات تلقائياً في مجموعة bookings
  Future<void> _startTournamentAndSchedule(DocumentReference docRef, Map<String, dynamic> data) async {
    final teams = List<String>.from(data['teams'] ?? []);
    if (teams.length < 2) return;

    teams.shuffle();
    final pName = data['pitchName'] ?? '';
    final tourName = data['name'] ?? 'البطولة';
    final sDateStr = data['startDate'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final matchesPerDay = (data['matchesPerDay'] as num?)?.toInt() ?? 2;
    DateTime currentMatchDay = DateTime.tryParse(sDateStr) ?? DateTime.now();

    final List<String> slotsPool = ['07:00 م', '08:00 م', '09:00 م', '10:00 م', '11:00 م', '12:00 ص'];
    int slotIndexBase = 1; // 08:00 م

    List<Map<String, dynamic>> matches = [];
    int matchCounterOnDay = 0;

    for (int i = 0; i < teams.length; i += 2) {
      if (i + 1 < teams.length) {
        final t1 = teams[i];
        final t2 = teams[i + 1];

        String sTime = slotsPool[(slotIndexBase + matchCounterOnDay) % slotsPool.length];
        String eTime = slotsPool[(slotIndexBase + matchCounterOnDay + 1) % slotsPool.length];
        String mDate = DateFormat('yyyy-MM-dd').format(currentMatchDay);

        matches.add({
          'team1': t1,
          'team2': t2,
          'score1': null,
          'score2': null,
          'winner': '',
          'round': teams.length == 16 ? 'ثمن النهائي' : (teams.length == 8 ? 'ربع النهائي' : 'نصف النهائي'),
          'matchDate': mDate,
          'matchSlot': '$sTime - $eTime',
        });

        // حجز الموعد تلقائياً في السيرفر ليظهر أحمر للكباتن
        await _firestore.collection('bookings').add({
          'pitchName': pName,
          'teamOne': '$t1 (🏆 $tourName)',
          'teamTwo': t2,
          'date': mDate,
          'startTime': sTime,
          'endTime': eTime,
          'price': 0.0,
          'status': 'tournament_match', // حالة مميزة للبطولة
          'createdAt': FieldValue.serverTimestamp(),
        });

        matchCounterOnDay++;
        if (matchCounterOnDay >= matchesPerDay) {
          matchCounterOnDay = 0;
          currentMatchDay = currentMatchDay.add(const Duration(days: 1));
        }
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
                        if (widget.isOwner) ...[
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade800, foregroundColor: Colors.white),
                            icon: const Icon(Icons.archive_outlined),
                            label: const Text('أرشفة البطولة وإنهاؤها 🏁', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update({
                                'isArchived': true,
                              });
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنهاء وأرشفة البطولة بنجاح'), backgroundColor: Colors.green));
                              }
                            },
                          ),
                        ],
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
                      final mDate = m['matchDate'] ?? '';
                      final mSlot = m['matchSlot'] ?? '';

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(m['round'] ?? 'مباراة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  if (mDate.isNotEmpty)
                                    Text('📅 $mDate ($mSlot)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(t1, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: winner == t1 ? Colors.green.shade800 : Colors.black87)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Text(s1 != null && s2 != null ? '$s1 - $s2' : 'ضد', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
                                  ),
                                  Expanded(
                                    child: Text(t2, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: winner == t2 ? Colors.green.shade800 : Colors.black87)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

                final currentRound = m['round'];
                final currentRoundMatches = matches.where((match) => match['round'] == currentRound).toList();
                final allFinished = currentRoundMatches.every((match) => match['winner'] != '');

                Map<String, dynamic> updateData = {'matches': matches};

                if (allFinished) {
                  final winners = currentRoundMatches.map((match) => match['winner'].toString()).toList();
                  
                  if (winners.length == 8) {
                    for (int i = 0; i < winners.length; i += 2) {
                      matches.add({
                        'team1': winners[i],
                        'team2': winners[i + 1],
                        'score1': null,
                        'score2': null,
                        'winner': '',
                        'round': 'ربع النهائي',
                        'matchIndex': matches.length,
                      });
                    }
                  } else if (winners.length == 4) {
                    matches.add({'team1': winners[0], 'team2': winners[1], 'score1': null, 'score2': null, 'winner': '', 'round': 'نصف النهائي', 'matchIndex': matches.length});
                    matches.add({'team1': winners[2], 'team2': winners[3], 'score1': null, 'score2': null, 'winner': '', 'round': 'نصف النهائي', 'matchIndex': matches.length});
                  } else if (winners.length == 2 && !currentRound.toString().contains('النهائية')) {
                    matches.add({
                      'team1': winners[0],
                      'team2': winners[1],
                      'score1': null,
                      'score2': null,
                      'winner': '',
                      'round': 'المباراة النهائية 🏆',
                      'matchIndex': matches.length,
                    });
                  } else if (winners.length == 1 || currentRound.toString().contains('النهائية')) {
                    updateData['champion'] = matches.last['winner'];
                  }
                  updateData['matches'] = matches;
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
