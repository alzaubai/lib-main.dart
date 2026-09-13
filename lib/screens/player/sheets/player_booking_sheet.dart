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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  final List<String> _availableSlots = buildPitchSlots(60);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'جدول مواعيد: ${widget.pitchName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const Text(
                      'الأخضر متاح للحجز / الأحمر محجوز أو بطولة',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (p != null) setState(() => _selectedDate = p);
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('bookings')
                    .where('pitchName', isEqualTo: widget.pitchName)
                    .where('date', isEqualTo: dateStr)
                    .where('status', whereIn: ['pending', 'upcoming', 'tournament_match', 'completed'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookings = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    itemCount: _availableSlots.length,
                    itemBuilder: (context, idx) {
                      final slot = _availableSlots[idx];
                      final parts = slot.split(' - ');
                      final sTime = parts[0].trim();

                      final matchingBooking = bookings.cast<DocumentSnapshot?>().firstWhere(
                        (b) {
                          final d = b!.data() as Map<String, dynamic>;
                          final bookStartTime = (d['startTime'] ?? '').toString().trim();
                          return bookStartTime == sTime;
                        },
                        orElse: () => null,
                      );

                      final isBooked = matchingBooking != null;
                      Map<String, dynamic>? bData = isBooked ? matchingBooking.data() as Map<String, dynamic> : null;
                      final isTournament = bData?['status'] == 'tournament_match';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isBooked ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isBooked ? Colors.red.shade200 : Colors.green.shade300),
                        ),
                        child: ListTile(
                          leading: Icon(
                            isTournament ? Icons.emoji_events : (isBooked ? Icons.cancel : Icons.check_circle),
                            color: isBooked ? Colors.red : Colors.green,
                          ),
                          title: Text(
                            slot,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isBooked ? Colors.red.shade900 : Colors.green.shade900,
                            ),
                          ),
                          subtitle: isTournament
                              ? Text(
                                  '🏆 بطولة رسمية: ${bData?['teamOne']} ⚔️ ${bData?['teamTwo']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                )
                              : (isBooked
                                  ? const Text('هذا الموعد محجوز مسبقاً ❌', style: TextStyle(fontSize: 11, color: Colors.red))
                                  : const Text('متاح للحجز المباشر ✔️', style: TextStyle(fontSize: 11, color: Colors.green))),
                          trailing: isBooked
                              ? const Chip(
                                  label: Text('محجوز', style: TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: Colors.red,
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  onPressed: () => _openRequestDialog(context, dateStr, slot),
                                  child: const Text('احجز الآن', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRequestDialog(BuildContext context, String date, String slot) {
    final teamCtrl = TextEditingController();
    final times = slot.split(' - ');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد طلب الحجز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الملعب: ${widget.pitchName}'),
              Text('الموعد: $date ($slot)'),
              const SizedBox(height: 10),
              TextField(
                controller: teamCtrl,
                decoration: const InputDecoration(labelText: 'اسم فريقك', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final tName = teamCtrl.text.trim();
                if (tName.isNotEmpty) {
                  await _firestore.collection('bookings').add({
                    'pitchName': widget.pitchName,
                    'teamOne': tName,
                    'teamTwo': 'تحدي',
                    'date': date,
                    'startTime': times[0].trim(),
                    'endTime': times.length > 1 ? times[1].trim() : '',
                    'price': widget.hourlyRate,
                    'phone': widget.userPhone,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال طلب الحجز للملعب بنجاح!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
