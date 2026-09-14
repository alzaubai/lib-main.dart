import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SlotSelectionGrid extends StatefulWidget {
  final String pitchName;
  final String dateStr;
  final String dayNameArabic;
  final List<String> allSlots;
  final String? selectedSlot;
  final ValueChanged<String?> onSlotSelected;

  const SlotSelectionGrid({
    super.key,
    required this.pitchName,
    required this.dateStr,
    required this.dayNameArabic,
    required this.allSlots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  State<SlotSelectionGrid> createState() => _SlotSelectionGridState();
}

class _SlotSelectionGridState extends State<SlotSelectionGrid> {
  int _selectedPeriodIndex = 1;

  final List<Map<String, dynamic>> _periods = [
    {'title': 'فترة العصر', 'icon': Icons.wb_twilight_rounded},
    {'title': 'فترة المساء', 'icon': Icons.nightlight_round},
    {'title': 'الفترة الليلية', 'icon': Icons.bedtime_rounded},
  ];

  int _extractStartHour(String slot) {
    try {
      final startPart = slot.split('-')[0].trim();
      final isPM = startPart.contains('م') || startPart.toLowerCase().contains('pm');
      final rawDigits = startPart.replaceAll(RegExp(r'[^\d:]'), '').split(':')[0];
      int hour = int.tryParse(rawDigits) ?? 0;
      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return hour;
    } catch (_) {
      return 0;
    }
  }

  List<String> _filterSlotsByPeriod(List<String> slots, int periodIndex) {
    return slots.where((slot) {
      final hour = _extractStartHour(slot);
      if (periodIndex == 0) {
        return hour >= 15 && hour < 19;
      } else if (periodIndex == 1) {
        return hour >= 19 && hour < 24;
      } else {
        return hour < 5 || hour >= 24;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final periodSlots = _filterSlotsByPeriod(widget.allSlots, _selectedPeriodIndex);
    final displayedSlots = periodSlots.isNotEmpty ? periodSlots : widget.allSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: List.generate(_periods.length, (idx) {
              final isSelected = _selectedPeriodIndex == idx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriodIndex = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _periods[idx]['icon'] as IconData,
                          size: 15,
                          color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _periods[idx]['title'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('pitchName', isEqualTo: widget.pitchName)
              .where('date', isEqualTo: widget.dateStr)
              .snapshots(),
          builder: (context, bookingSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recurring_rules')
                  .where('pitchName', isEqualTo: widget.pitchName)
                  .where('dayOfWeek', isEqualTo: widget.dayNameArabic)
                  .snapshots(),
              builder: (context, recurringSnap) {
                final confirmedSlots = <String>{};
                final pendingSlotsCount = <String, int>{};

                if (bookingSnap.hasData) {
                  for (var doc in bookingSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = d['status'];
                    final slot = '${d['startTime']} - ${d['endTime']}';

                    if (status == 'upcoming' || status == 'completed' || status == 'tournament_match') {
                      confirmedSlots.add(slot);
                    } else if (status == 'pending') {
                      pendingSlotsCount[slot] = (pendingSlotsCount[slot] ?? 0) + 1;
                    }
                  }
                }

                if (recurringSnap.hasData) {
                  for (var doc in recurringSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final slot = '${d['startTime']} - ${d['endTime']}';
                    confirmedSlots.add(slot);
                  }
                }

                if (displayedSlots.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: Text(
                      'لا توجد مواعيد مخصصة لهذه الفترة',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedSlots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final slot = displayedSlots[idx];
                    final isConfirmed = confirmedSlots.contains(slot);
                    final pendingCount = pendingSlotsCount[slot] ?? 0;
                    final hasPending = !isConfirmed && pendingCount > 0;
                    final isSelected = widget.selectedSlot == slot;

                    Color cardBg;
                    Color borderColor;
                    Widget statusBadge;

                    if (isConfirmed) {
                      cardBg = const Color(0xFFF7F8F9);
                      borderColor = Colors.grey.shade300;
                      statusBadge = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'محجوز رسمياً',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                        ),
                      );
                    } else if (isSelected) {
                      cardBg = const Color(0xFF1B5E20);
                      borderColor = const Color(0xFF1B5E20);
                      statusBadge = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'تم التحديد',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      );
                    } else if (hasPending) {
                      cardBg = const Color(0xFFFFFBF2);
                      borderColor = const Color(0xFFFFD599);
                      statusBadge = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8CC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pendingCount == 1 ? 'طلب قيد المراجعة' : '$pendingCount طلبات قيد المراجعة',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                        ),
                      );
                    } else {
                      cardBg = Colors.white;
                      borderColor = const Color(0xFFE2E8F0);
                      statusBadge = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'متاح للحجز',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      );
                    }

                    return InkWell(
                      onTap: isConfirmed
                          ? null
                          : () => widget.onSlotSelected(isSelected ? null : slot),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white24
                                    : (isConfirmed ? Colors.grey.shade200 : const Color(0xFFF1F5F2)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isConfirmed
                                    ? Icons.lock_outline_rounded
                                    : (isSelected ? Icons.check_rounded : Icons.schedule_rounded),
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : (isConfirmed ? Colors.grey.shade500 : const Color(0xFF1B5E20)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                slot,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isConfirmed ? Colors.grey.shade500 : const Color(0xFF1E293B)),
                                ),
                              ),
                            ),
                            statusBadge,
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
