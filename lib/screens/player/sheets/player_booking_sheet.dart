import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../constants.dart';
import '../../../../utils/time_parser_util.dart';
import '../../../../services/slot_lock_service.dart';

class PlayerBookingSheet extends StatefulWidget {
  final String pitchName;
  final String pitchPhone;
  final double hourlyRate;
  final String userPhone;

  const PlayerBookingSheet({
    super.key,
    required this.pitchName,
    required this.pitchPhone,
    required this.hourlyRate,
    required this.userPhone,
  });

  @override
  State<PlayerBookingSheet> createState() => _PlayerBookingSheetState();
}

class _PlayerBookingSheetState extends State<PlayerBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _teamController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  late List<String> _slots;
  
  bool _isSaving = false;
  bool _isLocking = false;

  @override
  void initState() {
    super.initState();
    _slots = buildPitchSlots(60); 
  }

  @override
  void dispose() {
    _releaseCurrentLock(); 
    super.dispose();
  }

  // تحرير الوقت في حال اللاعب سد الواجهة بدون ما يكمل حجز
  Future<void> _releaseCurrentLock() async {
    if (_selectedSlot != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await SlotLockService.releaseSlot(
        pitchName: widget.pitchName,
        date: dateStr,
        slot: _selectedSlot!,
        userPhone: widget.userPhone,
      );
    }
  }

  // معالجة اختيار الوقت وقفل الوقت حصرياً له
  Future<void> _handleSlotSelection(String slot) async {
    if (_selectedSlot == slot) return;

    setState(() => _isLocking = true);
    
    await _releaseCurrentLock();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final locked = await SlotLockService.lockSlot(
      pitchName: widget.pitchName,
      date: dateStr,
      slot: slot,
      userPhone: widget.userPhone,
    );

    if (mounted) {
      setState(() {
        _isLocking = false;
        if (locked) {
          _selectedSlot = slot;
        } else {
          _selectedSlot = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('عذراً، هذا الوقت قيد الحجز حالياً من قبل كابتن آخر. يرجى اختيار وقت آخر.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  void _makePhoneCall() async {
    final cleanPhone = widget.pitchPhone.replaceAll(RegExp(r'\s+|-'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openWhatsApp() async {
    String cleanPhone = widget.pitchPhone.replaceAll(RegExp(r'\s+|-'), '');
    if (cleanPhone.startsWith('07')) cleanPhone = '964${cleanPhone.substring(1)}';
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 25, offset: Offset(0, -5))],
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
                      child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20), size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('حجز موعد مباراة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                          Text('الملعب: ${widget.pitchName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF1B5E20)),
                        label: const Text('اتصال بالمالك', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _makePhoneCall,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8F5E9),
                          foregroundColor: const Color(0xFF1B5E20),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('واتساب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _openWhatsApp,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _releaseCurrentLock(); 
                        _selectedSlot = null;
                      });
                    }
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
                        const Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'التاريخ: ${TimeParserUtil.getArabicDayName(_selectedDate)} (${DateFormat('yyyy-MM-dd').format(_selectedDate)})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        const Text('تغيير 📅', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Text('اختر وقت المباراة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                    const Spacer(),
                    if (_isLocking)
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20))),
                  ],
                ),
                const SizedBox(height: 10),
                
                // إضافة StreamBuilder لجلب الحجوزات والأوقات المقفولة بشكل مباشر
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('pitchName', isEqualTo: widget.pitchName)
                      .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(_selectedDate))
                      .snapshots(),
                  builder: (context, bookingSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('slot_locks')
                          .where('pitchName', isEqualTo: widget.pitchName)
                          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(_selectedDate))
                          .snapshots(),
                      builder: (context, lockSnap) {
                        
                        // 1. تجميع الأوقات المحجوزة
                        final bookedSlots = <String>{};
                        for (var doc in bookingSnap.data?.docs ?? []) {
                          final d = doc.data() as Map<String, dynamic>;
                          if (d['status'] != 'rejected' && d['isDeleted'] != true) {
                            bookedSlots.add('${d['startTime']} - ${d['endTime']}');
                          }
                        }

                        // 2. تجميع الأوقات المقفولة من قبل مستخدمين آخرين
                        final lockedSlots = <String>{};
                        final now = DateTime.now();
                        for (var doc in lockSnap.data?.docs ?? []) {
                          final d = doc.data() as Map<String, dynamic>;
                          final expiresAt = (d['expiresAt'] as Timestamp?)?.toDate();
                          if (expiresAt != null && expiresAt.isAfter(now)) {
                            lockedSlots.add(d['timeSlot'] ?? '');
                          }
                        }

                        return SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _slots.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final slot = _slots[index];
                              final isPassed = TimeParserUtil.isSlotTimePassed(_selectedDate, slot);
                              final isBooked = bookedSlots.contains(slot);
                              final isLockedByOther = lockedSlots.contains(slot) && _selectedSlot != slot;
                              final isSelected = _selectedSlot == slot;
                              
                              final bool isDisabled = isPassed || isBooked || isLockedByOther;

                              String label = slot;
                              if (isPassed) label += ' (مضى)';
                              else if (isBooked) label += ' (محجوز)';
                              else if (isLockedByOther) label += ' (قيد المراجعة)';

                              return ChoiceChip(
                                label: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDisabled ? Colors.grey.shade400 : (isSelected ? Colors.white : Colors.black87),
                                  ),
                                ),
                                selected: isSelected && !isDisabled,
                                selectedColor: const Color(0xFF1B5E20),
                                backgroundColor: isDisabled ? Colors.grey.shade200 : Colors.grey.shade100,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                onSelected: (isDisabled || _isLocking) ? null : (val) {
                                  if (val) _handleSlotSelection(slot);
                                },
                              );
                            },
                          ),
                        );
                      }
                    );
                  }
                ),
                
                const SizedBox(height: 16),

                TextFormField(
                  controller: _teamController,
                  decoration: InputDecoration(
                    labelText: 'اسم فريقك',
                    prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'يرجى كتابة اسم الفريق' : null,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded),
                    label: const Text('إرسال طلب الحجز ⚽', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: _isSaving ? null : () async {
                      if (!_formKey.currentState!.validate()) return;
                      if (_selectedSlot == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار وقت المباراة المتاح')));
                        return;
                      }

                      setState(() => _isSaving = true);
                      try {
                        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                        final sTime = _selectedSlot!.split(' - ')[0].trim();
                        final eTime = _selectedSlot!.split(' - ').length > 1 ? _selectedSlot!.split(' - ')[1].trim() : '';
                        
                        await FirebaseFirestore.instance.collection('bookings').add({
                          'pitchName': widget.pitchName,
                          'teamOne': _teamController.text.trim(),
                          'teamTwo': 'طرف ثانٍ غير محدد',
                          'phone': widget.userPhone,
                          'date': dateStr,
                          'startTime': sTime,
                          'endTime': eTime,
                          'price': widget.hourlyRate,
                          'status': 'pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        await _releaseCurrentLock();

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إرسال الطلب بنجاح إلى إدارة الملعب.'),
                              backgroundColor: Color(0xFF1B5E20),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => _isSaving = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحجز')));
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
}
