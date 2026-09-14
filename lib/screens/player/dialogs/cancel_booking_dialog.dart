import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/booking_service.dart';
import '../../../constants.dart';

class CancelBookingDialog {
  /// نافذة تحذير منع الإلغاء قبل أقل من 3 ساعات مع توفير زر الاتصال والواتساب
  static void showTimeRestricted(BuildContext context, {String? ownerPhone}) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.timer_off_rounded, color: Colors.red, size: 26),
              SizedBox(width: 8),
              Text(
                'تعذر إلغاء الحجز ذاتياً',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'وفقاً لسياسة إدارة الملاعب، لا يمكن إلغاء الحجز ذاتياً قبل أقل من 3 ساعات من انطلاق المباراة للحفاظ على حقوق حجز الساعة.',
                style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 10),
              const Text(
                'يرجى التواصل المباشر مع إدارة الملعب هاتفياً أو عبر واتساب للتنسيق والإلغاء:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              if (ownerPhone != null && ownerPhone.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: const Text('اتصال', style: TextStyle(fontSize: 12)),
                        onPressed: () => launchCallDirect(ownerPhone),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const Text('واتساب', style: TextStyle(fontSize: 12)),
                        onPressed: () => launchWhatsAppDirect(ownerPhone),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة تأكيد الإلغاء في حال كان الموعد قبل أكثر من 3 ساعات
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
          title: Text(currentStatus == 'pending' ? 'سحب طلب الحجز' : 'إلغاء موعد الحجز'),
          content: Text(
            currentStatus == 'pending'
                ? 'هل أنت متأكد من سحب هذا الطلب المعلق؟ سيتم حذفه فوراً.'
                : 'هل أنت متأكد من إلغاء هذا الحجز المؤكد؟ سيتم إشعار إدارة الملعب وإتاحة الساعة.',
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
                      content: Text(currentStatus == 'pending' ? 'تم سحب الطلب بنجاح' : 'تم إلغاء الحجز وإبلاغ إدارة الملعب'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              },
              child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
