import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/booking_service.dart';

class CancelBookingDialog {
  /// نافذة تحذير منع الإلغاء بسبب حاجز الـ 3 ساعات
  static void showTimeRestricted(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.timer_off_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('لا يمكن إلغاء الحجز!', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'حسب سياسة حجوزات الملاعب، لا يمكن إلغاء الموعد المؤكد قبل أقل من 3 ساعات من انطلاق المباراة، وذلك لحفظ حق إدارة الملعب في حجز الساعة. يرجى التواصل مباشرة مع صاحب الملعب هاتفياً.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً، فهمت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة تأكيد الإلغاء وسحب الحجز
  static void confirmCancellation(
    BuildContext context, {
    required DocumentReference docRef,
    required String currentStatus,
    required String teamName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(currentStatus == 'pending' ? 'سحب طلب الحجز؟' : 'إلغاء موعد الحجز؟'),
          content: Text(
            currentStatus == 'pending'
                ? 'هل أنت متأكد من سحب هذا الطلب المعلق؟ سيتم حذفه فوراً.'
                : 'هل أنت متأكد من إلغاء هذا الحجز المؤكد؟ سيتم إشعار صاحب الملعب وإخلاء الموعد.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                await BookingService.cancelBookingByPlayer(
                  docRef: docRef,
                  currentStatus: currentStatus,
                  teamName: teamName,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(currentStatus == 'pending' ? 'تم سحب الطلب بنجاح' : 'تم إلغاء الحجز وإبلاغ إدارة الملعب ✔️'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              },
              child: const Text('نعم، تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
