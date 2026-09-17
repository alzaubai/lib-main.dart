import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateTournamentSheet extends StatefulWidget {
  final String pitchName;

  const CreateTournamentSheet({
    super.key,
    required this.pitchName,
  });

  @override
  State<CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<CreateTournamentSheet> {
  final _titleCtrl = TextEditingController();
  final _prizeCtrl = TextEditingController();
  final _feeCtrl = TextEditingController(text: '25000');
  final _customCapacityCtrl = TextEditingController();
  
  String _selectedSize = '4 فرق';
  bool _isCustomSize = false;
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 16, minute: 0);
  
  bool _isSaving = false;

  final sizes = ['4 فرق', '8 فرق', '16 فريق', 'مخصص'];

  void _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى كتابة اسم البطولة'), backgroundColor: Colors.red));
      return;
    }

    int capacity = 4;
    if (_isCustomSize) {
      capacity = int.tryParse(_customCapacityCtrl.text.trim()) ?? 0;
      if (capacity < 2) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال عدد فرق صحيح (على الأقل فريقين)'), backgroundColor: Colors.red));
        return;
      }
    } else {
      capacity = int.parse(_selectedSize.split(' ')[0]);
    }

    setState(() => _isSaving = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('tournaments').doc();
      
      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      
      await docRef.set({
        'pitchName': widget.pitchName,
        'title': title,
        'prize': _prizeCtrl.text.trim(), // جائزة البطولة
        'description': '', // تركناه فارغ للتوافق مع القديم، واعتمدنا حقل الجائزة
        'entryFee': double.tryParse(_feeCtrl.text.trim()) ?? 0,
        'capacity': capacity,
        'startDate': startDateStr, // تاريخ الافتتاح
        'startTime': startTimeStr, // ساعة الانطلاق
        'status': 'registration',
        'teams': [],
        'registeredPlayers': {},
        'matches': [],
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
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // تاخذ حجمها المناسب فقط
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
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.emoji_events_rounded, color: Colors.orange.shade900, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إنشاء بطولة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                          Text('نظم بطولة تنافسية في ملعبك', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('معلومات البطولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'اسم البطولة (مثال: كأس الصيف)',
                          prefixIcon: const Icon(Icons.tour_rounded, color: Colors.orange),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _prizeCtrl,
                        decoration: InputDecoration(
                          labelText: 'جائزة البطولة (مثال: كأس وميداليات)',
                          prefixIcon: const Icon(Icons.card_giftcard_rounded, color: Colors.orange),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      const Text('موعد الانطلاق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                                if (picked != null) setState(() => _startDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('تاريخ الافتتاح', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.orange),
                                        const SizedBox(width: 6),
                                        Text(DateFormat('yyyy-MM-dd').format(_startDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: _startTime);
                                if (picked != null) setState(() => _startTime = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ساعة الانطلاق', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 16, color: Colors.orange),
                                        const SizedBox(width: 6),
                                        Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text('إعدادات الاشتراك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedSize,
                                  decoration: InputDecoration(
                                    labelText: 'عدد الفرق',
                                    prefixIcon: const Icon(Icons.groups_rounded, color: Colors.orange),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  ),
                                  items: sizes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                                  onChanged: (v) { 
                                    if (v != null) {
                                      setState(() {
                                        _selectedSize = v;
                                        _isCustomSize = v == 'مخصص';
                                      });
                                    } 
                                  },
                                ),
                                if (_isCustomSize) ...[
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _customCapacityCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'اكتب العدد',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _feeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'رسوم المباراة',
                                suffixText: 'د.ع',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('الفرق ستسجل عبر التطبيق مجاناً، ويتم دفع رسوم المباراة عند الحضور للعب.', style: TextStyle(fontSize: 11.5, color: Colors.orange.shade900))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('إطلاق البطولة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
