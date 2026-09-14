import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants.dart';

class OwnerRequestsTab extends StatelessWidget {
  final String pitchName;
  const OwnerRequestsTab({super.key, required this.pitchName});

  // دالة قبول الطلب مع الرفض التلقائي الذكي للطلبات المتنافسة على نفس الساعة
  Future<void> _approveBookingAndAutoRejectConflicts(
    BuildContext context,
    DocumentSnapshot approvedDoc,
  ) async {
    final approvedData = approvedDoc.data() as Map<String, dynamic>;
    final date = approvedData['date'];
    final startTime = approvedData['startTime'];
    final firestore = FirebaseFirestore.instance;

    // 1. تثبيت هذا الحجز ونقله للحجوزات المؤكدة
    await approvedDoc.reference.update({
      'status': 'upcoming',
      'seenByPlayer': false, // لإشعار الكابتن الفائز بالموافقة
    });

    // 2. البحث عن أي طلبات أخرى معلقة مقدمة على نفس الملعب والتاريخ والساعة
    final conflictSnap = await firestore
        .collection('bookings')
        .where('pitchName', isEqualTo: pitchName)
        .where('date', isEqualTo: date)
        .where('startTime', isEqualTo: startTime)
        .where('status', isEqualTo: 'pending')
        .get();

    int rejectedCount = 0;
    for (var doc in conflictSnap.docs) {
      if (doc.id != approvedDoc.id) {
        await doc.reference.update({
          'status': 'rejected',
          'rejectionReason': 'نعتذر منك، تم تثبيت هذا الموعد لفريق آخر أسبق في التأكيد',
          'seenByPlayer': false, // لإشعارهم بالرفض فوراً مع السبب
        });
        rejectedCount++;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rejectedCount > 0
                ? 'تم تثبيت الحجز بالجدول، ورفض $rejectedCount طلبات منافسة لنفس الساعة تلقائياً ✔️'
                : 'تم تثبيت الحجز بنجاح وإدراجه في جدول المباريات ✔️',
          ),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('pitchName', isEqualTo: pitchName)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'لا توجد طلبات حجز معلقة حالياً',
                    style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
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
                color: Colors.amber.shade50,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.amber.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'طلب حجز من: ${data['teamOne']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20)),
                          ),
                          Chip(
                            label: const Text('معلق ⏳', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.amber.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '📅 التاريخ: ${data['date']} (${data['startTime']} - ${data['endTime']})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text('💰 المبلغ: ${data['price']} د.ع', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                      const Divider(height: 20),
                      Row(
                        children: [
                          if (phone.toString().isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () => launchCallDirect(phone),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                              onPressed: () => launchWhatsAppDirect(phone),
                            ),
                          ],
                          const Spacer(),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('رفض'),
                            onPressed: () => _openRejectDialog(context, doc.reference, data['teamOne'] ?? 'الكابتن'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                            icon: const Icon(Icons.check, size: 16, color: Colors.white),
                            label: const Text('تثبيت وقبول', style: TextStyle(color: Colors.white)),
                            onPressed: () => _approveBookingAndAutoRejectConflicts(context, doc),
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

  void _openRejectDialog(BuildContext context, DocumentReference docRef, String teamName) {
    final reasonController = TextEditingController();
    final List<String> quickReasons = [
      'الملعب يخضع للصيانة الدورية',
      'الموعد محجوز مسبقاً باتصال مباشر',
      'عطلة رسمية أو ظرف طارئ بالملعب',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.cancel_rounded, color: Colors.red.shade700, size: 26),
                const SizedBox(width: 8),
                const Text('رفض طلب الحجز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('يرجى كتابة سبب رفض حجز فريق ($teamName) ليظهر في إشعار اللاعب:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'اكتب سبب الرفض هنا...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('أسباب سريعة وجاهزة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: quickReasons.map((r) => ActionChip(
                      label: Text(r, style: const TextStyle(fontSize: 10)),
                      backgroundColor: Colors.grey.shade100,
                      onPressed: () {
                        setDlgState(() {
                          reasonController.text = r;
                        });
                      },
                    )).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  final reason = reasonController.text.trim().isEmpty
                      ? 'اعتذار من إدارة الملعب لعدم توفر الموعد'
                      : reasonController.text.trim();

                  await docRef.update({
                    'status': 'rejected',
                    'rejectionReason': reason,
                    'seenByPlayer': false,
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('تأكيد الرفض وإرسال السبب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
