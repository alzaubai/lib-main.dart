import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerBookingsTab extends StatelessWidget {
  final String userPhone;
  const PlayerBookingsTab({super.key, required this.userPhone});

  // دالة تحويل التاريخ والوقت (مثال: 2026-09-14 و 08:00 م) إلى كائن DateTime للمقارنة الدقيقة
  DateTime? _parseMatchDateTime(String dateStr, String timeStr) {
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) return null;

      final clean = timeStr.trim();
      final isPM = clean.contains('م') || clean.toLowerCase().contains('pm');
      final parts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('phone', isEqualTo: userPhone)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد لديك حجوزات سابقة أو حالية',
                style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final dateStr = (data['date'] ?? '').toString();
              final startTimeStr = (data['startTime'] ?? '').toString();

              Color statusColor = Colors.amber;
              String statusText = 'قيد المراجعة ⏳';
              if (status == 'upcoming') {
                statusColor = Colors.green;
                statusText = 'مؤكد ومثبت ✔️';
              } else if (status == 'rejected') {
                statusColor = Colors.red;
                statusText = 'مرفوض أو ملغي ❌';
              } else if (status == 'completed') {
                statusColor = Colors.blue;
                statusText = 'مكتمل ولُعب ⚽';
              }

              // حساب الوقت المتبقي للمباراة
              final matchDateTime = _parseMatchDateTime(dateStr, startTimeStr);
              final now = DateTime.now();
              final difference = matchDateTime != null ? matchDateTime.difference(now) : null;
              final bool isLessThan3Hours = difference != null && difference.inMinutes < 180;
              final bool isPassed = difference != null && difference.isNegative;

              final bool canCancel = status == 'pending' || (status == 'upcoming' && !isPassed);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.sports_soccer, color: Color(0xFF1B5E20)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['pitchName'] ?? 'ملعب رياضي',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '📅 $dateStr',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              statusText,
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAF7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF1B5E20)),
                            const SizedBox(width: 6),
                            Text(
                              'الفترة: ${data['startTime']} إلى ${data['endTime']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (data['price'] != null)
                              Text(
                                '${data['price']} د.ع',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                          ],
                        ),
                      ),
                      if (canCancel) ...[
                        const Divider(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                status == 'pending'
                                    ? 'طلب معلق (يمكنك سحبه بأي وقت)'
                                    : (isLessThan3Hours
                                        ? '⚠️ لا يمكن الإلغاء قبل أقل من 3 ساعات'
                                        : 'متاح الإلغاء قبل 3 ساعات من المباراة'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (status == 'upcoming' && isLessThan3Hours) ? Colors.red.shade700 : Colors.grey,
                                  fontWeight: (status == 'upcoming' && isLessThan3Hours) ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: Text(
                                status == 'pending' ? 'سحب الطلب ❌' : 'إلغاء الحجز ❌',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () {
                                if (status == 'upcoming' && isLessThan3Hours) {
                                  _showTimeRestrictedDialog(context);
                                } else {
                                  _confirmCancelBooking(context, doc.reference, status, data);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showTimeRestrictedDialog(BuildContext context) {
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

  void _confirmCancelBooking(BuildContext context, DocumentReference docRef, String currentStatus, Map<String, dynamic> bData) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(currentStatus == 'pending' ? 'سحب طلب الحجز؟' : 'إلغاء موعد الحجز؟'),
          content: Text(
            currentStatus == 'pending'
                ? 'هل أنت متأكد من سحب هذا الطلب المعلق؟ سيتم حذفه ولن يظهر لإدارة الملعب.'
                : 'هل أنت متأكد من إلغاء هذا الحجز المؤكد؟ سيتم إرسال إشعار فوري لمالك الملعب وتفريغ هذه الساعة بالجدول.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تراجع'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (currentStatus == 'pending') {
                  await docRef.delete();
                } else {
                  // تحويل الحجز إلى ملغي مع حفظ بيانات الإلغاء لإشعار صاحب الملعب فوراً
                  await docRef.update({
                    'status': 'rejected',
                    'cancelledByPlayer': true,
                    'cancellationSeenByOwner': false,
                    'cancelledAt': FieldValue.serverTimestamp(),
                    'cancellingTeamName': bData['teamOne'] ?? 'فريق كابتن',
                  });
                }
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(currentStatus == 'pending' ? 'تم سحب الطلب بنجاح' : 'تم إلغاء الحجز وإبلاغ إدارة الملعب ✔️'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              },
              child: const Text(
                'نعم، تأكيد الإلغاء',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
