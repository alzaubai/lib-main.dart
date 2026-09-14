import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _shareMatchToWhatsApp(String pitchName, String date, String time, String teamA, String teamB) async {
    final text = '⚽ *تأكيد موعد مباراة كروية* ⚽\n\n'
        '🏟️ *الملعب:* $pitchName\n'
        '📅 *التاريخ:* $date\n'
        '⏰ *الوقت:* $time\n'
        '⚔️ *المواجهة:* $teamA ضد $teamB\n\n'
        'يرجى الحضور قبل الموعد بـ 15 دقيقة والتواجد بالملعب!';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getTimeRemaining(String dateStr, String startTimeStr) {
    final matchTime = TimeParserUtil.parseMatchDateTime(dateStr, startTimeStr);
    if (matchTime == null) return '';
    final diff = matchTime.difference(DateTime.now());
    if (diff.isNegative) return 'انتهت المباراة';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 24) {
      return 'باقي ${(hours / 24).floor()} يوم';
    }
    return 'متبقي ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} ساعة';
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final dateStr = (data['date'] ?? '').toString();
    final startTimeStr = (data['startTime'] ?? '').toString();
    final endTimeStr = (data['endTime'] ?? '').toString();
    final pitchName = data['pitchName'] ?? 'ملعب كروي';
    final teamOne = data['teamOne'] ?? 'فريق الكابتن';
    final teamTwo = data['teamTwo'] ?? 'تحدي مفتوح';
    final rejectionReason = data['rejectionReason'];
    final isUnread = data['seenByPlayer'] == false;

    Color statusColor = Colors.amber.shade800;
    String statusText = 'قيد الانتظار ⏳';
    if (status == 'upcoming') {
      statusColor = const Color(0xFF1B5E20);
      statusText = 'مؤكد ومثبت ✔️';
    } else if (status == 'rejected') {
      statusColor = Colors.red.shade700;
      statusText = 'مرفوض / ملغي ❌';
    } else if (status == 'completed') {
      statusColor = Colors.blue.shade700;
      statusText = 'مكتمل ولُعب ⚽';
    }

    final isLess3Hrs = TimeParserUtil.isLessThan3Hours(dateStr, startTimeStr);
    final isPassed = TimeParserUtil.isMatchPassed(dateStr, startTimeStr);
    final bool canCancel = status == 'pending' || (status == 'upcoming' && !isPassed);
    final countdown = _getTimeRemaining(dateStr, startTimeStr);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread ? Colors.green.shade400 : const Color(0xFFE2E8F0),
            width: isUnread ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // الجزء العلوي: بطاقة التذكرة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF1B5E20), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pitchName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text('تاريخ اللعب: $dateStr', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // مواجهة الفريقين
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Text(teamOne, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                          child: const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 11)),
                        ),
                        Expanded(
                          child: Text(teamTwo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  if (status == 'upcoming' && countdown.isNotEmpty && !isPassed) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Colors.deepOrange),
                        const SizedBox(width: 6),
                        Text(countdown, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // خط التذكرة المخرّم (Dotted divider)
            Row(
              children: [
                Container(
                  width: 12,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F7F4),
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          (constraints.constrainWidth() / 10).floor(),
                          (_) => const SizedBox(
                            width: 5,
                            height: 1.5,
                            child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 12,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F7F4),
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                ),
              ],
            ),

            // الجزء السفلي للتذكرة: التوقيت والإجراءات
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 6),
                  Text('$startTimeStr - $endTimeStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  if (status == 'upcoming') ...[
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366), size: 20),
                      tooltip: 'مشاركة بالواتساب',
                      onPressed: () => _shareMatchToWhatsApp(pitchName, dateStr, startTimeStr, teamOne, teamTwo),
                    ),
                  ],
                  if (isActiveTab && canCancel) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      onPressed: () {
                        if (status == 'upcoming' && isLess3Hrs) {
                          CancelBookingDialog.showTimeRestricted(context);
                        } else {
                          CancelBookingDialog.confirmCancellation(
                            context,
                            docRef: doc.reference,
                            currentStatus: status,
                            teamName: teamOne,
                          );
                        }
                      },
                      child: Text(status == 'pending' ? 'سحب الطلب' : 'إلغاء الموعد', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),

            if (status == 'rejected' && rejectionReason != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Text('السبب: $rejectionReason', style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
