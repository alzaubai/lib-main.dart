import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import '../../../services/booking_service.dart';
import '../../../utils/time_parser_util.dart';
import '../widgets/slot_selection_grid.dart';

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
  final _teamTwoCtrl = TextEditingController(text: 'تحدي مفتوح');
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  bool _isLoading = false;
  late final List<String> _allSlots;

  @override
  void initState() {
    super.initState();
    _allSlots = buildPitchSlots(60);
    _loadCaptainTeamName();
  }

  Future<void> _loadCaptainTeamName() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).get();
      if (userDoc.exists && mounted) {
        final name = userDoc.data()?['name'] ?? 'فريق الكابتن';
        setState(() => _teamOneCtrl.text = 'فريق $name');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayNameArabic = TimeParserUtil.getArabicDayName(_selectedDate);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(top: 14, left: 18, right: 18, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20), size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('طلب حجز: ${widget.pitchName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(controller: _teamOneCtrl, decoration: const InputDecoration(labelText: 'اسم فريقك', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _teamTwoCtrl, decoration: const InputDecoration(labelText: 'الفريق المنافس (أو اكتب تحدي مفتوح)', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF7FAF7), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 8),
                    Text('$dayNameArabic ($dateStr)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1B5E20), side: const BorderSide(color: Color(0xFF1B5E20))),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                      label: const Text('تغيير التاريخ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (p != null) setState(() { _selectedDate = p; _selectedSlot = null; });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SlotSelectionGrid(
                pitchName: widget.pitchName,
                dateStr: dateStr,
                dayNameArabic: dayNameArabic,
                allSlots: _allSlots,
                selectedSlot: _selectedSlot,
                onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_selectedSlot == null || _isLoading)
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          final parts = _selectedSlot!.split(' - ');

                          await BookingService.createBookingRequest(
                            pitchName: widget.pitchName,
                            teamOne: _teamOneCtrl.text.trim().isEmpty ? 'فريق كابتن' : _teamOneCtrl.text.trim(),
                            teamTwo: _teamTwoCtrl.text.trim().isEmpty ? 'تحدي مفتوح' : _teamTwoCtrl.text.trim(),
                            phone: widget.userPhone,
                            dateStr: dateStr,
                            startTime: parts[0].trim(),
                            endTime: parts[1].trim(),
                            price: widget.hourlyRate,
                          );

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إرسال طلب الحجز بنجاح! سيصلك إشعار فور رد صاحب الملعب ✔️'),
                                backgroundColor: Color(0xFF1B5E20),
                              ),
                            );
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('إرسال طلب الحجز 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
