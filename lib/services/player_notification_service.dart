import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerNotificationService {
  static void listen(BuildContext context, String userPhone) {
    if (userPhone.trim().isEmpty) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userPhone', isEqualTo: userPhone.trim())
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'];

        if (type == 'tournament_removal') {
          _showRemovalDialog(context, doc.reference, data);
        } else if (type == 'tournament_match_scheduled') {
          _showMatchScheduledDialog(context, doc.reference, data);
        }
      }
    });
  }

  static void _showRemovalDialog(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'استبعاد من البطولة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نعتذر منك، تم استبعاد فريق (${data['teamName'] ?? 'فريقك'}) من بطولة (${data['tournamentName'] ?? ''}).',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'السبب المسجل من المنظم:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['reason'] ?? 'اعتذار من اللجنة المنظمة'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                await ref.update({'seen': true});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حسناً، تم الاطلاع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static void _showMatchScheduledDialog(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_available_rounded, color: Color(0xFF1B5E20), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'تثبيت موعد مباراتك الرسمية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تمت قرعة بطولة (${data['tournamentName'] ?? ''}) وتحديد موعد مباراتكم القادمة:',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _infoRow('المنافس', '${data['opponent'] ?? 'المنافس'}'),
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    _infoRow('التاريخ', '${data['matchDate'] ?? ''}'),
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    _infoRow('التوقيت', '${data['matchTime'] ?? ''}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                await ref.update({'seen': true});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('تأكيد الاستلام', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}
