import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';

class OwnerScheduleTab extends StatefulWidget {
  final String pitchName;
  const OwnerScheduleTab({super.key, required this.pitchName});

  @override
  State<OwnerScheduleTab> createState() => _OwnerScheduleTabState();
}

class _OwnerScheduleTabState extends State<OwnerScheduleTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat currencyFormatter = NumberFormat('#,###');

  int _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 9999;
    try {
      final clean = timeStr.trim();
      final isPM = clean.contains('م') || clean.toLowerCase().contains('pm');
      
      final parts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return (hour * 60) + minute;
    } catch (_) {
      return 9999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('pitchName', isEqualTo: widget.pitchName)
          .where('status', whereIn: ['upcoming', 'completed', 'tournament_match'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];

        // حساب الإيرادات من جميع الحجوزات حتى لو تم إخفاؤها من الجدول
        double actualRevenueReceived = 0.0;
        double expectedRevenueUpcoming = 0.0;

        for (var doc in allDocs) {
          final d = doc.data() as Map<String, dynamic>;
          final price = (d['price'] as num?)?.toDouble() ?? 0.0;
          final status = d['status'];

          if (status == 'completed') {
            actualRevenueReceived += price;
          } else if (status == 'upcoming' && d['isDeleted'] != true) {
            expectedRevenueUpcoming += price;
          }
        }

        // استبعاد الحجوزات المخفية من قائمة العرض بالجدول
        var visibleDocs = allDocs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return d['isDeleted'] != true;
        }).toList();

        // الترتيب الزمني الدقيق
        visibleDocs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          final dateA = (dataA['date'] ?? '').toString();
          final dateB = (dataB['date'] ?? '').toString();

          int dateComp = dateA.compareTo(dateB);
          if (dateComp != 0) {
            return dateComp;
          }

          final timeA = (dataA['startTime'] ?? '').toString();
          final timeB = (dataB['startTime'] ?? '').toString();

          final minA = _parseTimeToMinutes(timeA);
          final minB = _parseTimeToMinutes(timeB);

          return minA.compareTo(minB);
        });

        return Column(
          children: [
            // بطاقة الإيرادات العلوية
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 16),
                              SizedBox(width: 4),
                              Text('الوارد الفعلي المقبوض', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${currencyFormatter.format(actualRevenueReceived)} د.ع',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.hourglass_top_rounded, color: Colors.lightGreenAccent, size: 16),
                              SizedBox(width: 4),
                              Text('المبلغ المؤكد القادم', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${currencyFormatter.format(expectedRevenueUpcoming)} د.ع',
                            style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // قائمة المباريات المرتبة تصاعدياً
            Expanded(
              child: visibleDocs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_rounded, size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا توجد مباريات مسجلة حالياً بالجدول',
                              style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: visibleDocs.length,
                      itemBuilder: (context, index) {
                        final doc = visibleDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'];
                        final isDone = status == 'completed';
                        final isTour = status == 'tournament_match';
                        final phone = data['phone'] ?? '';

                        return Card(
                          elevation: 3,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isTour
                                  ? Colors.amber.shade400
                                  : (isDone ? Colors.green.shade300 : Colors.grey.shade300),
                              width: isTour ? 1.8 : 1.2,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade700),
                                        const SizedBox(width: 6),
                                        Text('${data['date']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isTour
                                            ? Colors.amber.shade50
                                            : (isDone ? Colors.green.shade50 : Colors.blue.shade50),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isTour
                                              ? Colors.amber.shade700
                                              : (isDone ? Colors.green : Colors.blue.shade300),
                                        ),
                                      ),
                                      child: Text(
                                        isTour
                                            ? '🏆 مباراة بطولة رسمية'
                                            : (isDone ? 'مكتملة ومقبوضة ✔️' : 'مؤكدة (بانتظار اللعب) ⏳'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isTour
                                              ? Colors.amber.shade900
                                              : (isDone ? Colors.green.shade900 : Colors.blue.shade900),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isTour ? Colors.amber.shade50.withOpacity(0.5) : const Color(0xFFF4F7F4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${data['teamOne']}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isTour ? Colors.amber.shade900 : const Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text('⚔️', style: TextStyle(fontSize: 18)),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${data['teamTwo']}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isTour ? Colors.amber.shade900 : const Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text('${data['startTime']} إلى ${data['endTime']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const Spacer(),
                                    Text(
                                      isTour
                                          ? 'محجوزة بالبطولة'
                                          : '${currencyFormatter.format(data['price'] ?? 0)} د.ع',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isTour ? Colors.amber.shade900 : Colors.teal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    if (phone.toString().isNotEmpty) ...[
                                      IconButton(
                                        icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green),
                                        tooltip: 'اتصال',
                                        onPressed: () => launchCallDirect(phone),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                                        tooltip: 'واتساب',
                                        onPressed: () => launchWhatsAppDirect(phone),
                                      ),
                                    ],
                                    const Spacer(),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                        side: BorderSide(color: Colors.red.shade300),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                                      label: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: () => _confirmDeleteMatch(context, doc.reference, isDone),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isDone && !isTour)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1B5E20),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                                        label: const Text('إنهاء وتثبيت', style: TextStyle(fontWeight: FontWeight.bold)),
                                        onPressed: () => _confirmMatchCompletion(context, doc.reference, data),
                                      )
                                    else if (isDone)
                                      const Row(
                                        children: [
                                          Icon(Icons.verified_rounded, color: Colors.green, size: 18),
                                          SizedBox(width: 4),
                                          Text('تم القبض', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _confirmMatchCompletion(BuildContext context, DocumentReference docRef, Map<String, dynamic> bData) {
    bool markTrusted = true;
    final teamPhone = bData['phone'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text('تأكيد إنهاء المباراة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تنبيه: بمجرد التأكيد لن تتمكن من التراجع، وسيتم تسجيل المبلغ نهائياً في الوارد الفعلي.',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('المباراة: ${bData['teamOne']} ⚔️ ${bData['teamTwo']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('المبلغ المقبوض: ${bData['price']} د.ع', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: markTrusted,
                  title: Text('فريق ملتزم بالحضور والمواعيد (${bData['teamOne']})', style: const TextStyle(fontSize: 12)),
                  subtitle: const Text('يمنح الفريق شارة "فريق موثوق 🏅"', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  activeColor: const Color(0xFF1B5E20),
                  onChanged: (val) => setDlgState(() => markTrusted = val ?? true),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                onPressed: () async {
                  await docRef.update({
                    'status': 'completed',
                    'teamTrustedRated': markTrusted,
                  });

                  if (teamPhone.toString().isNotEmpty) {
                    await _firestore.collection('players').doc(teamPhone).set({
                      'isTrustedTeam': markTrusted,
                    }, SetOptions(merge: true));
                  }

                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('نعم، تأكيد وتثبيت الوارد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMatch(BuildContext context, DocumentReference docRef, bool isDone) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(isDone ? 'إخفاء المباراة من الجدول؟' : 'حذف هذا الحجز؟'),
          content: Text(
            isDone
                ? 'المباراة مكتملة وتم قبض مبلغها مسبقاً. سيتم إخفاؤها من الجدول لتنظيف القائمة، مع الاحتفاظ الكامل بالمبلغ ضمن الوارد الفعلي المقبوض والتحليلات المالية.'
                : 'هل أنت متأكد من حذف هذه المباراة من الجدول؟ لن يتم احتسابها في الحسابات لأنها لم تلعب بعد.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (isDone) {
                  // إذا كانت مقبوضة: إخفاء فقط من الجدول وحفظ المال في الوارد
                  await docRef.update({'isDeleted': true});
                } else {
                  // إذا لم تلعب أصلاً: حذف نهائي
                  await docRef.delete();
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: Text(isDone ? 'نعم، إخفاء من الجدول' : 'نعم، حذف الحجز',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
