import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';

class PlayerBookingSheet extends StatefulWidget {
  final String pitchName;
  final double hourlyRate;
  final String userPhone;

  const PlayerBookingSheet({
    super.key,
    required this.pitchName,
    required this.hourlyRate,
    required this.userPhone,
  });

  @override
  State<PlayerBookingSheet> createState() => _PlayerBookingSheetState();
}

class _PlayerBookingSheetState extends State<PlayerBookingSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  final List<String> _availableSlots = buildPitchSlots(60);

  String _getArabicDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayNameArabic = _getArabicDayName(_selectedDate);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'جدول مواعيد: ${widget.pitchName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                    ),
                    Text(
                      'يوم $dayNameArabic ($dateStr)',
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87, elevation: 0),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('تغيير اليوم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (p != null) setState(() => _selectedDate = p);
                  },
                ),
              ],
            ),
            const Divider(height: 20),

            // دمج قراءة حجوزات اليوم + قواعد التكرار الأسبوعي لنفس اليوم
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('bookings')
                    .where('pitchName', isEqualTo: widget.pitchName)
                    .where('date', isEqualTo: dateStr)
                    .where('status', whereIn: ['pending', 'upcoming', 'tournament_match', 'completed'])
                    .snapshots(),
                builder: (context, bookingSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('recurring_rules')
                        .where('pitchName', isEqualTo: widget.pitchName)
                        .where('dayOfWeek', isEqualTo: dayNameArabic)
                        .snapshots(),
                    builder: (context, recurringSnapshot) {
                      if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final bookings = bookingSnapshot.data?.docs ?? [];
                      final recurringRules = recurringSnapshot.data?.docs ?? [];

                      return ListView.builder(
                        itemCount: _availableSlots.length,
                        itemBuilder: (context, idx) {
                          final slot = _availableSlots[idx];
                          final parts = slot.split(' - ');
                          final sTime = parts[0].trim();

                          // فحص حجز عادي أو بطولة
                          final matchingBooking = bookings.cast<DocumentSnapshot?>().firstWhere(
                            (b) {
                              final d = b!.data() as Map<String, dynamic>;
                              final bookStartTime = (d['startTime'] ?? '').toString().trim();
                              return bookStartTime == sTime;
                            },
                            orElse: () => null,
                          );

                          // فحص حجز أسبوعي دائم
                          final matchingRecurring = recurringRules.cast<DocumentSnapshot?>().firstWhere(
                            (r) {
                              final d = r!.data() as Map<String, dynamic>;
                              final rSlot = (d['timeSlot'] ?? '').toString().trim();
                              final rStart = (d['startTime'] ?? '').toString().trim();
                              return rSlot == slot || rStart == sTime;
                            },
                            orElse: () => null,
                          );

                          final isRegularBooked = matchingBooking != null;
                          final isRecurringBooked = matchingRecurring != null;
                          final isBooked = isRegularBooked || isRecurringBooked;

                          Map<String, dynamic>? bData = isRegularBooked ? matchingBooking.data() as Map<String, dynamic> : null;
                          Map<String, dynamic>? rData = isRecurringBooked ? matchingRecurring.data() as Map<String, dynamic> : null;

                          final isTournament = bData?['status'] == 'tournament_match';

                          String subtitleText = 'متاح للحجز المباشر ✔️';
                          Color textColor = Colors.green.shade900;
                          IconData leadingIcon = Icons.check_circle;
                          Color themeColor = Colors.green;

                          if (isTournament) {
                            subtitleText = '🏆 بطولة رسمية: ${bData?['teamOne']} ⚔️ ${bData?['teamTwo']}';
                            textColor = Colors.amber.shade900;
                            leadingIcon = Icons.emoji_events;
                            themeColor = Colors.amber;
                          } else if (isRecurringBooked) {
                            subtitleText = '🔒 حجز أسبوعي دائم: ${rData?['teamName']} ⚔️ ${rData?['teamTwo'] ?? ''}';
                            textColor = Colors.purple.shade900;
                            leadingIcon = Icons.repeat_rounded;
                            themeColor = Colors.purple;
                          } else if (isRegularBooked) {
                            subtitleText = 'هذا الموعد محجوز مسبقاً ❌';
                            textColor = Colors.red.shade900;
                            leadingIcon = Icons.cancel;
                            themeColor = Colors.red;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isBooked ? (isRecurringBooked ? Colors.purple.shade50 : Colors.red.shade50) : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isBooked ? (isRecurringBooked ? Colors.purple.shade200 : Colors.red.shade200) : Colors.green.shade300,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(leadingIcon, color: themeColor),
                              title: Text(slot, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                              subtitle: Text(subtitleText, style: TextStyle(fontSize: 11, fontWeight: isBooked ? FontWeight.bold : FontWeight.normal, color: textColor)),
                              trailing: isBooked
                                  ? Chip(
                                      label: Text(
                                        isRecurringBooked ? 'دائم' : (isTournament ? 'بطولة' : 'محجوز'),
                                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: isRecurringBooked ? Colors.purple.shade800 : (isTournament ? Colors.amber.shade800 : Colors.red),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(horizontal: 12)),
                                      onPressed: () => _openRequestDialog(context, dateStr, slot),
                                      child: const Text('احجز الآن', style: TextStyle(color: Colors.white, fontSize: 12)),
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
      ),
    );
  }

  void _openRequestDialog(BuildContext context, String date, String slot) {
    final teamCtrl = TextEditingController();
    final times = slot.split(' - ');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد طلب الحجز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الملعب: ${widget.pitchName}'),
              Text('الموعد: $date ($slot)'),
              const SizedBox(height: 10),
              TextField(
                controller: teamCtrl,
                decoration: const InputDecoration(labelText: 'اسم فريقك', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final tName = teamCtrl.text.trim();
                if (tName.isNotEmpty) {
                  await _firestore.collection('bookings').add({
                    'pitchName': widget.pitchName,
                    'teamOne': tName,
                    'teamTwo': 'تحدي',
                    'date': date,
                    'startTime': times[0].trim(),
                    'endTime': times.length > 1 ? times[1].trim() : '',
                    'price': widget.hourlyRate,
                    'phone': widget.userPhone,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال طلب الحجز للملعب بنجاح!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
