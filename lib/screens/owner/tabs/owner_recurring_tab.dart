import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants.dart';

class OwnerRecurringTab extends StatelessWidget {
  final String pitchName;
  const OwnerRecurringTab({super.key, required this.pitchName});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recurring_rules')
            .where('pitchName', isEqualTo: pitchName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat_rounded, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text('لا توجد حجوزات أسبوعية ثابتة حالياً',
                      style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('اضغط على الزر الدائري لإضافة حجز أسبوعي دائم', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final phone = data['phone'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.repeat, color: Colors.purple),
                  ),
                  title: Text('كل يوم ${data['dayOfWeek']} (${data['timeSlot']})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('محجوز دائماً لـ: ${data['teamName']} - (${data['price']} د.ع)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (phone.toString().isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () => launchCallDirect(phone),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => doc.reference.delete(),
                      ),
                    ],
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
