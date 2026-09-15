import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dialogs/remove_team_dialog.dart';

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

  void _showCenterToast(BuildContext context, String message, {bool isError = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? Colors.redAccent : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // نافذة إدخال عصرية لإضافة فريق يدوياً بواسطة المالك
  void _showManualAddTeamDialog(BuildContext context, String tournamentId, List<String> currentTeams, int maxTeams) {
    if (currentTeams.length >= maxTeams) {
      _showCenterToast(context, 'تم اكتمال العدد الأقصى لفرق البطولة', isError: true);
      return;
    }

    final teamNameCtrl = TextEditingController();
    final captainPhoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.group_add_rounded, color: Color(0xFF1B5E20), size: 22),
              SizedBox(width: 8),
              Text(
                'إضافة فريق للبطولة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: teamNameCtrl,
                decoration: InputDecoration(
                  labelText: 'اسم الفريق',
                  prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1B5E20)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captainPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم هاتف الكابتن (اختياري)',
                  prefixIcon: const Icon(Icons.phone_rounded, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final tName = teamNameCtrl.text.trim();
                final cPhone = captainPhoneCtrl.text.trim();

                if (tName.isEmpty) return;
                if (currentTeams.contains(tName)) {
                  _showCenterToast(context, 'هذا الفريق مضاف مسبقاً', isError: true);
                  return;
                }

                Navigator.pop(dialogCtx);
                final uniqueKey = cPhone.isNotEmpty ? cPhone : 'manual_${DateTime.now().millisecondsSinceEpoch}';

                await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).update({
                  'teams': FieldValue.arrayUnion([tName]),
                  'registeredPlayers.$uniqueKey': tName,
                });

                if (context.mounted) {
                  _showCenterToast(context, 'تمت إضافة الفريق بنجاح');
                }
              },
              child: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performFullTournamentDeletion(BuildContext context, String tournamentTitle) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      final bookingsByTid = await firestore
          .collection('bookings')
          .where('tournamentId', isEqualTo: doc.id)
          .get();

      for (var bDoc in bookingsByTid.docs) {
        batch.update(bDoc.reference, {
          'isDeleted': true,
          'status': 'cancelled',
        });
      }

      final bookingsByName = await firestore
          .collection('bookings')
          .where('tournamentTitle', isEqualTo: tournamentTitle)
          .get();

      for (var bDoc in bookingsByName.docs) {
        batch.update(bDoc.reference, {
          'isDeleted': true,
          'status': 'cancelled',
        });
      }

      batch.delete(doc.reference);
      await batch.commit();

      if (context.mounted) {
        _showCenterToast(context, 'تم حذف البطولة وتفريغ جدولها');
      }
    } catch (e) {
      if (context.mounted) {
        _showCenterToast(context, 'تعذر الحذف', isError: true);
      }
    }
  }

  void _confirmDeleteTournament(BuildContext context, String tournamentTitle) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف البطولة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text('هل أنت متأكد من حذف بطولة ($tournamentTitle) وتفريغ مبارياتها من الجدول؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                Navigator.pop(ctx);
                await _performFullTournamentDeletion(context, tournamentTitle);
              },
              child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openManageTeamsDialog(BuildContext context, Map<String, dynamic> data) {
    final teams = List<String>.from(data['teams'] ?? []);
    final registeredPlayers = Map<String, dynamic>.from(data['registeredPlayers'] ?? {});
    final tournamentName = data['title'] ?? 'البطولة';

    final Map<String, String> teamToPhone = {};
    registeredPlayers.forEach((phone, tName) {
      teamToPhone[tName.toString()] = phone;
    });

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  child: Center(child: Text('لا توجد فرق مسجلة بعد', style: TextStyle(color: Colors.grey))),
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
                          tooltip: 'استبعاد الفريق',
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

  void _showRegisterSheet(BuildContext context, String tournamentId, String tournamentTitle) {
    final teamNameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'تسجيل فريق في ($tournamentTitle)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: teamNameCtrl,
                decoration: InputDecoration(
                  labelText: 'اسم فريقك',
                  prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1B5E20)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final tName = teamNameCtrl.text.trim();
                  if (tName.isEmpty) return;
                  Navigator.pop(sheetCtx);

                  await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).update({
                    'teams': FieldValue.arrayUnion([tName]),
                    'registeredPlayers.$userPhone': tName,
                  });

                  if (context.mounted) {
                    _showCenterToast(context, 'تم تسجيل فريقك بنجاح');
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
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'delete') {
                          _confirmDeleteTournament(context, title);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('حذف البطولة', style: TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
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
                  Text(
                    'الفرق: ${teams.length} من $maxTeams',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  ),
                  Text(
                    isFull ? 'المقاعد مكتملة' : 'متبقي ${maxTeams - teams.length}',
                    style: TextStyle(fontSize: 11, color: isFull ? Colors.red : Colors.grey),
                  ),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.groups_rounded, size: 15),
                      label: const Text('إدارة الفرق', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () => _openManageTeamsDialog(context, data),
                    ),
                    const SizedBox(width: 6),

                    // زر المربع الصغير لإضافة فريق يدوياً بواسطة المالك
                    if (!isFull && status == 'registering')
                      InkWell(
                        onTap: () => _showManualAddTeamDialog(context, doc.id, teams, maxTeams),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1B5E20)),
                          ),
                          child: const Icon(Icons.add_rounded, color: Color(0xFF1B5E20), size: 18),
                        ),
                      ),
                    const SizedBox(width: 6),

                    if (onOpenBracket != null) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.account_tree_rounded, size: 15),
                        label: const Text('القرعة والنتائج', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: onOpenBracket,
                      ),
                    ],
                  ] else ...[
                    if (status == 'registering')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRegistered ? Colors.grey : const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(isRegistered ? Icons.check_circle_rounded : Icons.app_registration_rounded, size: 15),
                        label: Text(
                          isRegistered ? 'فريقك مسجل' : (isFull ? 'المقاعد مكتملة' : 'تسجيل فريقي'),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: (isRegistered || isFull)
                            ? null
                            : () => _showRegisterSheet(context, doc.id, title),
                      ),
                    if (onOpenBracket != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
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
