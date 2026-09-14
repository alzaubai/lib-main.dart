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
    {'title': 'العصر', 'icon': Icons.wb_twilight_rounded},
    {'title': 'المساء والذروة 🔥', 'icon': Icons.nightlight_round},
    {'title': 'الليل المتأخر', 'icon': Icons.bedtime_rounded},
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

  bool _isPeakHour(String slot) {
    final hour = _extractStartHour(slot);
    return hour >= 20 && hour <= 23; // ساعات الذروة المسائية بين 8 إلى 11 مساءً
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
        // أزرار الفترات العلوية
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
                          size: 14,
                          color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
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

        // شبكة عرض الساعات (Grid)
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

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: displayedSlots.length,
                  itemBuilder: (context, idx) {
                    final slot = displayedSlots[idx];
                    final isConfirmed = confirmedSlots.contains(slot);
                    final isSelected = widget.selectedSlot == slot;
                    final isPeak = _isPeakHour(slot);
                    final pendingCount = pendingSlotsCount[slot] ?? 0;

                    Color bg = Colors.white;
                    Color border = const Color(0xFFE2E8F0);
                    Color textColor = const Color(0xFF1E293B);

                    if (isConfirmed) {
                      bg = const Color(0xFFF1F5F9);
                      border = const Color(0xFFE2E8F0);
                      textColor = const Color(0xFF94A3B8);
                    } else if (isSelected) {
                      bg = const Color(0xFF1B5E20);
                      border = const Color(0xFF1B5E20);
                      textColor = Colors.white;
                    } else if (pendingCount > 0) {
                      bg = const Color(0xFFFFFBEB);
                      border = Colors.amber.shade300;
                      textColor = Colors.amber.shade900;
                    }

                    return InkWell(
                      onTap: isConfirmed ? null : () => widget.onSlotSelected(isSelected ? null : slot),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border, width: isSelected ? 1.8 : 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isPeak && !isConfirmed && !isSelected) ...[
                                  const Text('🔥', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  slot,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isConfirmed
                                  ? 'محجوز 🔒'
                                  : (isSelected ? 'تم الاختيار ✔️' : (pendingCount > 0 ? '$pendingCount طلب معلق' : 'متاح ⚽')),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white70 : (isConfirmed ? Colors.grey : const Color(0xFF1B5E20)),
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
        ),
      ],
    );
  }
}
