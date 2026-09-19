import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import '../../../utils/time_parser_util.dart';
import '../../../services/challenge_service.dart';

class CreateChallengeSheet extends StatefulWidget {
  final String userPhone;

  const CreateChallengeSheet({super.key, required this.userPhone});

  @override
  State<CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<CreateChallengeSheet> {
  final _teamCtrl = TextEditingController();

  List<Map<String, dynamic>> _pitches = [];
  Map<String, dynamic>? _selectedPitch;
  bool _isLoadingPitches = true;

  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  List<String> _slots = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPitches();
    _loadDefaultTeamName();
  }

  Future<void> _loadDefaultTeamName() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).get();
      if (doc.exists && mounted) {
        final teamName = (doc.data()?['teamName'] ?? '').toString();
        if (teamName.isNotEmpty) _teamCtrl.text = teamName;
      }
    } catch (_) {}
  }

  Future<void> _loadPitches() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('pitches').get();
      final list = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['name'] = data['name'] ?? d.id;
        return data;
      }).toList();
      if (mounted) {
        setState(() {
          _pitches = list;
          _isLoadingPitches = false;
          if (list.isNotEmpty) _selectPitch(list.first);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPitches = false);
    }
  }

  void _selectPitch(Map<String, dynamic> pitch) {
    setState(() {
      _selectedPitch = pitch;
      _selectedSlot = null;
      _slots = buildPitchSlotsForRange(
        openTime: (pitch['openTime'] ?? '04:00 م').toString(),
        closeTime: (pitch['closeTime'] ?? '03:00 ص').toString(),
        durationMinutes: 60,
      );
    });
  }

  double get _pricePerTeam {
    final rate = (_selectedPitch?['hourlyRate'] as num?)?.toDouble() ?? 25000.0;
    return rate / 2;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

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
            mainAxisSize: MainAxisSize.min,
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
                      decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.sports_kabaddi_rounded, color: Colors.deepOrange.shade700, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('نشر تحدي مفتوح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                          Text('أي فريق يكدر يشوف تحديك ويقبله', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
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
                      const SizedBox(height: 8),
                      TextField(
                        controller: _teamCtrl,
                        decoration: InputDecoration(
                          labelText: 'اسم فريقك',
                          prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1B5E20)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('اختر الملعب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                      const SizedBox(height: 8),
                      _isLoadingPitches
                          ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Color(0xFF1B5E20))))
                          : _pitches.isEmpty
                              ? const Text('لا توجد ملاعب مسجلة حالياً', style: TextStyle(color: Colors.grey))
                              : DropdownButtonFormField<String>(
                                  value: _selectedPitch?['name'],
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(Icons.stadium_rounded, color: Color(0xFF1B5E20)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: _pitches
                                      .map((p) => DropdownMenuItem(value: p['name'].toString(), child: Text(p['name'].toString(), style: const TextStyle(fontSize: 13))))
                                      .toList(),
                                  onChanged: (val) {
                                    final p = _pitches.firstWhere((e) => e['name'] == val);
                                    _selectPitch(p);
                                  },
                                ),
                      const SizedBox(height: 14),

                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                          );
                          if (picked != null) setState(() { _selectedDate = picked; _selectedSlot = null; });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
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

                      const Text('اختر وقت المباراة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                      const SizedBox(height: 10),
                      _slots.isEmpty
                          ? const Text('اختر ملعباً أولاً لعرض الأوقات المتاحة', style: TextStyle(color: Colors.grey, fontSize: 12))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _slots.map((slot) {
                                final isPassed = TimeParserUtil.isSlotTimePassed(_selectedDate, slot);
                                final isSelected = _selectedSlot == slot;
                                return ChoiceChip(
                                  label: Text(slot, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPassed ? Colors.grey.shade400 : (isSelected ? Colors.white : Colors.black87))),
                                  selected: isSelected,
                                  selectedColor: Colors.deepOrange.shade700,
                                  backgroundColor: isPassed ? Colors.grey.shade200 : Colors.grey.shade100,
                                  onSelected: isPassed ? null : (val) => setState(() => _selectedSlot = val ? slot : null),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepOrange.shade100)),
                        child: Row(
                          children: [
                            Icon(Icons.payments_rounded, color: Colors.deepOrange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'المبلغ على كل فريق: ${currencyFormatter.format(_pricePerTeam)} د.ع (نص سعر ساعة الملعب)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('نشر التحدي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _submit() async {
    final team = _teamCtrl.text.trim();
    if (team.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى كتابة اسم فريقك'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedPitch == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار الملعب'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار وقت المباراة'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final times = _selectedSlot!.split(' - ');
    final sTime = times[0].trim();
    final eTime = times.length > 1 ? times[1].trim() : '';

    final ok = await ChallengeService.createChallenge(
      pitchName: _selectedPitch!['name'].toString(),
      creatorPhone: widget.userPhone,
      creatorTeamName: team,
      dateStr: dateStr,
      startTime: sTime,
      endTime: eTime,
      pricePerTeam: _pricePerTeam,
      governorate: (_selectedPitch?['governorate'] ?? 'بغداد').toString(),
    );

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر التحدي بنجاح ⚽'), backgroundColor: Color(0xFF1B5E20)),
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء نشر التحدي'), backgroundColor: Colors.red));
      }
    }
  }
}
