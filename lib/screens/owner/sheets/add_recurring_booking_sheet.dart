import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/time_parser_util.dart';
import '../../../../constants.dart';

class ModernAddRecurringSheet extends StatefulWidget {
  final String pitchName;
  final int durationMinutes;
  final double defaultRate;

  const ModernAddRecurringSheet({
    super.key,
    required this.pitchName,
    required this.durationMinutes,
    required this.defaultRate,
  });

  @override
  State<ModernAddRecurringSheet> createState() => _ModernAddRecurringSheetState();
}

class _ModernAddRecurringSheetState extends State<ModernAddRecurringSheet> {
  final _teamCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '07');
  String _selectedDay = 'السبت';
  String? _selectedSlot;
  bool _isSaving = false;

  final daysOfWeek = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

  void _submit() async {
    final team = _teamCtrl.text.trim();
    if (team.isEmpty || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال اسم الفريق والوقت'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    final times = _selectedSlot!.split(' - ');
    final sTime = times[0];
    final eTime = times.length > 1 ? times[1] : '';

    try {
      final docRef = FirebaseFirestore.instance.collection('recurring_rules').doc();
      await docRef.set({
        'pitchName': widget.pitchName,
        'teamName': team,
        'phone': 'recurring_${_phoneCtrl.text.trim()}',
        'dayOfWeek': _selectedDay,
        'startTime': sTime,
        'endTime': eTime,
        'price': widget.defaultRate,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableSlots = buildPitchSlots(widget.durationMinutes);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.repeat_rounded, color: Colors.purple.shade800, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إضافة اشتراك دائم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        Text('يتم تكرار الحجز أسبوعياً بشكل تلقائي', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('بيانات المشترك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _teamCtrl,
                      decoration: InputDecoration(
                        labelText: 'اسم الفريق / الشخص',
                        prefixIcon: const Icon(Icons.groups_rounded, color: Colors.purple),
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
                    const Text('تحديد يوم ووقت الاشتراك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedDay,
                      decoration: InputDecoration(
                        labelText: 'اليوم (أسبوعياً)',
                        prefixIcon: const Icon(Icons.calendar_month_rounded, color: Colors.purple),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: daysOfWeek.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _selectedDay = v); },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('اختر وقت اللعب المعتاد:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableSlots.map((slot) {
                              final isSelected = _selectedSlot == slot;
                              return ChoiceChip(
                                label: Text(slot.split(' - ')[0], style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : const Color(0xFF0F172A), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                selected: isSelected,
                                selectedColor: Colors.purple.shade700,
                                backgroundColor: const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? Colors.purple.shade700 : const Color(0xFFE2E8F0))),
                                onSelected: (val) { if (val) setState(() => _selectedSlot = slot); },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isSaving ? null : _submit,
                        child: _isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('حفظ الاشتراك الدائم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
