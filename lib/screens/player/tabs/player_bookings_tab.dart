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
  bool _showPastBookings = true;

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
      case 'removed_from_tournament':
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
      case 'removed_from_tournament':
        return 'تمت الإزالة من البطولة';
      default:
        return status;
    }
  }

  bool _shouldBeArchived(Map<String, dynamic> data) {
    try {
      final status = (data['status'] ?? '').toString();
      if (data['isArchived'] == true) return true;

      final dateStr = (data['date'] ?? '').toString();
      if (dateStr.isEmpty) return false;

      final bookingDate = DateFormat('yyyy-MM-dd').parse(dateStr);
      final now = DateTime.now();
      final todayDateOnly = DateTime(now.year, now.month, now.day);

      if (bookingDate.isBefore(todayDateOnly)) {
        return true;
      }

      if (status == 'rejected' || status == 'removed_from_tournament' || status == 'completed' || status == 'cancelled') {
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          final difference = now.difference(createdAt.toDate());
          if (difference.inHours >= 24) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _submitPitchEvaluation({
    required String bookingId,
    required String pitchName,
    required int rating,
    required String tag,
    required String note,
  }) async {
    try {
      // 1. تحديث وثيقة الحجز
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'isArchived': true,
        'pitchRating': rating,
        'pitchReviewTag': tag,
        'pitchReviewNote': note,
      });

      // 2. مزامنة التقييم مع وثيقة الملعب ليظهر لباقي اللاعبين
      final pitchQuery = await FirebaseFirestore.instance
          .collection('pitches')
          .where('name', isEqualTo: pitchName)
          .limit(1)
          .get();

      if (pitchQuery.docs.isNotEmpty) {
        final pitchDoc = pitchQuery.docs.first;
        final pitchData = pitchDoc.data();

        final currentTotalRatings = (pitchData['totalRatings'] as num?)?.toInt() ?? 0;
        final currentRatingSum = (pitchData['ratingSum'] as num?)?.toDouble() ?? 0.0;

        final newTotal = currentTotalRatings + 1;
        final newSum = currentRatingSum + rating;
        final newAverage = double.parse((newSum / newTotal).toStringAsFixed(1));

        await pitchDoc.reference.update({
          'rating': newAverage,
          'totalRatings': newTotal,
          'ratingSum': newSum,
          'reviews': FieldValue.arrayUnion([
            {
              'rating': rating,
              'tag': tag,
              'note': note,
              'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            }
          ]),
        });
      }
    } catch (e) {
      debugPrint('Error updating pitch review: $e');
    }
  }

  void _showPitchEvaluationDialog(String bookingId, String pitchName) {
    final List<String> quickTags = [
      'أرضية الملعب ممتازة',
      'تنظيم وإدارة احترافية',
      'التزام تام بالمواعيد',
      'إنارة واضحة وقوية',
      'مرافق نظيفة ومرتبة'
    ];
    String selectedTag = quickTags.first;
    int rating = 5;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'تقييم تجربة اللعب: $pitchName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('التقييم العام بالنجوم:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: starVal <= rating ? const Color(0xFFF59E0B) : Colors.grey,
                          size: 30,
                        ),
                        onPressed: () => setDialogState(() => rating = starVal),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  const Text('اختر انطباعك الأساسي:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTag,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: quickTags.map((tag) => DropdownMenuItem(value: tag, child: Text(tag, style: const TextStyle(fontSize: 12.5)))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedTag = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('ملاحظات إضافية (اختياري):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'اكتب ملاحظتك الموضوعية عن الملعب...',
                      hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'isArchived': true});
                },
                child: const Text('تخطي', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _submitPitchEvaluation(
                    bookingId: bookingId,
                    pitchName: pitchName,
                    rating: rating,
                    tag: selectedTag,
                    note: noteCtrl.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال تقييمك للملعب بنجاح'), backgroundColor: Color(0xFF1B5E20)),
                    );
                  }
                },
                child: const Text('تأكيد التقييم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveToArchive(String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'isArchived': true});
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

            final item = Map<String, dynamic>.from(data);
            item['id'] = doc.id;

            if (_shouldBeArchived(item)) {
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
                  // حصرياً إذا كان مكتمل فقط ولم يقم بالتقييم بعد
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
                      onPressed: () => _showPitchEvaluationDialog(bookingId, pitchName),
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
