import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PlayerBookingsTab extends StatefulWidget {
  final String userPhone;

  const PlayerBookingsTab({super.key, required this.userPhone});

  @override
  State<PlayerBookingsTab> createState() => _PlayerBookingsTabState();
}

class _PlayerBookingsTabState extends State<PlayerBookingsTab> {
  bool _showPastBookings = false;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF1B5E20);
      case 'pending':
        return Colors.amber.shade800;
      case 'completed':
        return Colors.blue.shade700;
      case 'cancelled':
      case 'rejected':
        return Colors.red.shade700;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusArabicText(String status) {
    switch (status) {
      case 'confirmed':
        return 'مؤكد';
      case 'pending':
        return 'قيد الانتظار';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  bool _isPastBooking(String dateStr) {
    try {
      final bookingDate = DateFormat('yyyy-MM-dd').parse(dateStr);
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      return bookingDate.isBefore(todayDateOnly);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('phone', isEqualTo: widget.userPhone)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          final docs = snapshot.data?.docs ?? [];
          final List<Map<String, dynamic>> activeBookings = [];
          final List<Map<String, dynamic>> pastBookings = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isDeleted'] == true) continue;

            final dateStr = (data['date'] ?? '').toString();
            final status = (data['status'] ?? 'pending').toString();
            final item = Map<String, dynamic>.from(data);
            item['id'] = doc.id;

            if (_isPastBooking(dateStr) || status == 'completed' || status == 'cancelled' || status == 'rejected') {
              pastBookings.add(item);
            } else {
              activeBookings.add(item);
            }
          }

          if (activeBookings.isEmpty && pastBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'لا توجد لديك أي حجوزات مسجلة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'يمكنك استكشاف الملاعب وحجز موعد لمباراتك القادمة',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              if (activeBookings.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 10, right: 4),
                  child: Text(
                    'الحجوزات القادمة والنشطة',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  ),
                ),
                ...activeBookings.map((b) => _buildBookingCard(b, currencyFormatter, isPast: false)),
                const SizedBox(height: 10),
              ],

              if (pastBookings.isNotEmpty) ...[
                InkWell(
                  onTap: () => setState(() => _showPastBookings = !_showPastBookings),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.archive_outlined, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          'أرشيف المباريات السابقة (${pastBookings.length})',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const Spacer(),
                        Icon(
                          _showPastBookings ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showPastBookings) ...[
                  const SizedBox(height: 10),
                  ...pastBookings.map((b) => _buildBookingCard(b, currencyFormatter, isPast: true)),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b, NumberFormat currencyFormatter, {required bool isPast}) {
    final pitchName = b['pitchName'] ?? 'الملعب';
    final teamOne = b['teamOne'] ?? 'فريقك';
    final teamTwo = (b['teamTwo'] ?? '').toString().trim();
    final dateStr = b['date'] ?? '';
    final startTime = b['startTime'] ?? '';
    final endTime = b['endTime'] ?? '';
    final status = b['status'] ?? 'pending';
    final price = (b['price'] as num?)?.toDouble() ?? 25000.0;

    final statusColor = isPast && status == 'confirmed' ? Colors.blue.shade700 : _getStatusColor(status);
    final statusText = isPast && status == 'confirmed' ? 'منتهية' : _getStatusArabicText(status);

    return Card(
      elevation: isPast ? 0.5 : 1.5,
      margin: const EdgeInsets.only(bottom: 10),
      color: isPast ? const Color(0xFFF8FAFC) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isPast ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPast ? Colors.grey.shade100 : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.sports_soccer_rounded,
                    size: 20,
                    color: isPast ? Colors.grey : const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pitchName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isPast ? const Color(0xFF475569) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teamTwo.isNotEmpty && teamTwo != 'طرف ثانٍ غير محدد'
                            ? '$teamOne ضد $teamTwo'
                            : teamOne,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPast ? Colors.grey : const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(dateStr, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    const SizedBox(width: 10),
                    const Icon(Icons.schedule_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$startTime - $endTime', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  ],
                ),
                Text(
                  '${currencyFormatter.format(price)} د.ع',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isPast ? Colors.grey : const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
