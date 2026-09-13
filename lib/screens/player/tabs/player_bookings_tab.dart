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
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
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
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';

              Color statusColor = Colors.amber;
              String statusText = 'قيد المراجعة ⏳';
              if (status == 'upcoming') {
                statusColor = Colors.green;
                statusText = 'مؤكد ومثبت ✔️';
              } else if (status == 'rejected') {
                statusColor = Colors.red;
                statusText = 'مرفوض أو ملغي ❌';
              } else if (status == 'completed') {
                statusColor = Colors.blue;
                statusText = 'مكتمل ولُعب ⚽';
              }

              final bool canCancel = status == 'pending' || status == 'upcoming';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.sports_soccer, color: Color(0xFF1B5E20)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['pitchName'] ?? 'ملعب رياضي',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '📅 ${data['date'] ?? ''}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              statusText,
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAF7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF1B5E20)),
                            const SizedBox(width: 6),
                            Text(
                              'الفترة: ${data['startTime']} إلى ${data['endTime']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (data['price'] != null)
                              Text(
                                '${data['price']} د.ع',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                          ],
                        ),
                      ),
                      if (canCancel) ...[
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              status == 'pending' ? 'يمكنك سحب الطلب قبل موافقة الملعب' : 'إلغاء الموعد وإفساح المجال لغيرك',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: Text(
                                status == 'pending' ? 'سحب الطلب ❌' : 'إلغاء الحجز ❌',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () => _confirmCancelBooking(context, doc.reference, status),
                            ),
                          ],
                        ),
                      ],
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

  void _confirmCancelBooking(BuildContext context, DocumentReference docRef, String currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(currentStatus == 'pending' ? 'سحب طلب الحجز؟' : 'إلغاء موعد الحجز؟'),
          content: Text(
            currentStatus == 'pending'
                ? 'هل أنت متأكد من سحب هذا الطلب المعلق؟ سيتم حذفه ولن يظهر لإدارة الملعب.'
                : 'هل أنت متأكد من إلغاء هذا الحجز المؤكد؟ سيتم إخطار صاحب الملعب وإتاحة هذه الساعة للفرق الأخرى.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تراجع'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (currentStatus == 'pending') {
                  await docRef.delete();
                } else {
                  await docRef.update({
                    'status': 'rejected',
                    'cancelledByPlayer': true,
                  });
                }
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(currentStatus == 'pending' ? 'تم سحب الطلب بنجاح' : 'تم إلغاء الحجز بنجاح'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              },
              child: const Text(
                'نعم، تأكيد الإلغاء',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
