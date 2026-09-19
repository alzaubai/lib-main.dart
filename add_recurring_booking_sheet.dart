import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  
  List<String> _availableSlots = [];
  bool _isLoadingSlots = true;

  final daysOfWeek = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

  @override
  void initState() {
    super.initState();
    _fetchPitchHours();
  }

  Future<void> _fetchPitchHours() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('pitches').doc(widget.pitchName).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final openTime = data['openTime'] ?? '16:00';
        final closeTime = data['closeTime'] ?? '02:00';
        _generateSlots(openTime, closeTime, widget.durationMinutes);
      } else {
        _generateSlots('16:00', '02:00', widget.durationMinutes);
      }
    } catch (e) {
      _generateSlots('16:00', '02:00', widget.durationMinutes);
    }
  }

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
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
                      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.repeat_rounded, color: Colors.purple.shade800, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إضافة اشتراك دائم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                          Text('حجز يتكرر أسبوعياً بشكل تلقائي', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
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
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _teamCtrl,
                              decoration: InputDecoration(
                                labelText: 'اسم المشترك',
                                prefixIcon: const Icon(Icons.groups_rounded, size: 18, color: Colors.purple),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'الهاتف',
                                prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: InputDecoration(
                          labelText: 'يوم اللعب (كل أسبوع)',
                          prefixIcon: const Icon(Icons.calendar_month_rounded, color: Colors.purple),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: daysOfWeek.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _selectedDay = v); },
                      ),
                      const SizedBox(height: 20),
                      
                      const Text('اختر وقت اللعب المعتاد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
                      const SizedBox(height: 10),
                      
                      _isLoadingSlots
                          ? Center(child: CircularProgressIndicator(color: Colors.purple.shade700))
                          : _availableSlots.isEmpty
                              ? const Center(child: Text('لا توجد أوقات متاحة', style: TextStyle(color: Colors.red)))
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 2.1,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: _availableSlots.length,
                                  itemBuilder: (context, index) {
                                    final slot = _availableSlots[index];
                                    final isSelected = _selectedSlot == slot;
                                    final times = slot.split(' - ');
                                    final sTime = times[0];
                                    final eTime = times.length > 1 ? times[1] : '';

                                    return InkWell(
                                      onTap: () => setState(() => _selectedSlot = slot),
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.purple.shade700 : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected ? Colors.purple.shade700 : const Color(0xFFE2E8F0),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [BoxShadow(color: Colors.purple.shade700.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]
                                              : [],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(sTime, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? Colors.white : const Color(0xFF0F172A))),
                                                if (eTime.isNotEmpty)
                                                  Text('إلى $eTime', style: TextStyle(fontSize: 9.5, color: isSelected ? Colors.white70 : Colors.grey)),
                                              ],
                                            ),
                                            if (isSelected)
                                              const Positioned(top: 4, right: 4, child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 12)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
