import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants.dart';
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

  String _calculateCountdown(String? startDateStr) {
    if (startDateStr == null || startDateStr.isEmpty) return '';
    try {
      final start = DateTime.parse(startDateStr);
      final now = DateTime.now();
      final diffDays = start.difference(DateTime(now.year, now.month, now.day)).inDays;

      if (diffDays > 0) {
        return '⏳ باقي $diffDays أيام على الانطلاق';
      } else if (diffDays == 0) {
        return '🔥 تنطلق اليوم!';
      } else {
        return '⚽ انطلقت بالفعل';
      }
    } catch (_) {
      return '';
    }
  }

  void _launchWazeToPitch(BuildContext context, String pitchName) async {
    final pitchDoc = await FirebaseFirestore.instance.collection('pitches').doc(pitchName).get();
    if (!pitchDoc.exists) return;

    final data = pitchDoc.data() as Map<String, dynamic>;
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();

    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    } else {
      uri = Uri.parse('https://waze.com/ul?q=${Uri.encodeComponent(pitchName)}');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final webUri = Uri.parse(lat != null && lng != null
            ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
            : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(pitchName)}');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\s+|-'), '');
    if (cleanPhone.startsWith('07')) {
      cleanPhone = '964${cleanPhone.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
    final startDate = data['startDate'] ?? '';
    final countdown = _calculateCountdown(startDate);
    final champion = data['champion'];
    final contactPhone = data['phone'] ?? data['ownerPhone'] ?? '';

    final isJoined = registeredPlayers.containsKey(userPhone);
    final isFull = teams.length >= maxTeams;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: status == 'completed'
              ? Colors.amber.shade600
              : (status == 'running' ? Colors.green.shade400 : Colors.blue.shade300),
          width: status == 'completed' ? 2 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status == 'completed' ? Icons.emoji_events : Icons.sports_soccer_rounded,
                  color: status == 'completed' ? Colors.amber.shade800 : const Color(0xFF1B5E20),
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'completed'
                        ? Colors.amber.shade50
                        : (status == 'running' ? Colors.green.shade50 : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: status == 'completed'
                          ? Colors.amber.shade700
                          : (status == 'running' ? Colors.green : Colors.blue.shade300),
                    ),
                  ),
                  child: Text(
                    status == 'completed' ? 'منتهية 🏆' : (status == 'running' ? 'جارية ⚽' : 'التسجيل مفتوح ⏳'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status == 'completed'
                          ? Colors.amber.shade900
                          : (status == 'running' ? Colors.green.shade900 : Colors.blue.shade900),
                    ),
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
                    tooltip: 'حذف البطولة نهائياً',
                    onPressed: () => _confirmDeleteTournament(context),
                  ),
              ],
            ),

            if (status == 'completed' && champion != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.amber.shade100, Colors.amber.shade50]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade500),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🥇', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text('بطل النسخة الرسمية: $champion 🎉',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Text('📍 الملعب: $pitchName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                InkWell(
                  onTap: () => _launchWazeToPitch(context, pitchName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.lightBlue),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.near_me_rounded, color: Colors.blueAccent, size: 14),
                        SizedBox(width: 4),
                        Text('Waze 🗺️', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (startDate.isNotEmpty && status == 'registering') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available, size: 16, color: Colors.deepOrange),
                    const SizedBox(width: 6),
                    Text('الافتتاح: $startDate', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.deepOrange)),
                    const Spacer(),
                    Text(countdown, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.deepOrange)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                Text('👥 الفرق: ${teams.length} / $maxTeams', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  fee > 0 ? 'الاشتراك: ${currencyFormatter.format(fee)} د.ع' : 'مجانية 🎉',
                  style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('🎁 الجائزة: $prize', style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),

            // زر إدارة الفرق المسجلة للمالك
            if (isOwner && teams.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF1B5E20)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                label: Text('إدارة واستبعاد الفرق المسجلة (${teams.length}) 👥', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _openManageTeamsDialog(context, teams, registeredPlayers),
              ),
            ],

            if (!isOwner) ...[
              const SizedBox(height: 10),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('pitches').doc(pitchName).get(),
                builder: (ctx, pSnap) {
                  final fetchedPhone = pSnap.data?.get('phone') ?? '';
                  final targetPhone = (contactPhone.toString().isNotEmpty ? contactPhone : fetchedPhone).toString().trim();

                  if (targetPhone.isEmpty) return const SizedBox.shrink();

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF1B5E20)),
                        const SizedBox(width: 6),
                        const Text('تواصل مع المنظم:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                        const Spacer(),
                        InkWell(
                          onTap: () => _makeCall(targetPhone),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              children: [
                                Icon(Icons.call, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('اتصال', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _openWhatsApp(targetPhone),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              children: [
                                Icon(Icons.chat, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('واتساب', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const Divider(height: 20),

            Row(
              children: [
                if (matches.isNotEmpty) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.account_tree_rounded, size: 16),
                    label: const Text('المواجهات 🏆', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: onOpenBracket,
                  ),
                  const SizedBox(width: 6),
                ],

                if (isOwner && status == 'registering' && !isFull) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    icon: const Icon(Icons.group_add_rounded, size: 16, color: Color(0xFF1B5E20)),
                    label: const Text('إضافة فريق ➕', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    onPressed: () => _openAddManualTeamDialog(context),
                  ),
                ],

                const Spacer(),

                if (!isOwner && status == 'registering') ...[
                  if (isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                      child: const Text('فريقك مسجل ✔️', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    )
                  else if (isFull)
                    const Chip(label: Text('اكتمل العدد ❌', style: TextStyle(fontSize: 11, color: Colors.grey)))
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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

                if (isOwner && status == 'registering') ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: teams.length >= 2
                        ? () => _startTournament(context, doc.reference, teams, maxTeams, startDate, data['defaultSlot'] ?? '', pitchName, doc.id)
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('يجب تسجيل فريقين على الأقل لإجراء القرعة')),
                            );
                          },
                    child: const Text('إجراء القرعة ⚡', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // نافذة إدارة وحذف الفرق المسجلة للمالك
  void _openManageTeamsDialog(BuildContext context, List<String> teams, Map<String, dynamic> registeredPlayers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 14),
                const Text('إدارة الفرق المسجلة بالبطولة 👥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                const Text('يمكنك استبعاد أو حذف أي فريق بناءً على رغبته أو تقييمه:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => const Divider(height: 10),
                    itemBuilder: (context, idx) {
                      final tName = teams[idx];
                      String captainPhone = '';
                      registeredPlayers.forEach((key, val) {
                        if (val == tName && !key.startsWith('manual_')) {
                          captainPhone = key;
                        }
                      });

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F5E9),
                          child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                        ),
                        title: Text(tName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(captainPhone.isNotEmpty ? 'هاتف الكابتن: $captainPhone' : 'فريق مُضاف يدوياً من الإدارة', style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                          tooltip: 'استبعاد الفريق',
                          onPressed: () => _confirmRemoveTeam(context, tName, captainPhone, () {
                            setSheetState(() {
                              teams.remove(tName);
                            });
                          }),
                        ),
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

  void _confirmRemoveTeam(BuildContext context, String teamName, String captainPhone, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('استبعاد هذا الفريق؟'),
          content: Text('هل أنت متأكد من حذف فريق ($teamName) من البطولة؟ سيتم إفساح المجال لفرق أخرى.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final Map<String, dynamic> updatePayload = {
                  'teams': FieldValue.arrayRemove([teamName]),
                };
                if (captainPhone.isNotEmpty) {
                  updatePayload['registeredPlayers.$captainPhone'] = FieldValue.delete();
                }

                await doc.reference.update(updatePayload);
                onSuccess();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('نعم، استبعاد الفريق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddManualTeamDialog(BuildContext context) {
    final teamCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إضافة فريق شعبي للبطولة 👥'),
          content: TextField(
            controller: teamCtrl,
            decoration: const InputDecoration(labelText: 'اسم الفريق', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final name = teamCtrl.text.trim();
                if (name.isNotEmpty) {
                  await doc.reference.update({
                    'teams': FieldValue.arrayUnion([name]),
                    'registeredPlayers.manual_${DateTime.now().millisecondsSinceEpoch}': name,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('إضافة الفريق', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTournament(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف البطولة نهائياً؟ ⚠️'),
          content: const Text('هل أنت متأكد من حذف هذه البطولة؟ سيتم إزالتها فوراً وحذف كافة مبارياتها المحجوزة في جدول الملعب.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final firestore = FirebaseFirestore.instance;
                final bSnap = await firestore.collection('bookings').where('tournamentId', isEqualTo: doc.id).get();
                for (var b in bSnap.docs) {
                  await b.reference.delete();
                }

                await doc.reference.delete();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف البطولة وكافة مبارياتها بنجاح ✔️'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('تأكيد الحذف 🗑️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
