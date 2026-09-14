import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/owner_request_card.dart';

class OwnerRequestsTab extends StatelessWidget {
  final String pitchName;
  const OwnerRequestsTab({super.key, required this.pitchName});

  Future<void> _approveBookingAndAutoRejectConflicts(
    BuildContext context,
    DocumentSnapshot approvedDoc,
  ) async {
    final approvedData = approvedDoc.data() as Map<String, dynamic>;
    final date = approvedData['date'];
    final startTime = approvedData['startTime'];
    final firestore = FirebaseFirestore.instance;

    await approvedDoc.reference.update({
      'status': 'upcoming',
      'seenByPlayer': false,
    });

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
          'seenByPlayer': false,
        });
        rejectedCount++;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rejectedCount > 0
                ? 'تم تثبيت الحجز بالجدول، ورفض $rejectedCount طلبات منافسة لنفس الساعة تلقائياً'
                : 'تم تثبيت الحجز وإدراجه في جدول المباريات بنجاح',
          ),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    }
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            titlePadding: const EdgeInsets.all(18),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'رفض طلب الحجز',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'يرجى كتابة سبب رفض طلب فريق ($teamName) ليظهر في إشعار الكابتن:',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'اكتب سبب الرفض هنا...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('أسباب سريعة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: quickReasons.map((r) => ActionChip(
                      label: Text(r, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onPressed: () {
                        setDlgState(() => reasonController.text = r);
                      },
                    )).toList(),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('تراجع', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
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
                child: const Text('تأكيد الرفض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
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
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.inbox_rounded, size: 34, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'لا توجد طلبات حجز معلقة حالياً',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'الطلبات الجديدة التي يرسلها الكباتن ستظهر هنا',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return OwnerRequestCard(
                doc: doc,
                onApprove: () => _approveBookingAndAutoRejectConflicts(context, doc),
                onReject: () => _openRejectDialog(context, doc.reference, data['teamOne'] ?? 'الكابتن'),
              );
            },
          );
        },
      ),
    );
  }
}
