import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerBookingsTab extends StatelessWidget {
  final String userPhone;
  const PlayerBookingsTab({super.key, required this.userPhone});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('phone', isEqualTo: userPhone)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد لديك حجوزات سابقة أو حالية',
                style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';

              Color statusColor = Colors.amber;
              String statusText = 'قيد المراجعة ⏳';
              if (status == 'upcoming') {
                statusColor = Colors.green;
                statusText = 'مؤكد ومثبت ✔️';
              } else if (status == 'rejected') {
                statusColor = Colors.red;
                statusText = 'مرفوض ❌';
              } else if (status == 'completed') {
                statusColor = Colors.blue;
                statusText = 'مكتمل ولُعب ⚽';
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.sports_soccer, color: Color(0xFF1B5E20)),
                  ),
                  title: Text(
                    '${data['pitchName']} (${data['date']})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text('الفترة: ${data['startTime']} إلى ${data['endTime']}'),
                  trailing: Chip(
                    label: Text(
                      statusText,
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: statusColor,
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
