import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import '../sheets/add_manual_booking_sheet.dart';

class OwnerScheduleTab extends StatefulWidget {
  final String pitchName;
  const OwnerScheduleTab({super.key, required this.pitchName});

  @override
  State<OwnerScheduleTab> createState() => _OwnerScheduleTabState();
}

class _OwnerScheduleTabState extends State<OwnerScheduleTab> {
  DateTime _selectedDate = DateTime.now();

  String _getArabicDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayNameArabic = _getArabicDayName(_selectedDate);
    final allSlots = buildPitchSlots(60);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          // شريط اختيار وتنقل الأيام
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(14, (index) {
                        final d = DateTime.now().add(Duration(days: index));
                        final isSelected = DateFormat('yyyy-MM-dd').format(d) == dateStr;
                        final dayName = index == 0 ? 'اليوم' : (index == 1 ? 'غداً' : _getArabicDayName(d));

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(dayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                                Text(DateFormat('MM/dd').format(d), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF1B5E20),
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (val) {
                              if (val) setState(() => _selectedDate = d);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),

          // العرض التفاعلي لجدول الأجندة الزمنية (Timeline Grid)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('pitchName', isEqualTo: widget.pitchName)
                  .where('date', isEqualTo: dateStr)
                  .snapshots(),
              builder: (context, bookingSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('recurring_rules')
                      .where('pitchName', isEqualTo: widget.pitchName)
                      .where('dayOfWeek', isEqualTo: dayNameArabic)
                      .snapshots(),
                  builder: (context, recurringSnap) {
                    if (bookingSnap.connectionState == ConnectionState.waiting ||
                        recurringSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                    }

                    final Map<String, Map<String, dynamic>> bookedSlots = {};

                    // تسجيل الحجوزات العادية
                    for (var doc in bookingSnap.data?.docs ?? []) {
                      final d = doc.data() as Map<String, dynamic>;
                      if (d['isDeleted'] == true || d['status'] == 'rejected' || d['status'] == 'pending') continue;
                      final slot = '${d['startTime']} - ${d['endTime']}';
                      d['docId'] = doc.id;
                      d['isRecurring'] = false;
                      bookedSlots[slot] = d;
                    }

                    // تسجيل الحجوزات الدائمة
                    for (var doc in recurringSnap.data?.docs ?? []) {
                      final d = doc.data() as Map<String, dynamic>;
                      final slot = d['timeSlot'] ?? '${d['startTime']} - ${d['endTime']}';
                      d['docId'] = doc.id;
                      d['isRecurring'] = true;
                      d['status'] = 'recurring';
                      bookedSlots[slot] = d;
                    }

                    final totalBooked = bookedSlots.length;
                    final totalFree = allSlots.length - totalBooked;

                    return Column(
                      children: [
                        // ملخص إحصائي سريع أعلى اليوم
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text('⚽ مباريات اليوم: $totalBooked', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                              Container(width: 1, height: 20, color: Colors.grey.shade300),
                              Text('🟢 ساعات شاغرة: $totalFree', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900)),
                            ],
                          ),
                        ),

                        // قائمة الأجندة بالساعة
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            itemCount: allSlots.length,
                            itemBuilder: (context, idx) {
                              final slot = allSlots[idx];
                              final booking = bookedSlots[slot];
                              final isBooked = booking != null;

                              if (!isBooked) {
                                // ساعة فارغة متاحة للحجز المباشر
                                return InkWell(
                                  onTap: () {
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
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.radio_button_unchecked, color: Colors.green, size: 18),
                                        const SizedBox(width: 10),
                                        Text(slot, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                                          child: const Text('+ حجز يدوي مباشر', style: TextStyle(color: Color(0xFF1B5E20), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // ساعة محجوزة
                              final isRecurring = booking['isRecurring'] == true;
                              final status = booking['status'];
                              final team1 = booking['teamOne'] ?? booking['teamName'] ?? 'فريق';
                              final team2 = booking['teamTwo'] ?? 'تحدي';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isRecurring ? const Color(0xFFFAF5FF) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isRecurring ? Colors.purple.shade200 : const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isRecurring ? Icons.repeat_rounded : Icons.sports_soccer_rounded,
                                      color: isRecurring ? Colors.purple.shade700 : const Color(0xFF1B5E20),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$team1 ⚔️ $team2', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                        Text('الساعة: $slot', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                    const Spacer(),
                                    if (!isRecurring && status == 'upcoming')
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1B5E20),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection('bookings')
                                              .doc(booking['docId'])
                                              .update({'status': 'completed'});
                                        },
                                        child: const Text('إنهاء وقبض ✔️', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                        child: Text(isRecurring ? 'دائم' : 'مكتمل', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
