import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isListening = false;

  /// الاستماع الموحد لجميع إشعارات اللاعب (حجوزات عادية + بطولات)
  static void listen(BuildContext context, String userPhone) {
    if (_isListening) return;
    _isListening = true;

    // 1. الاستماع لتحديثات الحجوزات العادية (قبول أو رفض من صاحب الملعب)
    _firestore
        .collection('bookings')
        .where('phone', isEqualTo: userPhone)
        .where('seenByPlayer', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];

        if (status == 'upcoming' || status == 'rejected') {
          if (!context.mounted) return;
          _showBookingStatusDialog(context, doc.reference, data);
        }
      }
    });

    // 2. الاستماع لإشعارات البطولات (استبعاد أو تحديد مواعيد مباريات)
    _firestore
        .collection('notifications')
        .where('userPhone', isEqualTo: userPhone)
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!context.mounted) return;
        _showTournamentNotificationDialog(context, doc.reference, data);
      }
    });
  }

  /// نافذة إشعار الحجز العادي (قبول / رفض)
  static void _showBookingStatusDialog(
    BuildContext context,
    DocumentReference docRef,
    Map<String, dynamic> data,
  ) {
    final bool isAccepted = data['status'] == 'upcoming';
    final pitchName = data['pitchName'] ?? 'الملعب';
    final date = data['date'] ?? '';
    final time = data['startTime'] ?? '';
    final reason = data['rejectionReason'] ?? 'نعتذر عن استقبال الحجز في هذا التوقيت';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isAccepted ? const Color(0xFF1B5E20) : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isAccepted ? 'تم تثبيت حجزك بنجاح' : 'اعتذار عن قبول الحجز',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isAccepted ? const Color(0xFF1B5E20) : Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAccepted
                    ? 'وافقت إدارة $pitchName على طلب حجز موعدك رسمياً.'
                    : 'اعتذرت إدارة $pitchName عن قبول الموعد للسبب الآتي:',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAccepted ? const Color(0xFFE8F5E9) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAccepted ? const Color(0xFFA5D6A7) : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('التاريخ: $date', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('الوقت: $time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    if (!isAccepted) ...[
                      const SizedBox(height: 6),
                      Text('السبب: $reason', style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAccepted ? const Color(0xFF1B5E20) : Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await docRef.update({'seenByPlayer': true});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حسناً، فهمت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة إشعار البطولة (استبعاد أو جدولة موعد)
  static void _showTournamentNotificationDialog(
    BuildContext context,
    DocumentReference docRef,
    Map<String, dynamic> data,
  ) {
    final type = data['type'] ?? '';
    final title = data['title'] ?? 'إشعار بطولة';
    final tournamentName = data['tournamentName'] ?? 'البطولة';
    final reason = data['reason'] ?? '';
    final isRemoval = type == 'tournament_removal';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(
                isRemoval ? Icons.warning_rounded : Icons.emoji_events_rounded,
                color: isRemoval ? Colors.red : Colors.amber.shade800,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isRemoval ? Colors.red : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRemoval
                    ? 'تم استبعاد فريقك من بطولة ($tournamentName).'
                    : 'تم تحديد موعد رسمي لمباراتكم القادمة في ($tournamentName).',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              if (isRemoval && reason.toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'السبب: $reason',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRemoval ? Colors.red.shade700 : const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await docRef.update({'seen': true});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('تم الاطلاع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
