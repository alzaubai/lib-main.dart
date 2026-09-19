import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/tournament_service.dart';
import '../dialogs/manual_add_team_dialog.dart';
import '../dialogs/tournament_teams_dialog.dart';

class TournamentCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool isOwner;
  final String userPhone;
  final VoidCallback? onOpenBracket;

  const TournamentCard({
    super.key,
    required this.doc,
    required this.isOwner,
    required this.userPhone,
    this.onOpenBracket,
  });

  void _confirmDelete(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف البطولة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text('هل أنت متأكد من حذف بطولة ($title) وتفريغ مبارياتها من الجدول؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await TournamentService.deleteTournament(doc.id, title);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'تم حذف البطولة وتفريغ جدولها' : 'تعذر الحذف'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmWithdraw(BuildContext context, String tournamentId, String teamName) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('الانسحاب من البطولة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text('هل أنت متأكد من انسحاب فريقك ($teamName) من هذه البطولة؟ سيتم إتاحة مقعدكم لفريق آخر.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                Navigator.pop(ctx);
                await TournamentService.withdrawOwnTeam(tournamentId: tournamentId, userPhone: userPhone, teamName: teamName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الانسحاب من البطولة'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              child: const Text('تأكيد الانسحاب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegisterSheet(BuildContext context, String title) {
    final teamCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تسجيل فريق في ($title)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              TextField(
                controller: teamCtrl,
                decoration: InputDecoration(
                  labelText: 'اسم فريقك',
                  prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1B5E20)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  final tName = teamCtrl.text.trim();
                  if (tName.isEmpty) return;
                  Navigator.pop(ctx);
                  await TournamentService.registerPlayerTeam(tournamentId: doc.id, userPhone: userPhone, teamName: tName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل فريقك بنجاح'), behavior: SnackBarBehavior.floating));
                  }
                },
                child: const Text('تأكيد الاشتراك', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
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
    final prize = data['prize'] ?? 'كأس وجوائز قيمة';
    final rules = data['rules'] ?? '';
    final status = data['status'] ?? 'registering';
    final registeredPlayers = Map<String, dynamic>.from(data['registeredPlayers'] ?? {});
    final isFull = teams.length >= maxTeams;
    final isRegistered = registeredPlayers.containsKey(userPhone);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Card(
        elevation: 1.5,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text('الملعب: $pitchName', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                  if (isOwner) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                      onSelected: (val) { if (val == 'delete') _confirmDelete(context, title); },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18), SizedBox(width: 8), Text('حذف البطولة', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الفرق: ${teams.length} من $maxTeams', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  Text(isFull ? 'المقاعد مكتملة' : 'متبقي ${maxTeams - teams.length}', style: TextStyle(fontSize: 11, color: isFull ? Colors.red : Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: maxTeams > 0 ? (teams.length / maxTeams) : 0,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: isFull ? Colors.red : const Color(0xFF1B5E20),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الجائزة: $prize', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    if (rules.toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('الشروط: $rules', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isOwner) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      icon: const Icon(Icons.groups_rounded, size: 15),
                      label: const Text('إدارة الفرق', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () => TournamentTeamsDialog.show(context, tournamentId: doc.id, tournamentTitle: title, teams: teams, registeredPlayers: registeredPlayers),
                    ),
                    const SizedBox(width: 6),
                    if (!isFull && status == 'registering')
                      InkWell(
                        onTap: () => ManualAddTeamDialog.show(context, tournamentId: doc.id, currentTeams: teams, maxTeams: maxTeams),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1B5E20))),
                          child: const Icon(Icons.add_rounded, color: Color(0xFF1B5E20), size: 18),
                        ),
                      ),
                    const SizedBox(width: 6),
                    if (onOpenBracket != null)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1B5E20), side: const BorderSide(color: Color(0xFF1B5E20)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        icon: const Icon(Icons.account_tree_rounded, size: 15),
                        label: const Text('القرعة والنتائج', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: onOpenBracket,
                      ),
                  ] else ...[
                    if (status == 'registering')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: isRegistered ? Colors.grey : const Color(0xFF1B5E20), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        icon: Icon(isRegistered ? Icons.check_circle_rounded : Icons.app_registration_rounded, size: 15),
                        label: Text(isRegistered ? 'فريقك مسجل' : (isFull ? 'المقاعد مكتملة' : 'تسجيل فريقي'), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: (isRegistered || isFull) ? null : () => _showRegisterSheet(context, title),
                      ),
                    if (isRegistered) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.exit_to_app_rounded, color: Colors.red, size: 20),
                        tooltip: 'الانسحاب من البطولة',
                        style: IconButton.styleFrom(backgroundColor: Colors.red.shade50, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () => _confirmWithdraw(context, doc.id, registeredPlayers[userPhone]?.toString() ?? ''),
                      ),
                    ],
                    if (onOpenBracket != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1B5E20), side: const BorderSide(color: Color(0xFF1B5E20)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        icon: const Icon(Icons.account_tree_rounded, size: 15),
                        label: const Text('جدول المباريات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: onOpenBracket,
                      ),
                    ],
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
      label = 'البطولة جارية';
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
    } else if (status == 'completed') {
      label = 'انتهت البطولة';
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
