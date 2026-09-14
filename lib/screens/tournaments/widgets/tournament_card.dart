import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dialogs/remove_team_dialog.dart';
import '../dialogs/match_scheduling_dialog.dart';
import '../dialogs/score_input_dialog.dart';
import '../sheets/register_team_sheet.dart';

class TournamentCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool isOwner;
  final String userPhone;

  const TournamentCard({
    super.key,
    required this.doc,
    required this.isOwner,
    required this.userPhone,
  });

  void _openManageTeamsDialog(BuildContext context, Map<String, dynamic> data) {
    final teams = List<String>.from(data['teams'] ?? []);
    final registeredPlayers = Map<String, dynamic>.from(data['registeredPlayers'] ?? {});
    final tournamentName = data['title'] ?? 'البطولة';

    // مطابقة اسم الفريق برقم هاتف الكابتن
    final Map<String, String> teamToPhone = {};
    registeredPlayers.forEach((phone, tName) {
      teamToPhone[tName.toString()] = phone;
    });

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.groups_rounded, color: Color(0xFF1B5E20), size: 22),
              const SizedBox(width: 8),
              Text(
                'الفرق المشاركة (${teams.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: teams.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('لا توجد أي فرق مسجلة بعد', style: TextStyle(color: Colors.grey))),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tName = teams[index];
                      final captainPhone = teamToPhone[tName] ?? '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F5E9),
                          child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        title: Text(tName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          captainPhone.startsWith('manual_') ? 'تسجيل يدوي' : (captainPhone.isNotEmpty ? captainPhone : 'بدون هاتف مسجل'),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_remove_rounded, color: Colors.red),
                          tooltip: 'استبعاد مع كتابة السبب',
                          onPressed: () {
                            Navigator.pop(ctx);
                            RemoveTeamDialog.show(
                              context,
                              tournamentId: doc.id,
                              tournamentName: tournamentName,
                              teamName: tName,
                              captainPhone: captainPhone,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'بطولة كروية';
    final pitchName = data['pitchName'] ?? '';
    final maxTeams = data['maxTeams'] ?? 8;
    final teams = List<String>.from(data['teams'] ?? []);
    final prize = data['prize'] ?? 'كأس البطولة وجوائز قيمة';
    final rules = data['rules'] ?? '';
    final status = data['status'] ?? 'registering'; // registering, active, completed
    final registeredPlayers = Map<String, dynamic>.from(data['registeredPlayers'] ?? {});
    final isFull = teams.length >= maxTeams;
    final isRegistered = registeredPlayers.containsKey(userPhone);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس بطاقة البطولة
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'الملعب: $pitchName',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),

              // شريط تقدم اكتمال الفرق
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'اكتمال الفرق: ${teams.length} من $maxTeams',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                      Text(
                        isFull ? 'المقاعد مكتملة' : 'متبقي ${maxTeams - teams.length} مقاعد',
                        style: TextStyle(fontSize: 11, color: isFull ? Colors.red : Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: maxTeams > 0 ? (teams.length / maxTeams) : 0,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: isFull ? Colors.red : const Color(0xFF1B5E20),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // الجوائز والشروط
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.card_giftcard_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'الجائزة: $prize',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                    if (rules.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'الشروط: $rules',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // الأزرار والإجراءات
              Row(
                children: [
                  if (isOwner) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.groups_rounded, size: 16),
                      label: const Text('إدارة الفرق', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _openManageTeamsDialog(context, data),
                    ),
                    const SizedBox(width: 8),
                    if (status == 'active') ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                        label: const Text('جدولة المباريات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => MatchSchedulingDialog.show(context, doc.id, data),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade800),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.scoreboard_rounded, size: 16),
                        label: const Text('النتائج', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => ScoreInputDialog.show(context, doc.id, data),
                      ),
                    ],
                  ] else ...[
                    if (status == 'registering')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRegistered ? Colors.grey : const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(isRegistered ? Icons.check_circle_rounded : Icons.app_registration_rounded, size: 16),
                        label: Text(
                          isRegistered ? 'أنت مسجل بالبطولة' : (isFull ? 'المقاعد ممتلئة' : 'تسجيل فريقي'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: (isRegistered || isFull)
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => RegisterTeamSheet(
                                    tournamentDocId: doc.id,
                                    userPhone: userPhone,
                                    tournamentTitle: title,
                                  ),
                                );
                              },
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    String label = 'مفتوح للتسجيل';
    Color bg = const Color(0xFFE8F5E9);
    Color fg = const Color(0xFF1B5E20);

    if (status == 'active') {
      label = 'البطولة جارية ⚽';
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
    } else if (status == 'completed') {
      label = 'انتهت البطولة 🏆';
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
