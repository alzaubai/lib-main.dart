import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OwnerArchiveSheet extends StatelessWidget {
  final String pitchName;

  const OwnerArchiveSheet({super.key, required this.pitchName});

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currency = NumberFormat('#,###');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF1B5E20), size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'أرشيف المباريات المكتملة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const Divider(height: 22),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('pitchName', isEqualTo: pitchName)
                    .where('status', isEqualTo: 'completed')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final completedList = docs
                      .map((d) => d.data() as Map<String, dynamic>)
                      .where((d) => d['isDeleted'] != true)
                      .toList();

                  if (completedList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 54, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد مباريات مؤرشفة حتى الآن',
                            style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: completedList.length,
                    itemBuilder: (context, index) {
                      final item = completedList[index];
                      final team = item['teamOne'] ?? 'فريق كروي';
                      final date = item['date'] ?? '';
                      final time = '${item['startTime']} - ${item['endTime']}';
                      final price = (item['price'] as num?)?.toDouble() ?? 25000.0;
                      final isToday = date == todayStr;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isToday ? Colors.green.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: isToday ? const Color(0xFF1B5E20) : Colors.blue.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(team, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                      if (isToday) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('اليوم', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text('$date  •  $time', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Text(
                              '${currency.format(price)} د.ع',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B5E20)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
