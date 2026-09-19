import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SlotSelectionGrid extends StatelessWidget {
  final String pitchName;
  final String dateStr;
  final String dayNameArabic;
  final List<String> allSlots;
  final String? selectedSlot;
  final Function(String) onSlotSelected;

  const SlotSelectionGrid({
    super.key,
    required this.pitchName,
    required this.dateStr,
    required this.dayNameArabic,
    required this.allSlots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  // فحص حقيقي ودقيق لمعرفة هل الوقت مضى لليوم الحالي
  bool _checkIfTimePassed(String dateString, String timeSlot) {
    try {
      final now = DateTime.now();
      final todayFormatted = DateFormat('yyyy-MM-dd').format(now);

      // إذا كان التاريخ المختار في الماضي أصلاً
      final chosenDate = DateFormat('yyyy-MM-dd').parse(dateString);
      final todayDateOnly = DateTime(now.year, now.month, now.day);
      if (chosenDate.isBefore(todayDateOnly)) {
        return true;
      }

      // إذا كان في يوم قادم فهو متاح قطعاً
      if (chosenDate.isAfter(todayDateOnly)) {
        return false;
      }

      // إذا كان اليوم هو تاريخ اليوم، نفحص ساعة البداية
      final startPart = timeSlot.split(' - ').first.trim();
      final clean = startPart.replaceAll(RegExp(r'\s+'), ' ');
      final isPM = clean.contains('م') || clean.toUpperCase().contains('PM');
      final isAM = clean.contains('ص') || clean.toUpperCase().contains('AM');

      final digitsOnly = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final timeParts = digitsOnly.split(':');
      if (timeParts.isEmpty) return false;

      int hour = int.parse(timeParts[0]);
      int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      // أوقات ما بعد منتصف الليل (12 ص، 1 ص، 2 ص) التابعة لسهرة اليوم
      DateTime slotDateTime;
      if (isAM && hour < 6) {
        slotDateTime = DateTime(now.year, now.month, now.day + 1, hour, minute);
      } else {
        slotDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      }

      return now.isAfter(slotDateTime);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('pitchName', isEqualTo: pitchName)
          .where('date', isEqualTo: dateStr)
          .snapshots(),
      builder: (context, bookingSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recurring_rules')
              .where('pitchName', isEqualTo: pitchName)
              .where('dayOfWeek', isEqualTo: dayNameArabic)
              .snapshots(),
          builder: (context, recurringSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('slot_locks')
                  .where('pitchName', isEqualTo: pitchName)
                  .where('date', isEqualTo: dateStr)
                  .snapshots(),
              builder: (context, lockSnap) {
                if (bookingSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                }

                // 1. جمع الساعات المحجوزة رسمياً
                final bookedSlots = <String>{};
                for (var doc in bookingSnap.data?.docs ?? []) {
                  final d = doc.data() as Map<String, dynamic>;
                  final status = d['status'];
                  if (d['isDeleted'] == true || status == 'rejected') continue;
                  final s = '${d['startTime']} - ${d['endTime']}';
                  bookedSlots.add(s);
                }

                // 2. جمع الساعات للاشتراكات الأسبوعية
                for (var doc in recurringSnap.data?.docs ?? []) {
                  final d = doc.data() as Map<String, dynamic>;
                  final s = '${d['startTime']} - ${d['endTime']}';
                  bookedSlots.add(s);
                }

                // 3. جمع الساعات المقفولة مؤقتاً لمدة 5 دقائق
                final lockedSlots = <String>{};
                final now = DateTime.now();
                for (var doc in lockSnap.data?.docs ?? []) {
                  final d = doc.data() as Map<String, dynamic>;
                  final expiresAt = (d['expiresAt'] as Timestamp?)?.toDate();
                  if (expiresAt != null && expiresAt.isAfter(now)) {
                    lockedSlots.add((d['timeSlot'] ?? '').toString());
                  }
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: allSlots.length,
                  itemBuilder: (context, index) {
                    final slot = allSlots[index];
                    final isPassed = _checkIfTimePassed(dateStr, slot);
                    final isBooked = bookedSlots.contains(slot);
                    final isLockedByOther = lockedSlots.contains(slot) && selectedSlot != slot;
                    final isSelected = selectedSlot == slot;

                    Color bg = Colors.white;
                    Color border = const Color(0xFFCBD5E1);
                    Color text = const Color(0xFF1E293B);
                    String? statusSubtext;

                    if (isPassed) {
                      bg = Colors.grey.shade100;
                      border = Colors.transparent;
                      text = Colors.grey.shade400;
                      statusSubtext = 'انتهى';
                    } else if (isBooked) {
                      bg = Colors.red.shade50;
                      border = Colors.red.shade200;
                      text = Colors.red.shade700;
                      statusSubtext = 'محجوز';
                    } else if (isLockedByOther) {
                      bg = Colors.amber.shade50;
                      border = Colors.amber.shade300;
                      text = Colors.amber.shade900;
                      statusSubtext = 'قيد المراجعة';
                    } else if (isSelected) {
                      bg = const Color(0xFF1B5E20);
                      border = const Color(0xFF1B5E20);
                      text = Colors.white;
                    }

                    final bool isClickable = !isPassed && !isBooked && !isLockedByOther;

                    return InkWell(
                      onTap: isClickable ? () => onSlotSelected(slot) : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border, width: isSelected ? 1.8 : 1.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: text,
                              ),
                            ),
                            if (statusSubtext != null)
                              Text(
                                statusSubtext,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
