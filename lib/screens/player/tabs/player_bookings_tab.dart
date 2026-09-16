import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../dialogs/pitch_evaluation_dialog.dart';

class PlayerBookingsTab extends StatefulWidget {
  final String userPhone;

  const PlayerBookingsTab({super.key, required this.userPhone});

  @override
  State<PlayerBookingsTab> createState() => _PlayerBookingsTabState();
}

class _PlayerBookingsTabState extends State<PlayerBookingsTab> {
  bool _showPastBookings = true;

  List<String> _getPhoneVariants(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+|-'), '');
    final variants = <String>{clean};

    if (clean.startsWith('07')) {
      variants.add('964${clean.substring(1)}');
      variants.add('+964${clean.substring(1)}');
    } else if (clean.startsWith('964')) {
      variants.add('0${clean.substring(3)}');
      variants.add('+$clean');
    } else if (clean.startsWith('+964')) {
      variants.add('0${clean.substring(4)}');
      variants.add(clean.substring(1));
    }

    return variants.toList();
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
      case 'removed_from_tournament': return 'تمت الإزالة من البطولة';
      default: return status;
    }
  }

  bool _shouldBeArchived(Map<String, dynamic> data) {
    try {
      final status = (data['status'] ?? '').toString();
      if (data['isArchived'] == true) return true;

      final dateStr = (data['date'] ?? '').toString();
      if (dateStr.isNotEmpty) {
        final bookingDate = DateFormat('yyyy-MM-dd').parse(dateStr);
        final now = DateTime.now();
        final todayDateOnly = DateTime(now.year, now.month, now.day);
        if (bookingDate.isBefore(todayDateOnly)) return true;
      }

      if (status == 'rejected' || status == 'removed_from_tournament' || status == 'completed' || status == 'cancelled') {
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          final difference = DateTime.now().difference(createdAt.toDate());
          if (difference.inHours >= 24) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _moveToArchive(String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'isArchived': true});
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final phoneVariants = _getPhoneVariants(widget.userPhone);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('phone', whereIn: phoneVariants)
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

            final item = Map<String, dynamic>.from(data);
            item['id'] = doc.id;

            if (_shouldBeArchived(item)) {
              pastBookings.add(item);
            } else {
              activeBookings.add(item);
            }
          }

          int sortBookings(Map<String, dynamic> a, Map<String, dynamic> b) {
            final dateA = (a['date'] ?? '').toString();
            final dateB = (b['date'] ?? '').toString();
            final timeA = (a['startTime'] ?? '').toString();
            final timeB = (b['startTime'] ?? '').toString();
            final comp = dateB.compareTo(dateA);
            if (comp != 0) return comp;
            return timeB.compareTo(timeA);
          }

          activeBookings.sort(sortBookings);
          pastBookings.sort(sortBookings);

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
                const SizedBox(height: 16),
              ],

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showPastBookings = !_showPastBookings),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.archive_outlined, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text(
                              'أرشيف المباريات والسجلات السابقة (${pastBookings.length})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
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
                      const Divider(height: 1),
                      if (pastBookings.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('لا توجد مباريات سابقة في الأرشيف', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(10),
                          itemCount: pastBookings.length,
                          itemBuilder: (context, index) => _buildBookingCard(pastBookings[index], currencyFormatter, isPast: true),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b, NumberFormat currencyFormatter, {required bool isPast}) {
    final bookingId = b['id'] ?? '';
    final pitchName = b['pitchName'] ?? 'الملعب';
    final teamOne = b['teamOne'] ?? 'فريقك';
    final teamTwo = (b['teamTwo'] ?? '').toString().trim();
    final dateStr = b['date'] ?? '';
    final startTime = b['startTime'] ?? '';
    final endTime = b['endTime'] ?? '';
    final status = b['status'] ?? 'pending';
    final price = (b['price'] as num?)?.toDouble() ?? 25000.0;

    final statusColor = _getStatusColor(status);
    final statusText = _getStatusArabicText(status);

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

            if (!isPast) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'completed' && b['pitchRating'] == null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B5E20),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.star_rate_rounded, size: 15),
                      label: const Text('تقييم الملعب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => PitchEvaluationDialog.show(
                        context,
                        bookingId: bookingId,
                        pitchName: pitchName,
                        userPhone: widget.userPhone,
                      ),
                    ),
                  if (status == 'rejected' || status == 'removed_from_tournament' || status == 'completed') ...[
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _moveToArchive(bookingId),
                      child: const Text('نقل للأرشيف', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
