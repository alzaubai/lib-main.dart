import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import '../../../services/booking_service.dart';
import '../../../services/slot_lock_service.dart';
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

  @override
  void dispose() {
    _releaseActiveLock();
    _teamOneCtrl.dispose();
    _teamTwoCtrl.dispose();
    super.dispose();
  }

  void _releaseActiveLock() {
    if (_selectedSlot != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      SlotLockService.releaseLock(
        pitchName: widget.pitchName,
        dateStr: dateStr,
        timeSlot: _selectedSlot!,
        userPhone: widget.userPhone,
      );
    }
  }

  Future<void> _handleSlotSelection(String slot) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // تحرير القفل القديم إن وجد
    if (_selectedSlot != null && _selectedSlot != slot) {
      await SlotLockService.releaseLock(
        pitchName: widget.pitchName,
        dateStr: dateStr,
        timeSlot: _selectedSlot!,
        userPhone: widget.userPhone,
      );
    }

    // محاولة حجز قفل مؤقت للساعة المحددة لمدة 5 دقائق
    final locked = await SlotLockService.acquireTemporaryLock(
      pitchName: widget.pitchName,
      dateStr: dateStr,
      timeSlot: slot,
      userPhone: widget.userPhone,
    );

    if (locked) {
      setState(() => _selectedSlot = slot);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذه الساعة قيد التحديد حالياً من كابتن آخر، يرجى الانتظار أو اختيار توقيت آخر'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
  }

  Future<void> _loadCaptainTeamName() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        final name = data?['name'] ?? 'الكابتن';
        final team = data?['teamName'] ?? '';
        setState(() {
          _teamOneCtrl.text = (team.toString().isNotEmpty) ? team : 'فريق $name';
        });
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
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.stadium_rounded, color: Color(0xFF1B5E20), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pitchName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'أجرة الساعة: ${widget.hourlyRate.toInt()} دينار عراقي',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF1B5E20)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('موعد المباراة', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              Text(
                                '$dayNameArabic، $dateStr',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1B5E20),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: const Text('تغيير التاريخ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final p = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (p != null) {
                                _releaseActiveLock();
                                setState(() {
                                  _selectedDate = p;
                                  _selectedSlot = null;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _teamOneCtrl,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'اسم فريقك',
                              labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _teamTwoCtrl,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'المنافس (اختياري)',
                              labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'تحديد الساعة',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    SlotSelectionGrid(
                      pitchName: widget.pitchName,
                      dateStr: dateStr,
                      dayNameArabic: dayNameArabic,
                      allSlots: _allSlots,
                      selectedSlot: _selectedSlot,
                      onSlotSelected: _handleSlotSelection,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedSlot != null ? 'الساعة المحددة' : 'يرجى اختيار وقت',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Text(
                          _selectedSlot ?? 'لم يتم التحديد',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedSlot != null ? const Color(0xFF1B5E20) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: (_selectedSlot == null || _isLoading)
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            final parts = _selectedSlot!.split(' - ');

                            final success = await BookingService.createBookingRequest(
                              pitchName: widget.pitchName,
                              teamOne: _teamOneCtrl.text.trim().isEmpty ? 'فريق الكابتن' : _teamOneCtrl.text.trim(),
                              teamTwo: _teamTwoCtrl.text.trim().isEmpty ? 'تحدي مفتوح' : _teamTwoCtrl.text.trim(),
                              phone: widget.userPhone,
                              dateStr: dateStr,
                              startTime: parts[0].trim(),
                              endTime: parts[1].trim(),
                              price: widget.hourlyRate,
                            );

                            if (mounted) {
                              setState(() => _isLoading = false);
                              if (success) {
                                // تحرير القفل بعد اعتماد الطلب رسمياً
                                _releaseActiveLock();
                                _selectedSlot = null;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم إرسال طلب الحجز بنجاح، بانتظار تأكيد الملعب'),
                                    backgroundColor: Color(0xFF1B5E20),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('نعتذر منك، تم حجز هذه الساعة للتو من قبل فريق آخر'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'تأكيد الطلب',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
