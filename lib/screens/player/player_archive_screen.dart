import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PlayerArchiveScreen extends StatelessWidget {
  final String userPhone;
  
  const PlayerArchiveScreen({super.key, required this.userPhone});

  List<String> _getPhoneVariants(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+|-'), '');
    final variants = <String>{clean};
    if (clean.startsWith('07')) { variants.add('964${clean.substring(1)}'); variants.add('+964${clean.substring(1)}'); }
    else if (clean.startsWith('964')) { variants.add('0${clean.substring(3)}'); variants.add('+$clean'); }
    else if (clean.startsWith('+964')) { variants.add('0${clean.substring(4)}'); variants.add(clean.substring(1)); }
    return variants.toList();
  }

  bool _shouldBeArchived(Map<String, dynamic> data) {
    try {
      if (data['isArchived'] == true) return true;
      final dateStr = (data['date'] ?? '').toString();
      if (dateStr.isNotEmpty) {
        final bookingDate = DateFormat('yyyy-MM-dd').parse(dateStr);
        final todayDateOnly = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        if (bookingDate.isBefore(todayDateOnly)) return true;
      }
      final status = (data['status'] ?? '').toString();
      if (['rejected', 'removed_from_tournament', 'completed', 'cancelled'].contains(status)) {
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp && DateTime.now().difference(createdAt.toDate()).inHours >= 24) return true;
      }
    } catch (_) {}
    return false;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return const Color(0xFF1B5E20);
      case 'pending': return Colors.amber.shade800;
      case 'completed': return Colors.blue.shade700;
      case 'cancelled':
      case 'rejected':
      case 'removed_from_tournament': return Colors.red.shade700;
      default: return const Color(0xFF64748B);
    }
  }

  String _getStatusArabicText(String status) {
    switch (status) {
      case 'confirmed': return 'مؤكد';
      case 'pending': return 'قيد الانتظار';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      case 'rejected': return 'مرفوض';
      case 'removed_from_tournament': return 'تمت الإزالة';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final phoneVariants = _getPhoneVariants(userPhone);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: const Text('أرشيف المباريات السابقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('phone', whereIn: phoneVariants)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
            }

            final pastBookings = <Map<String, dynamic>>[];
            for (var doc in snapshot.data?.docs ?? []) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['isDeleted'] == true) continue;
              final item = Map<String, dynamic>.from(data);
              item['id'] = doc.id;
              if (_shouldBeArchived(item)) pastBookings.add(item);
            }

            pastBookings.sort((a, b) {
              final comp = (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString());
              if (comp != 0) return comp;
              return (b['startTime'] ?? '').toString().compareTo((a['startTime'] ?? '').toString());
            });

            if (pastBookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.archive_outlined, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('الأرشيف فارغ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: pastBookings.length,
              itemBuilder: (context, index) {
                final b = pastBookings[index];
                final pitchName = b['pitchName'] ?? 'الملعب';
                final teamOne = b['teamOne'] ?? 'فريقك';
                final teamTwo = (b['teamTwo'] ?? '').toString().trim();
                final dateStr = b['date'] ?? '';
                final time = '${b['startTime']} - ${b['endTime']}';
                final status = b['status'] ?? 'pending';
                final price = (b['price'] as num?)?.toDouble() ?? 25000.0;
                
                final statusColor = _getStatusColor(status);
                final statusText = _getStatusArabicText(status);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.sports_soccer_rounded, size: 20, color: Colors.grey),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569))),
                                  const SizedBox(height: 2),
                                  Text(teamTwo.isNotEmpty && teamTwo != 'طرف ثانٍ غير محدد' ? '$teamOne ضد $teamTwo' : teamOne, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$dateStr  •  $time', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            Text('${currencyFormatter.format(price)} د.ع', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey)),
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
      ),
    );
  }
}
