import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerNotificationService {
  static void listenToBookingUpdates(BuildContext context, String userPhone) {
    FirebaseFirestore.instance
        .collection('bookings')
        .where('phone', isEqualTo: userPhone)
        .snapshots()
        .listen((snapshot) async {
      final prefs = await SharedPreferences.getInstance();

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final bookingId = change.doc.id;
          final status = data['status'] ?? '';
          final pitchName = data['pitchName'] ?? 'الملعب';
          final date = data['date'] ?? '';
          final time = data['startTime'] ?? '';

          // التحقق من أن هذا الإشعار لم يُعرض من قبل
          final lastSeenStatus = prefs.getString('notif_seen_$bookingId');
          if (lastSeenStatus == status) continue;

          if (status == 'upcoming') {
            await prefs.setString('notif_seen_$bookingId', 'upcoming');
            if (context.mounted) {
              _showBookingAlert(
                context,
                title: 'تم تأكيد حجزك بنجاح! ⚽🎉',
                message: 'وافق صاحب $pitchName على حجزك لموعد ($date الساعة $time). جهز فريقك!',
                isSuccess: true,
              );
            }
          } else if (status == 'rejected') {
            await prefs.setString('notif_seen_$bookingId', 'rejected');
            if (context.mounted) {
              _showBookingAlert(
                context,
                title: 'تم رفض طلب الحجز ❌',
                message: 'نعتذر، تعذر تثبيت حجزك في $pitchName لموعد ($date الساعة $time). يمكنك اختيار موعد آخر.',
                isSuccess: false,
              );
            }
          }
        }
      }
    });
  }

  static void _showBookingAlert(
    BuildContext context, {
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isSuccess ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? const Color(0xFF1B5E20) : Colors.grey.shade800,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً فهمت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
