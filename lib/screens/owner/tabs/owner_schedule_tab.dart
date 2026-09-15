import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/time_parser_util.dart';
import '../sheets/add_manual_booking_sheet.dart';

class OwnerScheduleTab extends StatefulWidget {
  final String pitchName;

  const OwnerScheduleTab({super.key, required this.pitchName});

  @override
  State<OwnerScheduleTab> createState() => _OwnerScheduleTabState();
}

class _OwnerScheduleTabState extends State<OwnerScheduleTab> {
  DateTime _selectedDate = DateTime.now();

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF1B5E20);
      case 'pending':
        return Colors.amber.shade800;
      case 'cancelled':
      case 'rejected':
        return Colors.red.shade700;
      case 'recurring':
        return Colors.purple.shade800;
      default:
        return const Color(0xFF0F172A);
    }
  }

  String _getStatusArabicText(String status) {
    switch (status) {
      case 'confirmed':
        return 'مؤكد ✔️';
      case 'pending':
        return 'قيد الانتظار';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      case 'recurring':
        return 'اشتراك دائم';
      default:
        return 'محجوز';
    }
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> slot) {
    final teamOne = slot['teamOne'] ?? 'فريق كابتن';
    final teamTwo = slot['teamTwo'] ?? '';
    final phone = slot['phone'] ?? 'غير متوفر';
    final startTime = slot['startTime'] ?? '';
    final endTime = slot['endTime'] ?? '';
    final date = slot['date'] ?? '';
    final status = slot['status'] ?? 'upcoming';
    final price = slot['price'] ?? 25000;
    final isRecurring = slot['isRecurringRule'] == true || status == 'recurring';
    final docId = slot['docId']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isRecurring ? Icons.repeat_rounded : Icons.sports_soccer_rounded,
                color: isRecurring ? Colors.purple.shade800 : const Color(0xFF1B5E20),
              ),
              const SizedBox(width: 8),
              const Text('تفاصيل الحجز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الفريق الأول: $teamOne', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (teamTwo.toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('الفريق الثاني: $teamTwo', style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 8),
              Text('التاريخ: $date', style: const TextStyle(fontSize: 13)),
              Text('الوقت: من $startTime إلى $endTime', style: const TextStyle(fontSize: 13)),
              Text('رقم الهاتف: $phone', style: const TextStyle(fontSize: 13)),
              Text('المبلغ: $price د.ع', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            ],
          ),
          actions: [
            if (docId != null && !isRecurring)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                    'isDeleted': true,
                    'status': 'cancelled',
                  });
                },
                child: const Text('إلغاء الحجز', style: TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayNameArabic = TimeParserUtil.getArabicDayName(_selectedDate);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          // شريط الأيام الأفقي بدون أيقونة علوية
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_rounded, color: Color(0xFF1B5E20), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'جدول مباريات: $dayNameArabic ($dateStr)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const Spacer(),
                      if (!DateUtils.isSameDay(_selectedDate, DateTime.now()))
                        TextButton(
                          onPressed: () => setState(() => _selectedDate = DateTime.now()),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          child: const Text('اليوم', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 65,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 14,
                    itemBuilder: (context, index) {
                      final day = DateTime.now().add(Duration(days: index));
                      final isSelected = DateUtils.isSameDay(_selectedDate, day);
                      final dName = TimeParserUtil.getArabicDayName(day);
                      final dNum = DateFormat('d').format(day);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dNum,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // قائمة الحجوزات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('pitchName', isEqualTo: widget.pitchName)
                  .where('date', isEqualTo: dateStr)
                  .snapshots(),
              builder: (context, snapBookings) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('recurring_rules')
                      .where('pitchName', isEqualTo: widget.pitchName)
                      .where('dayOfWeek', isEqualTo: dayNameArabic)
                      .snapshots(),
                  builder: (context, snapRecurring) {
                    if (snapBookings.connectionState == ConnectionState.waiting &&
                        snapRecurring.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                    }

                    final bookingsDocs = snapBookings.data?.docs ?? [];
                    final recurringDocs = snapRecurring.data?.docs ?? [];
                    final List<Map<String, dynamic>> allSlots = [];

                    for (var doc in bookingsDocs) {
                      final d = doc.data() as Map<String, dynamic>;
                      if (d['isDeleted'] == true) continue;
                      if (d['status'] == 'rejected') continue;
                      final map = Map<String, dynamic>.from(d);
                      map['docId'] = doc.id;
                      map['isRecurringRule'] = false;
                      allSlots.add(map);
                    }

                    for (var rDoc in recurringDocs) {
                      final rd = rDoc.data() as Map<String, dynamic>;
                      final startTime = rd['startTime'] ?? '';
                      bool alreadyBooked = allSlots.any((s) => s['startTime'] == startTime);

                      if (!alreadyBooked) {
                        allSlots.add({
                          'docId': rDoc.id,
                          'pitchName': widget.pitchName,
                          'teamOne': rd['teamName'] ?? 'فريق دائم',
                          'teamTwo': '',
                          'phone': rd['phone'] ?? '',
                          'date': dateStr,
                          'startTime': startTime,
                          'endTime': rd['endTime'] ?? '',
                          'price': rd['price'] ?? 25000,
                          'status': 'recurring',
                          'isRecurringRule': true,
                        });
                      }
                    }

                    allSlots.sort((a, b) {
                      final tA = a['startTime'] ?? '';
                      final tB = b['startTime'] ?? '';
                      return tA.compareTo(tB);
                    });

                    if (allSlots.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد حجوزات في $dayNameArabic',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'الملعب متاح بالكامل طوال هذا اليوم',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add_rounded, color: Colors.white),
                              label: const Text('إضافة حجز يدوي الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ModernAddBookingSheet(
                                    pitchName: widget.pitchName,
                                    durationMinutes: 60,
                                    defaultRate: 25000,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: allSlots.length,
                      itemBuilder: (context, idx) {
                        final slot = allSlots[idx];
                        final teamOne = slot['teamOne'] ?? 'فريق كروي';
                        final startTime = slot['startTime'] ?? '';
                        final endTime = slot['endTime'] ?? '';
                        final status = slot['status'] ?? 'upcoming';
                        final isRecurring = slot['isRecurringRule'] == true || status == 'recurring';

                        final statusColor = _getStatusColor(status);
                        final statusText = _getStatusArabicText(status);

                        return Card(
                          elevation: 1.5,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isRecurring ? Colors.purple.shade200 : const Color(0xFFE2E8F0),
                              width: isRecurring ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isRecurring ? Colors.purple.shade50 : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isRecurring ? Icons.repeat_rounded : Icons.sports_soccer_rounded,
                                color: isRecurring ? Colors.purple.shade800 : const Color(0xFF1B5E20),
                                size: 22,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  teamOne,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                                if (isRecurring) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: Text('اشتراك أسبوعي', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('$startTime - $endTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                ],
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            onTap: () => _showBookingDetails(context, slot),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
