import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemoveTeamDialog {
  static void show(
    BuildContext context, {
    required String tournamentId,
    required String tournamentName,
    required String teamName,
    required String captainPhone,
  }) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    // الخيارات الجاهزة والسريعة
    final quickReasons = ['انسحاب الفريق', 'تأخر عن الحضور', 'مخالفة القوانين / شغب', 'سبب آخر...'];
    String selectedReason = quickReasons[0];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.person_remove_rounded, color: Colors.red.shade700, size: 22),
                const SizedBox(width: 8),
                Text(
                  'استبعاد فريق ($teamName)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حدد سبب الاستبعاد لإرسال إشعار فوري للكابتن:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 10),
                
                // عرض الخيارات السريعة
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quickReasons.map((r) {
                    final isSelected = selectedReason == r;
                    return ChoiceChip(
                      label: Text(r, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: Colors.red.shade700,
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (val) {
                        if (val) setState(() => selectedReason = r);
                      },
                    );
                  }).toList(),
                ),
                
                // مربع النص يظهر فقط إذا اختار "سبب آخر..."
                if (selectedReason == 'سبب آخر...') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'اكتب تفاصيل سبب الاستبعاد هنا...',
                      hintStyle: const TextStyle(fontSize: 11),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final finalReason = selectedReason == 'سبب آخر...' ? reasonController.text.trim() : selectedReason;
                        if (finalReason.isEmpty) return;

                        setState(() => isSubmitting = true);

                        final firestore = FirebaseFirestore.instance;
                        final batch = firestore.batch();

                        // 1. إزالة الفريق وتفريغ تسجيل الكابتن
                        final tourRef = firestore.collection('tournaments').doc(tournamentId);
                        batch.update(tourRef, {
                          'teams': FieldValue.arrayRemove([teamName]),
                          if (captainPhone.isNotEmpty)
                            'registeredPlayers.$captainPhone': FieldValue.delete(),
                        });

                        // 2. إرسال إشعار فوري ومسجل في حساب الكابتن
                        if (captainPhone.isNotEmpty && !captainPhone.startsWith('manual_')) {
                          final notifRef = firestore.collection('notifications').doc();
                          batch.set(notifRef, {
                            'userPhone': captainPhone, 
                            'title': 'تحديث بخصوص اشتراك البطولة',
                            'body': 'تم استبعاد فريقك ($teamName) من بطولة ($tournamentName). السبب: $finalReason',
                            'type': 'tournament_rejection',
                            'tournamentId': tournamentId,
                            'seen': false,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        }

                        await batch.commit();

                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم استبعاد فريق ($teamName) وإشعار الكابتن'),
                              backgroundColor: Colors.black87,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('تأكيد الاستبعاد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
