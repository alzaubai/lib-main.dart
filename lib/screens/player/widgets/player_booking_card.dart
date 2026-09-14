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

  Future<String> _getPitchPhone(String pitchName) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('pitches').doc(pitchName).get();
      if (snap.exists) {
        return (snap.data()?['phone'] ?? snap.data()?['ownerPhone'] ?? '').toString();
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final dateStr = (data['date'] ?? '').toString();
    final startTimeStr = (data['startTime'] ?? '').toString();
    final rejectionReason = data['rejectionReason'];
    final isUnread = data['seenByPlayer'] == false;
    final pitchName = data['pitchName'] ?? 'ملعب رياضي';

    Color statusColor = Colors.amber.shade800;
    String statusText = 'قيد المراجعة';
    if (status == 'upcoming') {
      statusColor = const Color(0xFF1B5E20);
      statusText = 'مؤكد ومثبت';
    } else if (status == 'rejected') {
      statusColor = Colors.red.shade700;
      statusText = 'مرفوض أو ملغي';
    } else if (status == 'completed') {
      statusColor = Colors.blue.shade800;
      statusText = 'مكتمل';
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
                          Text(
                            pitchName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'جديد',
                                style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text('التاريخ: $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    statusText,
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
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
                        Text(
                          'سبب الرفض من إدارة الملعب:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$rejectionReason',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                    ),
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
                          : (isLess3Hrs
                              ? 'لا يمكن الإلغاء (أقل من 3 ساعات على المباراة)'
                              : 'متاح الإلغاء قبل 3 ساعات من المباراة'),
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
                    label: Text(
                      status == 'pending' ? 'سحب الطلب' : 'إلغاء الحجز',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () async {
                      if (status == 'upcoming' && isLess3Hrs) {
                        final phone = await _getPitchPhone(pitchName);
                        if (context.mounted) {
                          CancelBookingDialog.showTimeRestricted(context, ownerPhone: phone);
                        }
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
                  label: const Text('إزالة من السجل', style: TextStyle(fontSize: 11)),
                  onPressed: () => doc.reference.delete(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
