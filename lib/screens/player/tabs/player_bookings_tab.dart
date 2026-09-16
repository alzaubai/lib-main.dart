import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../dialogs/pitch_evaluation_dialog.dart';

class PlayerBookingsTab extends StatelessWidget {
  final String userPhone;

  const PlayerBookingsTab({super.key, required this.userPhone});

  List<String> _getPhoneVariants(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+|-'), '');
    final variants = <String>{clean};
    if (clean.startsWith('07')) { variants.add('964${clean.substring(1)}'); variants.add('+964${clean.substring(1)}'); }
    else if (clean.startsWith('964')) { variants.add('0${clean.substring(3)}'); variants.add('+$clean'); }
    else if (clean.startsWith('+964')) { variants.add('0${clean.substring(4)}'); variants.add(clean.substring(1)); }
    return variants.toList();
  }

  bool _shouldBeArchived(Map<String, dynamic> data) {
    try {
      if (data['isArchived'] == true) return true;
      final dateStr = (data['date'] ?? '').toString();
      if (dateStr.isNotEmpty) {
        final bookingDate = DateFormat('yyyy-MM-dd').parse(dateStr);
        final todayDateOnly = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        if (bookingDate.isBefore(todayDateOnly)) return true;
      }
      final status = (data['status'] ?? '').toString();
      if (['rejected', 'removed_from_tournament', 'completed', 'cancelled'].contains(status)) {
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp && DateTime.now().difference(createdAt.toDate()).inHours >= 24) return true;
      }
    } catch (_) {}
    return false;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return const Color(0xFF1B5E20);
      case 'pending': return Colors.amber.shade800;
      case 'completed': return Colors.blue.shade700;
      case 'cancelled':
      case 'rejected':
      case 'removed_from_tournament': return Colors.red.shade700;
      default: return const Color(0xFF64748B);
    }
  }

  String _getStatusArabicText(String status) {
    switch (status) {
      case 'confirmed': return 'مؤكد';
      case 'pending': return 'قيد الانتظار';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      case 'rejected': return 'مرفوض';
      case 'removed_from_tournament': return 'طرد من البطولة';
      default: return status;
    }
  }

  Future<void> _moveToArchive(String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'isArchived': true});
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final phoneVariants = _getPhoneVariants(userPhone);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('phone', whereIn: phoneVariants)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          final activeBookings = <Map<String, dynamic>>[];
          for (var doc in snapshot.data?.docs ?? []) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isDeleted'] == true) continue;
            final item = Map<String, dynamic>.from(data);
            item['id'] = doc.id;
            if (!_shouldBeArchived(item)) activeBookings.add(item);
          }

          activeBookings.sort((a, b) {
            final comp = (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString());
            if (comp != 0) return comp;
            return (a['startTime'] ?? '').toString().compareTo((b['startTime'] ?? '').toString());
          });

          if (activeBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_rounded, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('لا توجد لديك أي حجوزات نشطة حالياً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  const Text('المباريات السابقة تجدها في الأرشيف (أعلى الشاشة)', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: activeBookings.length,
            itemBuilder: (context, index) {
              final b = activeBookings[index];
              final bookingId = b['id'] ?? '';
              final pitchName = b['pitchName'] ?? 'الملعب';
              final teamOne = b['teamOne'] ?? 'فريقك';
              final teamTwo = (b['teamTwo'] ?? '').toString().trim();
              final dateStr = b['date'] ?? '';
              final time = '${b['startTime']} - ${b['endTime']}';
              final status = b['status'] ?? 'pending';
              final price = (b['price'] as num?)?.toDouble() ?? 25000.0;
              
              // برمجة الإشعارات (التظليل بالألوان)
              final bool isUnseen = b['isSeenByPlayer'] == false;
              Color cardColor = Colors.white;
              Color borderColor = const Color(0xFFCBD5E1);

              if (isUnseen) {
                if (status == 'confirmed') {
                  cardColor = Colors.green.shade50;
                  borderColor = Colors.green.shade400;
                } else if (status == 'rejected') {
                  cardColor = Colors.red.shade50;
                  borderColor = Colors.red.shade400;
                } else if (status == 'removed_from_tournament') {
                  cardColor = Colors.orange.shade50;
                  borderColor = Colors.orange.shade400;
                }
              }

              final statusColor = _getStatusColor(status);
              final statusText = _getStatusArabicText(status);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: isUnseen ? () async {
                    // بمجرد الضغط: يتحدث الداتا بيس، يروح اللون، ويتصفر العداد!
                    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'isSeenByPlayer': true});
                  } : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Card(
                    elevation: isUnseen ? 4 : 1.5,
                    margin: EdgeInsets.zero,
                    color: cardColor,
                    shadowColor: isUnseen ? borderColor.withOpacity(0.5) : Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: borderColor, width: isUnseen ? 1.5 : 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isUnseen) ...[
                            Row(
                              children: [
                                Icon(Icons.notifications_active_rounded, size: 14, color: borderColor),
                                const SizedBox(width: 6),
                                Text(
                                  'تحديث جديد من الإدارة! (اضغط للإخفاء)',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: borderColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.sports_soccer_rounded, size: 20, color: Color(0xFF1B5E20)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text(teamTwo.isNotEmpty && teamTwo != 'طرف ثانٍ غير محدد' ? '$teamOne ضد $teamTwo' : teamOne, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.event_note_rounded, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(dateStr, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.schedule_rounded, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(time, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                ],
                              ),
                              Text('${currencyFormatter.format(price)} د.ع', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                            ],
                          ),
                          if (status == 'completed' || status == 'rejected' || status == 'removed_from_tournament' || status == 'cancelled') ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status == 'completed' && b['pitchRating'] == null)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1B5E20),
                                      side: const BorderSide(color: Color(0xFF1B5E20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.star_rate_rounded, size: 15),
                                    label: const Text('تقييم الملعب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () => PitchEvaluationDialog.show(context, bookingId: bookingId, pitchName: pitchName, userPhone: userPhone),
                                  ),
                                const SizedBox(width: 8),
                                TextButton(
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), visualDensity: VisualDensity.compact),
                                  onPressed: () => _moveToArchive(bookingId),
                                  child: const Text('نقل للأرشيف', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
