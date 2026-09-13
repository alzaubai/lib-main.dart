import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants.dart';

class AddRecurringBookingSheet extends StatefulWidget {
  final String pitchName;
  final double defaultRate;

  const AddRecurringBookingSheet({
    super.key,
    required this.pitchName,
    required this.defaultRate,
  });

  @override
  State<AddRecurringBookingSheet> createState() => _AddRecurringBookingSheetState();
}

class _AddRecurringBookingSheetState extends State<AddRecurringBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _teamOneController = TextEditingController();
  final _teamTwoController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _priceController;

  final List<String> _daysOfWeek = [
    'الجمعة',
    'الخميس',
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
  ];

  final List<String> _selectedDays = ['الجمعة'];
  late final List<String> _slots;
  late String _selectedSlot;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _slots = buildPitchSlots(60);
    _selectedSlot = _slots.isNotEmpty ? _slots.first : '08:00 م - 09:00 م';
    _priceController = TextEditingController(text: '${widget.defaultRate.toInt()}');
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
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Icon(Icons.repeat_rounded, color: Colors.purple.shade800, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تثبيت حجز أسبوعي دائم (اشتراك) 🔄',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                        Text('الملعب: ${widget.pitchName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // بطاقة الفريقين
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _teamOneController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'اسم الفريق الأساسي (صاحب الحجز)',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.shield_outlined, color: Colors.purple.shade800),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'يرجى كتابة اسم الفريق' : null,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('⚔️ ضد ⚔️', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple)),
                      ),
                      TextFormField(
                        controller: _teamTwoController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'الفريق المنافس (أو اكتب: تحدي أسبوعي)',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.sports_soccer, color: Colors.teal),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'يرجى كتابة الفريق الثاني أو كلمة تحدي' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // اختيار أيام التكرار
                const Text('أيام الحجز الأسبوعي (يمكنك اختيار أكثر من يوم):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _daysOfWeek.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      selectedColor: Colors.purple.shade800,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            if (_selectedDays.length > 1) {
                              _selectedDays.remove(day);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // فترة المباراة
                const Text('وقت وفترة المباراة الأسبوعية:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
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
                        selectedColor: Colors.purple.shade800,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val) setState(() => _selectedSlot = slot);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // الهاتف والمبلغ
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم هاتف الكابتن',
                          prefixIcon: const Icon(Icons.phone_rounded, color: Colors.purple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'يرجى كتابة رقم الهاتف' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'سعر الحجز (د.ع)',
                          prefixIcon: const Icon(Icons.payments_rounded, color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade800,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded),
                    label: const Text('تثبيت الاشتراك الأسبوعي الدائم 🔒', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isSaving = true);
                              final priceVal = double.tryParse(_priceController.text.trim()) ?? widget.defaultRate;
                              final times = _selectedSlot.split(' - ');
                              final sTime = times[0].trim();
                              final eTime = times.length > 1 ? times[1].trim() : '';

                              // إضافة الحجز لكل يوم تم اختياره
                              for (var day in _selectedDays) {
                                await FirebaseFirestore.instance.collection('recurring_rules').add({
                                  'pitchName': widget.pitchName,
                                  'dayOfWeek': day,
                                  'timeSlot': _selectedSlot,
                                  'startTime': sTime,
                                  'endTime': eTime,
                                  'teamName': _teamOneController.text.trim(),
                                  'teamTwo': _teamTwoController.text.trim(),
                                  'phone': _phoneController.text.trim(),
                                  'price': priceVal,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                              }

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تثبيت الحجز الأسبوعي الدائم بنجاح 🔄'), backgroundColor: Colors.purple),
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
}
