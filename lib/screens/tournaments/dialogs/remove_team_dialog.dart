import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../services/tournament_service.dart';

class RemoveTeamDialog {
  static void show(
    BuildContext context, {
    required String tournamentId,
    required String tournamentName,
    required Map<String, dynamic> teamData,
  }) {
    final reasonCtrl = TextEditingController();
    final List<String> defaultReasons = [
      'عدم استكمال رسوم الاشتراك بالوقت المحدد',
      'مخالفة الشروط واللوائح الفنية للبطولة',
      'انسحاب الفريق بناءً على طلب الكابتن',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            titlePadding: const EdgeInsets.all(18),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_remove_rounded, color: Colors.red.shade800, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'استبعاد فريق من البطولة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سيتم حذف الفريق وإرسال إشعار مباشر للكابتن بالسبب المسجل هنا:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'اكتب سبب الاستبعاد...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'خيارات سريعة:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: defaultReasons.map((r) => ActionChip(
                      label: Text(r, style: const TextStyle(fontSize: 10)),
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onPressed: () {
                        setDialogState(() => reasonCtrl.text = r);
                      },
                    )).toList(),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('تراجع', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () async {
                  final finalReason = reasonCtrl.text.trim().isEmpty
                      ? 'اعتذار من اللجنة المنظمة للبطولة'
                      : reasonCtrl.text.trim();

                  Navigator.pop(ctx);

                  await TournamentService.removeTeamWithReason(
                    tournamentId: tournamentId,
                    tournamentName: tournamentName,
                    teamData: teamData,
                    reason: finalReason,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم استبعاد الفريق وإرسال الإشعار للكابتن'),
                        backgroundColor: Colors.black87,
                      ),
                    );
                  }
                },
                child: const Text('تأكيد الاستبعاد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
