import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  final _teamCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '07');
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  bool _isSaving = false;
  
  List<String> _availableSlots = [];
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _fetchPitchHours();
  }

  // دالة لجلب أوقات فتح وإغلاق الملعب الحقيقية من قاعدة البيانات
  Future<void> _fetchPitchHours() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('pitches').doc(widget.pitchName).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final openTime = data['openTime'] ?? '16:00';
        final closeTime = data['closeTime'] ?? '02:00';
        _generateSlots(openTime, closeTime, widget.durationMinutes);
      } else {
        _generateSlots('16:00', '02:00', widget.durationMinutes); // وقت افتراضي
      }
    } catch (e) {
      _generateSlots('16:00', '02:00', widget.durationMinutes);
    }
  }

  // دالة لتوليد الأوقات من وقت الفتح إلى الإغلاق
  void _generateSlots(String openStr, String closeStr, int duration) {
    List<String> slots = [];
    try {
      DateTime now = DateTime.now();
      
      DateTime parseTime(String t) {
        t = t.trim().replaceAll('ص', 'AM').replaceAll('م', 'PM');
        if (t.toUpperCase().contains('AM') || t.toUpperCase().contains('PM')) {
          final p = DateFormat('hh:mm a').parse(t);
          return DateTime(now.year, now.month, now.day, p.hour, p.minute);
        } else {
          final parts = t.split(':');
          return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
        }
      }

      DateTime start = parseTime(openStr);
      DateTime end = parseTime(closeStr);

      // إذا كان الإغلاق بعد منتصف الليل (مثلاً يفتح 4 عصراً ويغلق 2 فجراً)
      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        end = end.add(const Duration(days: 1));
      }

      DateTime current = start;
      while (current.isBefore(end)) {
        DateTime next = current.add(Duration(minutes: duration));
        if (next.isAfter(end)) break;
        
        String sTime = DateFormat('HH:mm').format(current);
        String eTime = DateFormat('HH:mm').format(next);
        slots.add('$sTime - $eTime');
        current = next;
      }
    } catch (e) {
      slots = ['16:00 - 17:00', '17:00 - 18:00', '18:00 - 19:00', '19:00 - 20:00'];
    }

    if (mounted) {
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
    }
  }

  void _submit() async {
    final team = _teamCtrl.text.trim();
    if (team.isEmpty || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الفريق وتحديد الوقت'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final times = _selectedSlot!.split(' - ');
    final sTime = times[0];
    final eTime = times.length > 1 ? times[1] : '';

    try {
      final snap = await FirebaseFirestore.instance.collection('bookings')
          .where('pitchName', isEqualTo: widget.pitchName)
          .where('date', isEqualTo: dateStr)
          .where('startTime', isEqualTo: sTime)
          .where('isDeleted', isNotEqualTo: true)
          .get();

      final isBooked = snap.docs.any((d) => d.data()['status'] != 'cancelled' && d.data()['status'] != 'rejected');
      if (isBooked) {
        setState(() => _isSaving = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الوقت تم حجزه للتو'), backgroundColor: Colors.red));
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('bookings').doc();
      await docRef.set({
        'pitchName': widget.pitchName,
        'teamOne': team,
        'teamTwo': 'مباراة ودية',
        'phone': 'manual_${_phoneCtrl.text.trim()}',
        'date': dateStr,
        'startTime': sTime,
        'endTime': eTime,
        'price': widget.defaultRate,
        'status': 'confirmed',
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      // هذا السطر هو اللي يرفع النافذة لمن ينفتح الكيبورد!
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9), // حد أقصى للارتفاع
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // النافذة تاخذ حجم المحتوى فقط
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF1B5E20), size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إضافة حجز يدوي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                          Text('تثبيت وقت محدد لفريق معين بالجدول', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 16),
              Flexible( // Flexible يسمح بالمساحة للمحتوى ويدعم الـ Scroll
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('بيانات الفريق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _teamCtrl,
                        decoration: InputDecoration(
                          labelText: 'اسم الفريق',
                          prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1B5E20)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف (اختياري)',
                          prefixIcon: const Icon(Icons.phone_rounded, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('تحديد الموعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (picked != null) setState(() { _selectedDate = picked; _selectedSlot = null; });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)),
                              const SizedBox(width: 10),
                              Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              const Icon(Icons.edit_rounded, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('اختر الوقت المتاح:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      
                      // هنا ترتيب الأوقات بشكل سطور عمودية واحد جوة الثاني
                      _isLoadingSlots
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                          : _availableSlots.isEmpty
                              ? const Center(child: Text('لا توجد أوقات متاحة', style: TextStyle(color: Colors.red)))
                              : Column(
                                  children: _availableSlots.map((slot) {
                                    final isSelected = _selectedSlot == slot;
                                    return InkWell(
                                      onTap: () => setState(() => _selectedSlot = slot),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.schedule_rounded, color: isSelected ? Colors.white : Colors.grey, size: 20),
                                            const SizedBox(width: 12),
                                            Text(
                                              slot,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const Spacer(),
                                            if (isSelected)
                                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22)
                                            else
                                              const Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('تثبيت الحجز بالجدول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
