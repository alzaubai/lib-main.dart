import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';

class OwnerRecurringTab extends StatelessWidget {
  final String pitchName;
  const OwnerRecurringTab({super.key, required this.pitchName});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.repeat_rounded, size: 60, color: Colors.purple.shade400),
                  ),
                  const SizedBox(height: 14),
                  const Text('لا توجد حجوزات أسبوعية ثابتة حالياً',
                      style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('اضغط على الزر البنفسجي بالأسفل لتثبيت اشتراك أسبوعي دائم',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
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
              final day = data['dayOfWeek'] ?? 'الجمعة';
              final slot = data['timeSlot'] ?? '';
              final team1 = data['teamName'] ?? 'فريق أساسي';
              final team2 = data['teamTwo'] ?? 'تحدي مفتوح';
              final phone = data['phone'] ?? '';
              final price = (data['price'] as num?)?.toDouble() ?? 25000.0;

              return Card(
                elevation: 3,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.purple.shade200, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.repeat, color: Colors.purple, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'كل يوم $day',
                                  style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              '${currencyFormatter.format(price)} د.ع',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // مواجهة الفريقين
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF9FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade50),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                team1,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('⚔️ VS ⚔️', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                            Expanded(
                              child: Text(
                                team2,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(slot, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 22),

                      Row(
                        children: [
                          if (phone.toString().isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green),
                              tooltip: 'اتصال بالكابتن',
                              onPressed: () => launchCallDirect(phone),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                              tooltip: 'واتساب',
                              onPressed: () => launchWhatsAppDirect(phone),
                            ),
                          ],
                          const Spacer(),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.delete_forever_rounded, size: 18),
                            label: const Text('إلغاء الاشتراك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () => _confirmDeleteRecurring(context, doc.reference, team1, day),
                          ),
                        ],
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

  void _confirmDeleteRecurring(BuildContext context, DocumentReference docRef, String teamName, String day) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('إلغاء الحجز الأسبوعي الدائم؟'),
          content: Text('هل أنت متأكد من إلغاء اشتراك ($teamName) ليوم $day؟ ستصبح هذه الساعة متاحة للحجز العام مجدداً.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await docRef.delete();
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('نعم، إلغاء الحجز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
