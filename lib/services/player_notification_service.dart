import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerNotificationService {
  static StreamSubscription<QuerySnapshot>? _bookingSubscription;
  static final Map<String, String> _lastKnownStatuses = {};
  static bool _isInitialLoad = true;

  static void listenToBookingUpdates(BuildContext context, String userPhone) {
    stopListening();
    _isInitialLoad = true;
    _lastKnownStatuses.clear();

    _bookingSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('phone', isEqualTo: userPhone)
        .snapshots()
        .listen((snapshot) {
      if (_isInitialLoad) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _lastKnownStatuses[doc.id] = (data['status'] ?? '').toString();
        }
        _isInitialLoad = false;
        return;
      }

      for (var change in snapshot.docChanges) {
        final doc = change.doc;
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final newStatus = (data['status'] ?? '').toString();
        final oldStatus = _lastKnownStatuses[doc.id];

        if (oldStatus != null && oldStatus != newStatus) {
          _lastKnownStatuses[doc.id] = newStatus;

          if (newStatus == 'upcoming') {
            _showNotificationDialog(
              context,
              isApproved: true,
              pitchName: data['pitchName'] ?? 'الملعب',
              date: data['date'] ?? '',
              time: '${data['startTime'] ?? ''} إلى ${data['endTime'] ?? ''}',
            );
          } else if (newStatus == 'rejected' && data['cancelledByPlayer'] != true) {
            _showNotificationDialog(
              context,
              isApproved: false,
              pitchName: data['pitchName'] ?? 'الملعب',
              date: data['date'] ?? '',
              time: '${data['startTime'] ?? ''} إلى ${data['endTime'] ?? ''}',
              rejectionReason: data['rejectionReason'] ?? 'لم يتم تحديد سبب من قبل إدارة الملعب',
            );
          }
        } else {
          _lastKnownStatuses[doc.id] = newStatus;
        }
      }
    });
  }

  static void stopListening() {
    _bookingSubscription?.cancel();
    _bookingSubscription = null;
    _isInitialLoad = true;
  }

  static void _showNotificationDialog(
    BuildContext context, {
    required bool isApproved,
    required String pitchName,
    required String date,
    required String time,
    String? rejectionReason,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(
              color: isApproved ? const Color(0xFF1B5E20) : Colors.red.shade800,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Icon(
                  isApproved ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isApproved ? 'تم تأكيد حجزك! ⚽' : 'تم رفض طلب الحجز ❌',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApproved
                    ? 'مبروك! وافق صاحب الملعب على موعد مباراتك وتم تثبيتها بالجدول رسمياً.'
                    : 'نعتذر منك، لقد تم رفض طلب الحجز من قبل إدارة الملعب.',
                style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
              ),
              if (!isApproved && rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.red),
                          SizedBox(width: 4),
                          Text('سبب الرفض:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(rejectionReason, style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stadium_rounded, size: 16, color: Color(0xFF1B5E20)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pitchName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('اليوم: $date', style: const TextStyle(fontSize: 12)),
                        const Spacer(),
                        const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(time, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApproved ? const Color(0xFF1B5E20) : Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً، فهمت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
