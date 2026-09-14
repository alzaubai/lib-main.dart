import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/time_parser_util.dart';
import '../dialogs/cancel_booking_dialog.dart';

class PlayerBookingCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isActiveTab;

  const PlayerBookingCard({
    super.key,
    required this.doc,
    required this.isActiveTab,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final dateStr = (data['date'] ?? '').toString();
    final startTimeStr = (data['startTime'] ?? '').toString();
    final rejectionReason = data['rejectionReason'];
    final isUnread = data['seenByPlayer'] == false;

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

    final isLess3Hrs = TimeParserUtil.isLessThan3Hours(dateStr, startTimeStr);
    final isPassed = TimeParserUtil.isMatchPassed(dateStr, startTimeStr);
    final bool canCancel = status == 'pending' || (status == 'upcoming' && !isPassed);

    return Card(
      elevation: isUnread ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnread ? Colors.redAccent.withOpacity(0.6) : Colors.transparent,
          width: isUnread ? 1.5 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.15),
                  child: Icon(Icons.sports_soccer, color: statusColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(data['pitchName'] ?? 'ملعب رياضي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                              child: const Text('جديد', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text('📅 $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(statusText, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF7FAF7), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 6),
                  Text('الفترة: ${data['startTime']} إلى ${data['endTime']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (data['price'] != null)
                    Text('${data['price']} د.ع', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
            ),
            if (status == 'rejected' && rejectionReason != null) ...[
              const SizedBox(height: 10),
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
                        Icon(Icons.report_problem_rounded, color: Colors.red, size: 16),
                        SizedBox(width: 6),
                        Text('سبب الرفض من صاحب الملعب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$rejectionReason', style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            if (isActiveTab && canCancel) ...[
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status == 'pending'
                          ? 'طلب معلق (يمكنك سحبه بأي وقت)'
                          : (isLess3Hrs ? '⚠️ لا يمكن الإلغاء قبل أقل من 3 ساعات' : 'متاح الإلغاء قبل 3 ساعات من المباراة'),
                      style: TextStyle(
                        fontSize: 11,
                        color: (status == 'upcoming' && isLess3Hrs) ? Colors.red.shade700 : Colors.grey,
                        fontWeight: (status == 'upcoming' && isLess3Hrs) ? FontWeight.bold : FontWeight.normal,
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
                    label: Text(status == 'pending' ? 'سحب الطلب ❌' : 'إلغاء الحجز ❌', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      if (status == 'upcoming' && isLess3Hrs) {
                        CancelBookingDialog.showTimeRestricted(context);
                      } else {
                        CancelBookingDialog.confirmCancellation(
                          context,
                          docRef: doc.reference,
                          currentStatus: status,
                          teamName: data['teamOne'] ?? 'فريق كابتن',
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
            if (!isActiveTab) ...[
              const Divider(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('إزالة من سجلي', style: TextStyle(fontSize: 11)),
                  onPressed: () => doc.reference.delete(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
