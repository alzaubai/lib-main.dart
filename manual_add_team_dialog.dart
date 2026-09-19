import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../services/tournament_service.dart';

class ManualAddTeamDialog {
  static void show(
    BuildContext context, {
    required String tournamentId,
    required List<String> currentTeams,
    required int maxTeams,
  }) {
    if (currentTeams.length >= maxTeams) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اكتمال العدد الأقصى لفرق البطولة'), behavior: SnackBarBehavior.floating),
      );
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
              Text('إضافة فريق للبطولة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('هذا الفريق مضاف مسبقاً'), behavior: SnackBarBehavior.floating),
                  );
                  return;
                }

                Navigator.pop(dialogCtx);
                final uniqueKey = cPhone.isNotEmpty ? cPhone : 'manual_${DateTime.now().millisecondsSinceEpoch}';

                await TournamentService.addTeamManually(
                  tournamentId: tournamentId,
                  teamName: tName,
                  phoneKey: uniqueKey,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة الفريق بنجاح'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              child: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
