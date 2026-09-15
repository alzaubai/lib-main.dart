import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OwnerRequestsTab extends StatefulWidget {
  final String pitchName;

  const OwnerRequestsTab({super.key, required this.pitchName});

  @override
  State<OwnerRequestsTab> createState() => _OwnerRequestsTabState();
}

class _OwnerRequestsTabState extends State<OwnerRequestsTab> {
  final Set<String> _processingDocs = {};

  Future<void> _approveRequest(DocumentSnapshot doc) async {
    final docId = doc.id;
    if (_processingDocs.contains(docId)) return;

    setState(() => _processingDocs.add(docId));

    try {
      final data = doc.data() as Map<String, dynamic>;
      final userPhone = data['phone']?.toString() ?? '';
      final teamOne = data['teamOne']?.toString() ?? 'فريق كابتن';
      final date = data['date']?.toString() ?? '';
      final startTime = data['startTime']?.toString() ?? '';

      final batch = FirebaseFirestore.instance.batch();

      // 1. تحديث حالة الحجز إلى confirmed لينزل فوراً بجدول المالك
      batch.update(doc.reference, {
        'status': 'confirmed',
        'seenByPlayer': false,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // 2. إرسال إشعار فوري للاعب
      if (userPhone.isNotEmpty) {
        final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifRef, {
          'userPhone': userPhone,
          'type': 'booking_approved',
          'title': 'تم تأكيد حجزك رسمياً! ⚽',
          'body': 'تمت الموافقة على حجز فريق ($teamOne) بتاريخ $date الساعة $startTime',
          'bookingId': docId,
          'seen': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تأكيد حجز ($teamOne) ونزوله بالجدول'),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تأكيد الحجز'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processingDocs.remove(docId));
    }
  }

  void _showRejectDialog(DocumentSnapshot doc) {
    final reasonCtrl = TextEditingController();
    final data = doc.data() as Map<String, dynamic>;
    final teamOne = data['teamOne']?.toString() ?? 'فريق كابتن';

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('رفض طلب حجز ($teamOne)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('يرجى تحديد سبب الرفض لإبلاغ الكابتن:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'مثلاً: صيانة أرضية الملعب، أو الموعد محجوز مسبقاً...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) return;

                Navigator.pop(ctx);
                final docId = doc.id;
                setState(() => _processingDocs.add(docId));

                try {
                  final userPhone = data['phone']?.toString() ?? '';
                  final date = data['date']?.toString() ?? '';
                  final startTime = data['startTime']?.toString() ?? '';

                  final batch = FirebaseFirestore.instance.batch();

                  batch.update(doc.reference, {
                    'status': 'rejected',
                    'rejectionReason': reason,
                    'seenByPlayer': false,
                    'rejectedAt': FieldValue.serverTimestamp(),
                  });

                  if (userPhone.isNotEmpty) {
                    final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
                    batch.set(notifRef, {
                      'userPhone': userPhone,
                      'type': 'booking_rejected',
                      'title': 'تم الاعتذار عن موعد الحجز',
                      'body': 'نعتذر عن حجز موعد $date ($startTime). السبب: $reason',
                      'bookingId': docId,
                      'seen': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }

                  await batch.commit();
                } catch (_) {} finally {
                  if (mounted) setState(() => _processingDocs.remove(docId));
                }
              },
              child: const Text('تأكيد الرفض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('pitchName', isEqualTo: widget.pitchName)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          final docs = (snapshot.data?.docs ?? []).where((d) {
            final m = d.data() as Map<String, dynamic>;
            return m['isDeleted'] != true;
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('لا توجد طلبات حجز معلقة حالياً', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  const Text('الطلبات الجديدة التي يرسلها اللاعبون ستظهر هنا', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
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
              final isBusy = _processingDocs.contains(doc.id);

              final teamOne = data['teamOne'] ?? 'فريق كابتن';
              final teamTwo = data['teamTwo'] ?? '';
              final phone = data['phone'] ?? '';
              final date = data['date'] ?? '';
              final startTime = data['startTime'] ?? '';
              final endTime = data['endTime'] ?? '';
              final price = (data['price'] as num?)?.toDouble() ?? 25000.0;

              return Card(
                elevation: 1.5,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.schedule_send_rounded, color: Colors.amber.shade900, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teamTwo.isNotEmpty && teamTwo != 'طرف ثانٍ غير محدد' && teamTwo != 'تحدي مفتوح'
                                      ? '$teamOne ضد $teamTwo'
                                      : teamOne,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text('هاتف الكابتن: $phone', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                            child: Text('${currencyFormatter.format(price)} د.ع', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_note_rounded, size: 14, color: Color(0xFF1B5E20)),
                                const SizedBox(width: 4),
                                Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF1B5E20)),
                                const SizedBox(width: 4),
                                Text('$startTime - $endTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: isBusy
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_circle_rounded, size: 16),
                              label: const Text('تأكيد وقبول الحجز', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: isBusy ? null : () => _approveRequest(doc),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('رفض', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: isBusy ? null : () => _showRejectDialog(doc),
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
}
