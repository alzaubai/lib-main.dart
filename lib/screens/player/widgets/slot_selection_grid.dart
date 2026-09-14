import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SlotSelectionGrid extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _legendItem('متاحة تماماً', Colors.green.shade700, const Color(0xFFE8F5E9)),
            _legendItem('عليها طلب سابق ⏳', Colors.orange.shade800, Colors.orange.shade50),
            _legendItem('مثبتة ومقفلة 🔒', Colors.grey.shade600, Colors.grey.shade200),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
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
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: allSlots.length,
                  itemBuilder: (context, idx) {
                    final slot = allSlots[idx];
                    final isConfirmed = confirmedSlots.contains(slot);
                    final pendingCount = pendingSlotsCount[slot] ?? 0;
                    final hasPending = !isConfirmed && pendingCount > 0;
                    final isSelected = selectedSlot == slot;

                    Color bgColor;
                    Color borderColor;
                    Color textColor;
                    Widget badge;

                    if (isConfirmed) {
                      bgColor = Colors.grey.shade200;
                      borderColor = Colors.grey.shade300;
                      textColor = Colors.grey.shade500;
                      badge = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('محجوزة رسمياً', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        ],
                      );
                    } else if (isSelected) {
                      bgColor = const Color(0xFF1B5E20);
                      borderColor = const Color(0xFF1B5E20);
                      textColor = Colors.white;
                      badge = const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text('تم الاختيار', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      );
                    } else if (hasPending) {
                      bgColor = Colors.orange.shade50;
                      borderColor = Colors.orange.shade300;
                      textColor = Colors.orange.shade900;
                      badge = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_top_rounded, size: 11, color: Colors.orange.shade800),
                          const SizedBox(width: 4),
                          Text(
                            pendingCount == 1 ? 'طلب قيد الانتظار' : '$pendingCount طلبات بالانتظار',
                            style: TextStyle(fontSize: 9, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    } else {
                      bgColor = Colors.green.shade50;
                      borderColor = Colors.green.shade300;
                      textColor = const Color(0xFF1B5E20);
                      badge = const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 11, color: Color(0xFF1B5E20)),
                          SizedBox(width: 4),
                          Text('متاحة بالكامل', style: TextStyle(fontSize: 9, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                        ],
                      );
                    }

                    return InkWell(
                      onTap: isConfirmed
                          ? null
                          : () => onSlotSelected(isSelected ? null : slot),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            badge,
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

  Widget _legendItem(String label, Color dotColor, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dotColor)),
        ],
      ),
    );
  }
}
