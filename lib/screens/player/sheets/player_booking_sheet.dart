import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';

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
        setState(() {
          _teamOneCtrl.text = 'فريق $name';
        });
      }
    } catch (_) {}
  }

  String _getArabicDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayNameArabic = _getArabicDayName(_selectedDate);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 14,
          left: 18,
          right: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
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
                    child: Text(
                      'طلب حجز: ${widget.pitchName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _teamOneCtrl,
                decoration: const InputDecoration(labelText: 'اسم فريقك', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _teamTwoCtrl,
                decoration: const InputDecoration(labelText: 'الفريق المنافس (أو اكتب تحدي مفتوح)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),

              // شريط التاريخ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 8),
                    Text('$dayNameArabic ($dateStr)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B5E20),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                      ),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                      label: const Text('تغيير التاريخ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (p != null) {
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

              // دليل الألوان الإرشادي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statusLegendItem('متاحة تماماً', Colors.green.shade700, const Color(0xFFE8F5E9)),
                  _statusLegendItem('عليها طلب سابق ⏳', Colors.orange.shade800, Colors.orange.shade50),
                  _statusLegendItem('مثبتة ومقفلة 🔒', Colors.grey.shade600, Colors.grey.shade200),
                ],
              ),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('pitchName', isEqualTo: widget.pitchName)
                    .where('date', isEqualTo: dateStr)
                    .snapshots(),
                builder: (context, bookingSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('recurring_rules')
                        .where('pitchName', isEqualTo: widget.pitchName)
                        .where('dayOfWeek', isEqualTo: dayNameArabic)
                        .snapshots(),
                    builder: (context, recurringSnap) {
                      final confirmedBookedSlots = <String>{};
                      final pendingSlotsCount = <String, int>{};

                      // فحص الحجوزات
                      if (bookingSnap.hasData) {
                        for (var doc in bookingSnap.data!.docs) {
                          final d = doc.data() as Map<String, dynamic>;
                          final status = d['status'];
                          final slot = '${d['startTime']} - ${d['endTime']}';

                          if (status == 'upcoming' || status == 'completed' || status == 'tournament_match') {
                            confirmedBookedSlots.add(slot);
                          } else if (status == 'pending') {
                            pendingSlotsCount[slot] = (pendingSlotsCount[slot] ?? 0) + 1;
                          }
                        }
                      }

                      // فحص الحجوزات الدائمة
                      if (recurringSnap.hasData) {
                        for (var doc in recurringSnap.data!.docs) {
                          final d = doc.data() as Map<String, dynamic>;
                          final slot = '${d['startTime']} - ${d['endTime']}';
                          confirmedBookedSlots.add(slot);
                        }
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _allSlots.length,
                        itemBuilder: (context, idx) {
                          final slot = _allSlots[idx];
                          final isConfirmed = confirmedBookedSlots.contains(slot);
                          final pendingCount = pendingSlotsCount[slot] ?? 0;
                          final hasPending = !isConfirmed && pendingCount > 0;
                          final isSelected = _selectedSlot == slot;

                          Color bgColor;
                          Color borderColor;
                          Color textColor;
                          Widget badgeWidget;

                          if (isConfirmed) {
                            bgColor = Colors.grey.shade200;
                            borderColor = Colors.grey.shade300;
                            textColor = Colors.grey.shade500;
                            badgeWidget = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('محجوزة رسمياً', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              ],
                            );
                          } else if (isSelected) {
                            bgColor = const Color(0xFF1B5E20);
                            borderColor = const Color(0xFF1B5E20);
                            textColor = Colors.white;
                            badgeWidget = const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('تم الاختيار', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            );
                          } else if (hasPending) {
                            bgColor = Colors.orange.shade50;
                            borderColor = Colors.orange.shade300;
                            textColor = Colors.orange.shade900;
                            badgeWidget = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 12, color: Colors.orange.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  pendingCount == 1 ? 'طلب قيد الانتظار' : '$pendingCount طلبات بالانتظار',
                                  style: TextStyle(fontSize: 9, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          } else {
                            bgColor = Colors.green.shade50;
                            borderColor = Colors.green.shade300;
                            textColor = const Color(0xFF1B5E20);
                            badgeWidget = const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, size: 12, color: Color(0xFF1B5E20)),
                                SizedBox(width: 4),
                                Text('متاحة بالكامل', style: TextStyle(fontSize: 9, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                              ],
                            );
                          }

                          return InkWell(
                            onTap: isConfirmed
                                ? null
                                : () {
                                    setState(() {
                                      _selectedSlot = isSelected ? null : slot;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    slot,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  badgeWidget,
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 18),

              // رسالة توضيحية في حال اختيار ساعة عليها طلبات معلقة
              if (_selectedSlot != null) ...[
                Builder(
                  builder: (context) {
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'يحق لك إرسال طلبك حتى لو كانت الساعة مطلوبة؛ الاختيار النهائي لتأكيد الفريق يعود لصاحب الملعب.',
                              style: TextStyle(fontSize: 11, color: Colors.blueGrey, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],

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

                          await FirebaseFirestore.instance.collection('bookings').add({
                            'pitchName': widget.pitchName,
                            'teamOne': _teamOneCtrl.text.trim().isEmpty ? 'فريق كابتن' : _teamOneCtrl.text.trim(),
                            'teamTwo': _teamTwoCtrl.text.trim().isEmpty ? 'تحدي مفتوح' : _teamTwoCtrl.text.trim(),
                            'phone': widget.userPhone,
                            'date': dateStr,
                            'startTime': parts[0].trim(),
                            'endTime': parts[1].trim(),
                            'price': widget.hourlyRate,
                            'status': 'pending',
                            'seenByPlayer': true,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

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

  Widget _statusLegendItem(String label, Color dotColor, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dotColor)),
        ],
      ),
    );
  }
}
