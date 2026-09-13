import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';

class CreateTournamentSheet extends StatefulWidget {
  final String pitchName;
  const CreateTournamentSheet({super.key, required this.pitchName});

  @override
  State<CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<CreateTournamentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _prizeController = TextEditingController(text: 'كأس البطولة + جوائز عينية');
  final _feeController = TextEditingController(text: '50000');
  
  int _maxTeams = 8;
  DateTime _startDate = DateTime.now().add(const Duration(days: 2));
  late final List<String> _slots;
  late String _defaultSlot;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _slots = buildPitchSlots(60);
    _defaultSlot = _slots.isNotEmpty ? _slots.first : '08:00 م - 09:00 م';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
                    width: 44,
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
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إطلاق بطولة رسمية جديدة 🏆', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                        Text('الملعب: ${widget.pitchName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'اسم أو عنوان البطولة',
                    hintText: 'مثال: بطولة رمضان الكبرى',
                    prefixIcon: const Icon(Icons.military_tech_rounded, color: Color(0xFF1B5E20)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'يرجى كتابة اسم البطولة' : null,
                ),
                const SizedBox(height: 14),

                // سعة الفرق (4، 8، 16)
                const Text('عدد الفرق المشاركة بالبطولة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [4, 8, 16].map((capacity) {
                    final isSel = _maxTeams == capacity;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              '$capacity فرق',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.black87),
                            ),
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFF1B5E20),
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (val) {
                            if (val) setState(() => _maxTeams = capacity);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _feeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'رسوم الاشتراك (د.ع)',
                          prefixIcon: const Icon(Icons.payments_rounded, color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _prizeController,
                        decoration: InputDecoration(
                          labelText: 'جوائز البطولة',
                          prefixIcon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // موعد الافتتاح وساعة الانطلاق
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF1B5E20)),
                          SizedBox(width: 6),
                          Text('تاريخ افتتاح البطولة وساعة الانطلاق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B5E20))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event_note, size: 14),
                              label: Text(DateFormat('yyyy-MM-dd').format(_startDate), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final p = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (p != null) setState(() => _startDate = p);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _defaultSlot,
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), border: OutlineInputBorder()),
                              items: _slots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 10)))).toList(),
                              onChanged: (v) => setState(() => _defaultSlot = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: _isCreating
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isCreating = true);
                              final feeVal = double.tryParse(_feeController.text.trim()) ?? 0.0;
                              final dateStr = DateFormat('yyyy-MM-dd').format(_startDate);

                              await FirebaseFirestore.instance.collection('tournaments').add({
                                'title': _titleController.text.trim(),
                                'pitchName': widget.pitchName,
                                'maxTeams': _maxTeams,
                                'entryFee': feeVal,
                                'prize': _prizeController.text.trim(),
                                'status': 'registering',
                                'startDate': dateStr,
                                'defaultSlot': _defaultSlot,
                                'teams': <String>[],
                                'registeredPlayers': <String, String>{},
                                'matches': [],
                                'champion': null,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم إطلاق البطولة بنجاح! 🏆'), backgroundColor: Color(0xFF1B5E20)),
                                );
                              }
                            }
                          },
                    child: _isCreating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('نشر البطولة وفتح التسجيل 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
