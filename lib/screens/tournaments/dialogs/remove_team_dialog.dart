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
                  'يرجى كتابة سبب الاستبعاد لإرسال إشعار رسمي إلى كابتن الفريق:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'اكتب سبب الاستبعاد هنا...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
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
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) return;

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
                            'targetPhone': captainPhone,
                            'title': 'تحديث بخصوص اشتراك البطولة',
                            'body': 'تم استبعاد فريقك ($teamName) من بطولة ($tournamentName). السبب: $reason',
                            'type': 'tournament_rejection',
                            'tournamentId': tournamentId,
                            'isRead': false,
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
