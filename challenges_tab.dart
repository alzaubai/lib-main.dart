import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import '../../../utils/time_parser_util.dart';
import '../../../services/challenge_service.dart';
import '../sheets/create_challenge_sheet.dart';

class ChallengesTab extends StatefulWidget {
  final String userPhone;

  const ChallengesTab({super.key, required this.userPhone});

  @override
  State<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<ChallengesTab> {
  String _selectedGov = 'الكل';

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateChallengeSheet(userPhone: widget.userPhone),
    );
  }

  void _confirmCancel(String challengeId, String teamName) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إلغاء التحدي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: Text('هل أنت متأكد من إلغاء تحدي ($teamName)؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                Navigator.pop(ctx);
                await ChallengeService.cancelChallenge(challengeId);
              },
              child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openAcceptSheet(Map<String, dynamic> challenge, String challengeId) {
    final teamCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('قبول التحدي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أنت على وشك قبول تحدي فريق (${challenge['creatorTeamName']}) بملعب (${challenge['pitchName']}).', style: const TextStyle(fontSize: 12.5)),
                const SizedBox(height: 12),
                TextField(
                  controller: teamCtrl,
                  decoration: InputDecoration(
                    labelText: 'اسم فريقك',
                    prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1B5E20)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(ctx), child: const Text('تراجع', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final tName = teamCtrl.text.trim();
                        if (tName.isEmpty) return;
                        setDialogState(() => isSubmitting = true);

                        final result = await ChallengeService.acceptChallenge(
                          challengeId: challengeId,
                          pitchName: challenge['pitchName'] ?? '',
                          dateStr: challenge['date'] ?? '',
                          startTime: challenge['startTime'] ?? '',
                          endTime: challenge['endTime'] ?? '',
                          creatorTeamName: challenge['creatorTeamName'] ?? 'فريق منافس',
                          pricePerTeam: (challenge['pricePerTeam'] as num?)?.toDouble() ?? 12500.0,
                          acceptedByPhone: widget.userPhone,
                          acceptedTeamName: tName,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.success ? 'تم قبول التحدي وتثبيت الحجز ⚽' : (result.errorMessage ?? 'حدث خطأ')),
                              backgroundColor: result.success ? const Color(0xFF1B5E20) : Colors.red,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('تأكيد القبول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded, size: 18, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: _selectedGov,
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      items: iraqGovernoratesList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => _selectedGov = v!),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('challenges').where('status', isEqualTo: 'open').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final activeChallenges = <QueryDocumentSnapshot>[];
                  for (var doc in docs) {
                    final d = doc.data() as Map<String, dynamic>;

                    // فلترة المحافظة
                    if (_selectedGov != 'الكل' && (d['governorate'] ?? '') != _selectedGov) continue;

                    final date = (d['date'] ?? '').toString();
                    final slot = '${d['startTime']} - ${d['endTime']}';
                    // إخفاء التحديات التي فات وقتها
                    try {
                      final parsedDate = DateFormat('yyyy-MM-dd').parse(date);
                      if (TimeParserUtil.isSlotTimePassed(parsedDate, slot)) continue;
                    } catch (_) {}
                    activeChallenges.add(doc);
                  }

                  activeChallenges.sort((a, b) {
                    final ad = a.data() as Map<String, dynamic>;
                    final bd = b.data() as Map<String, dynamic>;
                    final comp = (ad['date'] ?? '').toString().compareTo((bd['date'] ?? '').toString());
                    if (comp != 0) return comp;
                    return (ad['startTime'] ?? '').toString().compareTo((bd['startTime'] ?? '').toString());
                  });

                  if (activeChallenges.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_kabaddi_rounded, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا توجد تحديات مفتوحة حالياً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          const Text('انشر تحدي جديد وخل الكل يشوفه!', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: activeChallenges.length,
                    itemBuilder: (context, index) {
                      final doc = activeChallenges[index];
                      final d = doc.data() as Map<String, dynamic>;
                      final isMine = d['creatorPhone'] == widget.userPhone;
                      final pitchName = d['pitchName'] ?? 'ملعب';
                      final teamName = d['creatorTeamName'] ?? 'فريق';
                      final date = d['date'] ?? '';
                      final time = '${d['startTime']} - ${d['endTime']}';
                      final price = (d['pricePerTeam'] as num?)?.toDouble() ?? 12500.0;

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(10)),
                                    child: Icon(Icons.sports_kabaddi_rounded, color: Colors.deepOrange.shade700, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(child: Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5), overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: 6),
                                            FutureBuilder<DocumentSnapshot>(
                                              future: FirebaseFirestore.instance.collection('users').doc(d['creatorPhone']).get(),
                                              builder: (context, userSnap) {
                                                if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox();
                                                final rating = ((userSnap.data!.data() as Map<String, dynamic>?)?['teamRating'] as num?)?.toDouble() ?? 5.0;
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                    const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                                                    const SizedBox(width: 2),
                                                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                  ]),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        Text('الملعب: $pitchName', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  if (isMine)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                                      child: const Text('تحديك', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [const Icon(Icons.event_note_rounded, size: 14, color: Color(0xFF1B5E20)), const SizedBox(width: 4), Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                                    Row(children: [const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF1B5E20)), const SizedBox(width: 4), Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.payments_rounded, size: 15, color: Colors.deepOrange.shade700),
                                  const SizedBox(width: 4),
                                  Text('${currencyFormatter.format(price)} د.ع لكل فريق', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade900)),
                                  const Spacer(),
                                  if (isMine)
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      icon: const Icon(Icons.close_rounded, size: 15),
                                      label: const Text('إلغاء', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                      onPressed: () => _confirmCancel(doc.id, teamName),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      icon: const Icon(Icons.sports_soccer_rounded, size: 15),
                                      label: const Text('قبول التحدي', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                      onPressed: () => _openAcceptSheet(d, doc.id),
                                    ),
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
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.deepOrange.shade700,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('تحدي جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _openCreateSheet,
        ),
      ),
    );
  }
}
