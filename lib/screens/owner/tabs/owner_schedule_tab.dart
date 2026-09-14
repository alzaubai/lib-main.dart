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
  DateTime _selectedDate = DateTime.now();

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
      child: Column(
        children: [
          // شريط اختيار وتنقل الأيام
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(14, (index) {
                        final d = DateTime.now().add(Duration(days: index));
                        final isSelected = DateFormat('yyyy-MM-dd').format(d) == dateStr;
                        final dayName = index == 0 ? 'اليوم' : (index == 1 ? 'غداً' : _getArabicDayName(d));

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(dayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                                Text(DateFormat('MM/dd').format(d), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF1B5E20),
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (val) {
                              if (val) setState(() => _selectedDate = d);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)),
                  tooltip: 'اختر يوماً من التقويم',
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),

          // عرض الحجوزات المؤكدة فقط لهذا اليوم (استبعاد المعلق pending والملغي rejected)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                    if (bookingSnap.connectionState == ConnectionState.waiting ||
                        recurringSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                    }

                    // تصفية: استبعاد المعلق pending والمرفوض rejected والمحذوف
                    final regularDocs = (bookingSnap.data?.docs ?? []).where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final status = data['status'];
                      return data['isDeleted'] != true &&
                          status != 'pending' &&
                          status != 'rejected';
                    }).map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      data['docId'] = d.id;
                      data['isRecurring'] = false;
                      return data;
                    }).toList();

                    // الحجوزات الدائمة لنفس اليوم
                    final recurringDocs = (recurringSnap.data?.docs ?? []).map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      data['docId'] = d.id;
                      data['isRecurring'] = true;
                      data['status'] = 'recurring';
                      return data;
                    }).toList();

                    final allMatches = [...regularDocs, ...recurringDocs];

                    allMatches.sort((a, b) {
                      final aTime = (a['startTime'] ?? '').toString();
                      final bTime = (b['startTime'] ?? '').toString();
                      return aTime.compareTo(bTime);
                    });

                    if (allMatches.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              'لا توجد مباريات مثبتة في يوم $dayNameArabic ($dateStr)',
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text('ساعات هذا اليوم شاغرة بالكامل أمام الحجز', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: allMatches.length,
                      itemBuilder: (context, index) {
                        final item = allMatches[index];
                        final bool isRecurring = item['isRecurring'] == true;
                        final status = item['status'] ?? 'upcoming';

                        Color cardColor = Colors.white;
                        Color borderColor = Colors.grey.shade300;
                        String statusLabel = 'مباراة مؤكدة ⏳';

                        if (isRecurring) {
                          cardColor = const Color(0xFFFAF7FC);
                          borderColor = Colors.purple.shade200;
                          statusLabel = 'اشتراك أسبوعي دائم 🔄';
                        } else if (status == 'completed') {
                          cardColor = Colors.grey.shade50;
                          borderColor = Colors.blue.shade200;
                          statusLabel = 'مكتملة ومقبوضة ✔️';
                        } else if (status == 'tournament_match') {
                          cardColor = Colors.amber.shade50;
                          borderColor = Colors.amber.shade300;
                          statusLabel = 'مباراة بطولة رسمية 🏆';
                        }

                        return Card(
                          color: cardColor,
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: borderColor, width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isRecurring
                                          ? Icons.repeat_rounded
                                          : (status == 'tournament_match' ? Icons.emoji_events : Icons.sports_soccer),
                                      color: isRecurring
                                          ? Colors.purple.shade800
                                          : (status == 'tournament_match' ? Colors.amber.shade800 : const Color(0xFF1B5E20)),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${item['teamOne'] ?? item['teamName'] ?? 'فريق'} ⚔️ ${item['teamTwo'] ?? 'تحدي'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isRecurring ? Colors.purple.shade900 : const Color(0xFF1B5E20),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isRecurring ? Colors.purple.shade50 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isRecurring ? Colors.purple.shade800 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'الساعة: ${item['startTime']} - ${item['endTime']}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${item['price'] ?? 0} د.ع',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if ((item['phone'] ?? '').toString().isNotEmpty)
                                      Text(
                                        'كابتن: ${item['phone']}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    const Spacer(),
                                    if (!isRecurring && status == 'upcoming')
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1B5E20),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                                        label: const Text('إنهاء وقبض ✔️', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection('bookings')
                                              .doc(item['docId'])
                                              .update({'status': 'completed'});
                                        },
                                      ),
                                    if (!isRecurring && status == 'completed')
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        tooltip: 'إخفاء من الجدول',
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection('bookings')
                                              .doc(item['docId'])
                                              .update({'isDeleted': true});
                                        },
                                      ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }
}
