import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/time_parser_util.dart';
import '../sheets/add_manual_booking_sheet.dart';
import 'widgets/today_financial_card.dart'; // استدعاء الكرت المالي الجديد لليوم الحالي

class OwnerScheduleTab extends StatefulWidget {
  final String pitchName;

  const OwnerScheduleTab({super.key, required this.pitchName});

  @override
  State<OwnerScheduleTab> createState() => _OwnerScheduleTabState();
}

class _OwnerScheduleTabState extends State<OwnerScheduleTab> {
  DateTime _selectedDate = DateTime.now();

  void _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+|-'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\s+|-'), '');
    if (cleanPhone.startsWith('07')) {
      cleanPhone = '964${cleanPhone.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _completeBooking(String docId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
      'status': 'completed',
    });
    if (mounted) {
      _showCenterToast('تم تحديد الحجز كمكتمل');
    }
  }

  Future<void> _cancelBooking(String docId, String teamName) async {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('إلغاء الحجز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: Text('هل أنت متأكد من إلغاء حجز فريق ($teamName) وتفريغ هذا الوقت في الجدول؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                  'isDeleted': true,
                  'status': 'cancelled',
                });
                if (mounted) {
                  _showCenterToast('تم إلغاء الحجز بنجاح');
                }
              },
              child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCenterToast(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF1B5E20);
      case 'completed':
        return Colors.blue.shade700;
      case 'recurring':
        return Colors.purple.shade800;
      default:
        return const Color(0xFF0F172A);
    }
  }

  String _getStatusArabicText(String status) {
    switch (status) {
      case 'confirmed':
        return 'حجز مؤكد';
      case 'completed':
        return 'مكتمل';
      case 'recurring':
        return 'اشتراك دائم';
      default:
        return 'محجوز';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayNameArabic = TimeParserUtil.getArabicDayName(_selectedDate);
    final currencyFormatter = NumberFormat('#,###');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          // 1. الكرت المالي المستقل الخاص باليوم الحالي حصراً
          TodayFinancialCard(pitchName: widget.pitchName),

          // 2. شريط الأيام الأفقي الخاص بالجدول
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_rounded, color: Color(0xFF1B5E20), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'جدول مباريات: $dayNameArabic ($dateStr)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const Spacer(),
                      if (!DateUtils.isSameDay(_selectedDate, DateTime.now()))
                        TextButton(
                          onPressed: () => setState(() => _selectedDate = DateTime.now()),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          child: const Text('اليوم', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 65,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 14,
                    itemBuilder: (context, index) {
                      final day = DateTime.now().add(Duration(days: index));
                      final isSelected = DateUtils.isSameDay(_selectedDate, day);
                      final dName = TimeParserUtil.getArabicDayName(day);
                      final dNum = DateFormat('d').format(day);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dNum,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. قائمة الحجوزات الخاصة باليوم المختار في الجدول
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('pitchName', isEqualTo: widget.pitchName)
                  .where('date', isEqualTo: dateStr)
                  .snapshots(),
              builder: (context, snapBookings) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('recurring_rules')
                      .where('pitchName', isEqualTo: widget.pitchName)
                      .where('dayOfWeek', isEqualTo: dayNameArabic)
                      .snapshots(),
                  builder: (context, snapRecurring) {
                    if (snapBookings.connectionState == ConnectionState.waiting &&
                        snapRecurring.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                    }

                    final bookingsDocs = snapBookings.data?.docs ?? [];
                    final recurringDocs = snapRecurring.data?.docs ?? [];
                    final List<Map<String, dynamic>> allSlots = [];

                    for (var doc in bookingsDocs) {
                      final d = doc.data() as Map<String, dynamic>;
                      if (d['isDeleted'] == true) continue;
                      final st = (d['status'] ?? '').toString();
                      if (st != 'confirmed' && st != 'completed') continue;

                      final map = Map<String, dynamic>.from(d);
                      map['docId'] = doc.id;
                      map['isRecurringRule'] = false;
                      allSlots.add(map);
                    }

                    for (var rDoc in recurringDocs) {
                      final rd = rDoc.data() as Map<String, dynamic>;
                      final startTime = rd['startTime'] ?? '';
                      bool alreadyBooked = allSlots.any((s) => s['startTime'] == startTime);

                      if (!alreadyBooked) {
                        allSlots.add({
                          'docId': rDoc.id,
                          'pitchName': widget.pitchName,
                          'teamOne': rd['teamName'] ?? 'فريق دائم',
                          'teamTwo': '',
                          'phone': rd['phone'] ?? '',
                          'date': dateStr,
                          'startTime': startTime,
                          'endTime': rd['endTime'] ?? '',
                          'price': rd['price'] ?? 25000,
                          'status': 'recurring',
                          'isRecurringRule': true,
                        });
                      }
                    }

                    allSlots.sort((a, b) {
                      final tA = a['startTime'] ?? '';
                      final tB = b['startTime'] ?? '';
                      return tA.compareTo(tB);
                    });

                    if (allSlots.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد حجوزات مثبتة في $dayNameArabic',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'الطلبات الجديدة غير المقبولة تجدها في تبويب الطلبات الواردة',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              label: const Text('إضافة حجز يدوي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ModernAddBookingSheet(
                                    pitchName: widget.pitchName,
                                    durationMinutes: 60,
                                    defaultRate: 25000,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: allSlots.length,
                      itemBuilder: (context, idx) {
                        final slot = allSlots[idx];
                        final docId = slot['docId']?.toString() ?? '';
                        final teamOne = slot['teamOne'] ?? 'فريق كروي';
                        final teamTwo = (slot['teamTwo'] ?? '').toString().trim();
                        final phone = (slot['phone'] ?? '').toString().trim();
                        final startTime = slot['startTime'] ?? '';
                        final endTime = slot['endTime'] ?? '';
                        final status = slot['status'] ?? 'confirmed';
                        final price = (slot['price'] as num?)?.toDouble() ?? 25000.0;
                        final isRecurring = slot['isRecurringRule'] == true || status == 'recurring';

                        final statusColor = _getStatusColor(status);
                        final statusText = _getStatusArabicText(status);

                        return Card(
                          elevation: 1.5,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isRecurring ? Colors.purple.shade200 : const Color(0xFFE2E8F0),
                              width: isRecurring ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isRecurring ? Colors.purple.shade50 : const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isRecurring ? Icons.repeat_rounded : Icons.sports_soccer_rounded,
                                        color: isRecurring ? Colors.purple.shade800 : const Color(0xFF1B5E20),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            teamTwo.isNotEmpty && teamTwo != 'طرف ثانٍ غير محدد'
                                                ? '$teamOne ضد $teamTwo'
                                                : teamOne,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.schedule_rounded, size: 13, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$startTime - $endTime',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '${currencyFormatter.format(price)} د.ع',
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                    if (!isRecurring) ...[
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (val) {
                                          if (val == 'cancel') {
                                            _cancelBooking(docId, teamOne);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'cancel',
                                            child: Row(
                                              children: [
                                                Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                                                SizedBox(width: 8),
                                                Text('إلغاء الحجز', style: TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  children: [
                                    if (phone.isNotEmpty) ...[
                                      InkWell(
                                        onTap: () => _makePhoneCall(phone),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.phone_rounded, size: 14, color: Color(0xFF1B5E20)),
                                              SizedBox(width: 4),
                                              Text('اتصال', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _openWhatsApp(phone),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.chat_rounded, size: 14, color: Color(0xFF2E7D32)),
                                              SizedBox(width: 4),
                                              Text('واتساب', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    if (!isRecurring && status == 'confirmed')
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF1B5E20),
                                          side: const BorderSide(color: Color(0xFF1B5E20)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        icon: const Icon(Icons.check_rounded, size: 15),
                                        label: const Text('إكمال الحجز', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () => _completeBooking(docId),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
