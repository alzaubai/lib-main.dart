import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/time_parser_util.dart';
import '../../../services/booking_service.dart';

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
  final _teamOneCtrl = TextEditingController();
  final _teamTwoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedStartTime;
  bool _isSubmitting = false;

  // الفترة الزمنية المحددة: 0 = العصر، 1 = المساء، 2 = بعد منتصف الليل
  int _selectedPeriodIndex = 1;

  final Set<String> _bookedSlots = {};

  final List<String> _afternoonHours = [
    '03:00 م', '04:00 م', '05:00 م',
  ];

  final List<String> _eveningHours = [
    '06:00 م', '07:00 م', '08:00 م', '09:00 م', '10:00 م',
  ];

  final List<String> _lateNightHours = [
    '11:00 م', '12:00 ص', '01:00 ص', '02:00 ص', '03:00 ص',
  ];

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.userPhone;
    _loadUserDefaultTeam();
    _fetchBookedSlotsInBackground();
  }

  @override
  void dispose() {
    _teamOneCtrl.dispose();
    _teamTwoCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserDefaultTeam() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).get();
      if (doc.exists && mounted) {
        final d = doc.data();
        final team = (d?['teamName'] ?? '').toString();
        if (team.isNotEmpty && _teamOneCtrl.text.isEmpty) {
          setState(() => _teamOneCtrl.text = team);
        }
      }
    } catch (_) {}
  }

  // مزامنة خفيفة وسريعة في الخلفية بدون حجب الواجهة
  Future<void> _fetchBookedSlotsInBackground() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayNameArabic = TimeParserUtil.getArabicDayName(_selectedDate);

    try {
      final bookedSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('pitchName', isEqualTo: widget.pitchName)
          .where('date', isEqualTo: dateStr)
          .get();

      final recurringSnap = await FirebaseFirestore.instance
          .collection('recurring_rules')
          .where('pitchName', isEqualTo: widget.pitchName)
          .where('dayOfWeek', isEqualTo: dayNameArabic)
          .get();

      final Set<String> taken = {};

      for (var doc in bookedSnap.docs) {
        final d = doc.data();
        if (d['isDeleted'] == true) continue;
        if (d['status'] == 'rejected') continue;
        final t = (d['startTime'] ?? '').toString().trim();
        if (t.isNotEmpty) taken.add(t);
      }

      for (var doc in recurringSnap.docs) {
        final d = doc.data();
        final t = (d['startTime'] ?? '').toString().trim();
        if (t.isNotEmpty) taken.add(t);
      }

      if (mounted) {
        setState(() {
          _bookedSlots.clear();
          _bookedSlots.addAll(taken);
        });
      }
    } catch (_) {}
  }

  String _calculateEndTime(String start) {
    try {
      final parts = start.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = timeParts[1];
      String period = parts.length > 1 ? parts[1] : 'م';

      hour += 1;
      if (hour == 12) {
        period = (period == 'م') ? 'ص' : 'م';
      } else if (hour > 12) {
        hour = 1;
      }

      final formattedHour = hour.toString().padLeft(2, '0');
      return '$formattedHour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  List<String> _getCurrentPeriodHours() {
    if (_selectedPeriodIndex == 0) return _afternoonHours;
    if (_selectedPeriodIndex == 1) return _eveningHours;
    return _lateNightHours;
  }

  Future<void> _submitBooking() async {
    final teamOne = _teamOneCtrl.text.trim();
    final teamTwo = _teamTwoCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (teamOne.isEmpty) {
      _showToast('يرجى كتابة اسم فريقك');
      return;
    }
    if (phone.isEmpty) {
      _showToast('يرجى إدخال رقم الهاتف للتواصل');
      return;
    }
    if (_selectedStartTime == null) {
      _showToast('يرجى اختيار وقت الحجز');
      return;
    }

    setState(() => _isSubmitting = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final endTime = _calculateEndTime(_selectedStartTime!);

    final success = await BookingService.createBookingRequest(
      pitchName: widget.pitchName,
      teamOne: teamOne,
      teamTwo: teamTwo.isNotEmpty ? teamTwo : 'تحدي مفتوح',
      phone: phone,
      dateStr: dateStr,
      startTime: _selectedStartTime!,
      endTime: endTime,
      price: widget.hourlyRate,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('تم إرسال طلب الحجز لفريق ($teamOne) بنجاح')),
              ],
            ),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        _showToast('عذراً، هذا الموعد غير متاح حالياً');
        _fetchBookedSlotsInBackground();
      }
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final activeHours = _getCurrentPeriodHours();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 12),

            // رأس النافذة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حجز موعد: ${widget.pitchName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'سعر الساعة: ${currencyFormatter.format(widget.hourlyRate)} د.ع',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // أولاً: بيانات الفريقين ورقم الهاتف
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'بيانات الفريق والحجز',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _teamOneCtrl,
                            decoration: InputDecoration(
                              labelText: 'اسم فريقك (الطرف الأول)',
                              prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1B5E20)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _teamTwoCtrl,
                            decoration: InputDecoration(
                              labelText: 'اسم الفريق الخصم (اختياري)',
                              hintText: 'اكتب اسم الخصم أو اختر تحدي مفتوح',
                              prefixIcon: const Icon(Icons.shield_outlined, color: Colors.grey),
                              suffixIcon: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  setState(() => _teamTwoCtrl.text = 'تحدي مفتوح');
                                },
                                child: const Text(
                                  'تحدي مفتوح',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                ),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'رقم هاتف التواصل',
                              prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF1B5E20)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ثانياً: اختيار التاريخ
                    const Text(
                      'تاريخ المباراة:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 14,
                        itemBuilder: (context, idx) {
                          final day = DateTime.now().add(Duration(days: idx));
                          final isSelected = DateUtils.isSameDay(_selectedDate, day);
                          final dayName = TimeParserUtil.getArabicDayName(day);
                          final dayNum = DateFormat('d').format(day);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = day;
                                _selectedStartTime = null;
                              });
                              _fetchBookedSlotsInBackground();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 58,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(dayName, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(dayNum, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ثالثاً: فترات اليوم (العصر / المساء / بعد منتصف الليل)
                    const Text(
                      'فترة اللعب:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildPeriodTab(title: 'العصر', index: 0),
                          _buildPeriodTab(title: 'المساء', index: 1),
                          _buildPeriodTab(title: 'بعد منتصف الليل', index: 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // رابعاً: قائمة المواعيد الرأسية تحت الفترة المحددة
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeHours.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final hour = activeHours[idx];
                        final isBooked = _bookedSlots.contains(hour);
                        final isSelected = _selectedStartTime == hour;
                        final endHour = _calculateEndTime(hour);

                        return InkWell(
                          onTap: isBooked
                              ? null
                              : () {
                                  setState(() => _selectedStartTime = hour);
                                },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isBooked
                                  ? const Color(0xFFF1F5F9)
                                  : (isSelected ? const Color(0xFFE8F5E9) : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isBooked
                                    ? Colors.transparent
                                    : (isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0)),
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isBooked
                                        ? Colors.grey.shade200
                                        : (isSelected ? const Color(0xFF1B5E20) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isBooked ? Icons.lock_outline_rounded : Icons.schedule_rounded,
                                    size: 20,
                                    color: isBooked
                                        ? Colors.grey
                                        : (isSelected ? Colors.white : const Color(0xFF1B5E20)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'من $hour إلى $endHour',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isBooked ? Colors.grey : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'حصة تدريبية 60 دقيقة',
                                        style: TextStyle(fontSize: 11, color: isBooked ? Colors.grey.shade400 : Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isBooked
                                        ? Colors.red.shade50
                                        : (isSelected ? const Color(0xFF1B5E20) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isBooked ? 'محجوز' : (isSelected ? 'تم الاختيار' : 'متاح للحجز'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isBooked
                                          ? Colors.red.shade700
                                          : (isSelected ? Colors.white : const Color(0xFF1B5E20)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // زر التأكيد
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                        onPressed: _isSubmitting ? null : _submitBooking,
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'تأكيد وإرسال طلب الحجز',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab({required String title, required int index}) {
    final isSelected = _selectedPeriodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriodIndex = index;
            _selectedStartTime = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
