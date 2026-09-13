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
  final NumberFormat currencyFormatter = NumberFormat('#,###');
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
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Color(0xFFF7FAF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // مقبض النافذة
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            // رأس النافذة مع اختيار اليوم
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.stadium_rounded, color: Colors.amberAccent, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pitchName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'يوم $dayNameArabic • $dateStr',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B5E20),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: const Text('تغيير اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
              ),
            ),

            const SizedBox(height: 12),

            // قائمة الساعات
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
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                      }

                      final bookings = bookingSnapshot.data?.docs ?? [];
                      final recurringRules = recurringSnapshot.data?.docs ?? [];

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: _availableSlots.length,
                        itemBuilder: (context, idx) {
                          final slot = _availableSlots[idx];
                          final parts = slot.split(' - ');
                          final sTime = parts[0].trim();

                          final matchingBooking = bookings.cast<DocumentSnapshot?>().firstWhere(
                            (b) {
                              final d = b!.data() as Map<String, dynamic>;
                              return (d['startTime'] ?? '').toString().trim() == sTime;
                            },
                            orElse: () => null,
                          );

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

                          Color cardBg = Colors.white;
                          Color borderColor = Colors.grey.shade200;
                          Widget statusBadge;

                          if (isTournament) {
                            cardBg = Colors.amber.shade50;
                            borderColor = Colors.amber.shade300;
                            statusBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text('🏆 بطولة', style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                            );
                          } else if (isRecurringBooked) {
                            cardBg = Colors.purple.shade50;
                            borderColor = Colors.purple.shade200;
                            statusBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text('🔒 حجز دائم', style: TextStyle(color: Colors.purple.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                            );
                          } else if (isRegularBooked) {
                            cardBg = Colors.red.shade50;
                            borderColor = Colors.red.shade200;
                            statusBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text('❌ محجوز', style: TextStyle(color: Colors.red.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                            );
                          } else {
                            statusBadge = ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: () => _openModernBookingRequestSheet(context, dateStr, slot, dayNameArabic),
                              child: const Text('طلب حجز ⚡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            );
                          }

                          return Card(
                            elevation: isBooked ? 0 : 2,
                            shadowColor: Colors.black12,
                            color: cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor),
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 20,
                                    color: isBooked ? Colors.grey.shade600 : const Color(0xFF1B5E20),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slot,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isBooked ? Colors.black54 : Colors.black87,
                                          ),
                                        ),
                                        if (isTournament)
                                          Text(
                                            '${bData?['teamOne']} ⚔️ ${bData?['teamTwo']}',
                                            style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                                          )
                                        else if (isRecurringBooked)
                                          Text(
                                            'محجوز لـ: ${rData?['teamName']}',
                                            style: TextStyle(color: Colors.purple.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                                          )
                                        else if (!isBooked)
                                          Text(
                                            '${currencyFormatter.format(widget.hourlyRate)} د.ع / ساعة',
                                            style: const TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                  ),
                                  statusBadge,
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
      ),
    );
  }

  // الشيت العصري لتثبيت طلب الحجز
  void _openModernBookingRequestSheet(
    BuildContext context,
    String dateStr,
    String slot,
    String dayName,
  ) {
    final teamCtrl = TextEditingController();
    final opponentCtrl = TextEditingController();
    bool isOpenChallenge = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 14,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // كارت تذكرة المباراة
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                '${currencyFormatter.format(widget.hourlyRate)} د.ع',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Icon(Icons.event_available_rounded, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text('يوم $dayName ($dateStr)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Icon(Icons.schedule_rounded, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(slot, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Text('بيانات المباراة والفريقين:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),

                  // إدخال اسم الفريق
                  TextField(
                    controller: teamCtrl,
                    decoration: InputDecoration(
                      labelText: 'اسم فريقك (فريق الكابتن)',
                      hintText: 'مثال: فريق الفرسان',
                      prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // خيار نوع المباراة (تحدي مفتوح أو منافس محدد)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('⚔️ تحدي مفتوح (أي فريق)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          selected: isOpenChallenge,
                          selectedColor: const Color(0xFF1B5E20),
                          labelStyle: TextStyle(color: isOpenChallenge ? Colors.white : Colors.black87),
                          onSelected: (val) {
                            if (val) setSheetState(() => isOpenChallenge = true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('ضد فريق محدد 🛡️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          selected: !isOpenChallenge,
                          selectedColor: const Color(0xFF1B5E20),
                          labelStyle: TextStyle(color: !isOpenChallenge ? Colors.white : Colors.black87),
                          onSelected: (val) {
                            if (val) setSheetState(() => isOpenChallenge = false);
                          },
                        ),
                      ),
                    ],
                  ),

                  if (!isOpenChallenge) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: opponentCtrl,
                      decoration: InputDecoration(
                        labelText: 'اسم الفريق المنافس',
                        hintText: 'مثال: فريق النجوم',
                        prefixIcon: const Icon(Icons.sports_soccer, color: Colors.teal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // زر إرسال الطلب
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                      label: const Text('إرسال طلب الحجز للملعب 🚀', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final myTeam = teamCtrl.text.trim();
                              if (myTeam.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('يرجى كتابة اسم فريقك أولاً')),
                                );
                                return;
                              }

                              final opponentTeam = isOpenChallenge ? 'تحدي مفتوح ⚔️' : opponentCtrl.text.trim();
                              if (!isOpenChallenge && opponentTeam.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('يرجى كتابة اسم الفريق المنافس')),
                                );
                                return;
                              }

                              setSheetState(() => isSubmitting = true);
                              final times = slot.split(' - ');

                              try {
                                await _firestore.collection('bookings').add({
                                  'pitchName': widget.pitchName,
                                  'teamOne': myTeam,
                                  'teamTwo': opponentTeam,
                                  'date': dateStr,
                                  'startTime': times[0].trim(),
                                  'endTime': times.length > 1 ? times[1].trim() : '',
                                  'price': widget.hourlyRate,
                                  'phone': widget.userPhone,
                                  'status': 'pending',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                if (mounted) {
                                  Navigator.pop(sheetCtx);
                                  Navigator.pop(context); // إغلاق شيت المواعيد والعودة للاستكشاف
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم إرسال طلب الحجز بنجاح، ستجده في تبويب "حجوزاتي" ⚽'),
                                      backgroundColor: Color(0xFF1B5E20),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isSubmitting = false);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
