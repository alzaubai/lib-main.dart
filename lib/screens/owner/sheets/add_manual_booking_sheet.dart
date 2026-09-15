import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';

class ModernAddBookingSheet extends StatefulWidget {
  final String pitchName;
  final int durationMinutes;
  final double defaultRate;

  const ModernAddBookingSheet({
    super.key,
    required this.pitchName,
    required this.durationMinutes,
    required this.defaultRate,
  });

  @override
  State<ModernAddBookingSheet> createState() => _ModernAddBookingSheetState();
}

class _ModernAddBookingSheetState extends State<ModernAddBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _teamOneController = TextEditingController();
  final _teamTwoController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _priceController;

  DateTime _selectedDate = DateTime.now();
  late String _selectedSlot;
  late List<String> _slots;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _slots = buildPitchSlots(widget.durationMinutes);
    _selectedSlot = _slots.isNotEmpty ? _slots.first : '08:00 م - 09:00 م';
    _priceController = TextEditingController(text: '${widget.defaultRate.toInt()}');
  }

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
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 25, offset: Offset(0, -5)),
          ],
        ),
        padding: EdgeInsets.only(
          top: 14,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.add_task_rounded, color: Color(0xFF1B5E20), size: 26),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('تسجيل مباراة وحجز مباشر ⚽',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                        Text('الملعب: ${widget.pitchName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _teamOneController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'اسم الفريق الأول',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'يرجى كتابة اسم الفريق' : null,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('⚔️ VS ⚔️', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      TextFormField(
                        controller: _teamTwoController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'اسم الفريق الثاني (أو اكتب: تحدي)',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.sports_soccer, color: Colors.teal),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'يرجى كتابة اسم الفريق' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 15)),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF1B5E20), size: 20),
                        const SizedBox(width: 10),
                        Text('موعد المباراة: ${_getArabicDayName(_selectedDate)} (${DateFormat('yyyy/MM/dd').format(_selectedDate)})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        const Text('تغيير 📅', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('اختر فترة وتوقيت المباراة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _slots.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final slot = _slots[index];
                      final isSelected = _selectedSlot == slot;
                      return ChoiceChip(
                        label: Text(slot, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1B5E20),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val) setState(() => _selectedSlot = slot);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم هاتف الكابتن',
                          prefixIcon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'المبلغ (د.ع)',
                          prefixIcon: const Icon(Icons.payments_rounded, color: Colors.teal, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded),
                    label: const Text('تثبيت المباراة في الجدول ⚽', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => _isSaving = true);
                            final firestore = FirebaseFirestore.instance;
                            final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                            final dayNameArabic = _getArabicDayName(_selectedDate);
                            final times = _selectedSlot.split(' - ');
                            final sTime = times[0].trim();
                            final eTime = times.length > 1 ? times[1].trim() : '';

                            try {
                              // 1. فحص التعارض في الحجوزات العادية والمباريات القائمة (يشمل confirmed و upcoming)
                              final existingBookings = await firestore
                                  .collection('bookings')
                                  .where('pitchName', isEqualTo: widget.pitchName)
                                  .where('date', isEqualTo: dateStr)
                                  .where('status', whereIn: ['confirmed', 'upcoming', 'completed', 'tournament_match', 'pending'])
                                  .get();

                              for (var doc in existingBookings.docs) {
                                final d = doc.data();
                                if (d['isDeleted'] == true) continue;
                                if ((d['startTime'] ?? '').toString().trim() == sTime) {
                                  setState(() => _isSaving = false);
                                  if (!mounted) return;
                                  _showConflictDialog(
                                    context,
                                    conflictReason: 'يوجد حجز مسبق بالفعل في هذه الساعة!',
                                    details: 'محجوز لـ: ${d['teamOne']} ⚔️ ${d['teamTwo']}\nالحالة: ${_getStatusArabic(d['status'])}',
                                  );
                                  return;
                                }
                              }

                              // 2. فحص التعارض مع الاشتراكات الأسبوعية الدائمة
                              final recurringCheck = await firestore
                                  .collection('recurring_rules')
                                  .where('pitchName', isEqualTo: widget.pitchName)
                                  .where('dayOfWeek', isEqualTo: dayNameArabic)
                                  .get();

                              for (var doc in recurringCheck.docs) {
                                final d = doc.data();
                                final rStart = (d['startTime'] ?? '').toString().trim();
                                final rSlot = (d['timeSlot'] ?? '').toString().trim();

                                if (rStart == sTime || rSlot == _selectedSlot) {
                                  setState(() => _isSaving = false);
                                  if (!mounted) return;
                                  _showConflictDialog(
                                    context,
                                    conflictReason: 'هذه الساعة محجوزة باشتراك أسبوعي دائم!',
                                    details: 'محجوزة بشكل دائم كل يوم $dayNameArabic لفريق: (${d['teamName']})',
                                  );
                                  return;
                                }
                              }

                              // 3. التثبيت في حال عدم وجود أي تعارض مع ضبط الحالة إلى confirmed لينزل فوراً في الجدول
                              await firestore.collection('bookings').add({
                                'pitchName': widget.pitchName,
                                'teamOne': _teamOneController.text.trim(),
                                'teamTwo': _teamTwoController.text.trim(),
                                'date': dateStr,
                                'startTime': sTime,
                                'endTime': eTime,
                                'phone': _phoneController.text.trim(),
                                'price': double.tryParse(_priceController.text.trim()) ?? widget.defaultRate,
                                'status': 'confirmed',
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم تثبيت المباراة في الجدول بنجاح ✔️'),
                                    backgroundColor: Color(0xFF1B5E20),
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() => _isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConflictDialog(BuildContext context, {required String conflictReason, required String details}) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('تعارض في الموعد!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conflictReason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text(details, style: const TextStyle(color: Colors.black87, fontSize: 13)),
              const SizedBox(height: 12),
              const Text('يرجى اختيار ساعة أخرى أو يوم آخر لتفادي تداخل المباريات.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً، سأغير الوقت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusArabic(String? status) {
    switch (status) {
      case 'confirmed':
      case 'upcoming':
        return 'مباراة مؤكدة ⏳';
      case 'completed':
        return 'مباراة ملعوبة ومقبوضة ✔️';
      case 'tournament_match':
        return 'مباراة بطولة رسمية 🏆';
      case 'pending':
        return 'طلب قيد المراجعة ⏳';
      default:
        return 'محجوز';
    }
  }
}
