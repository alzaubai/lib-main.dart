import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  final String pitchName;
  const OwnerAnalyticsScreen({super.key, required this.pitchName});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  String _selectedFilter = 'كل الأوقات'; 
  final currencyFormatter = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: Text('تحليلات وأداء ${widget.pitchName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          actions: [
            DropdownButton<String>(
              dropdownColor: const Color(0xFF1B5E20),
              value: _selectedFilter,
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_alt, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'كل الأوقات', child: Text('كل الأوقات')),
                DropdownMenuItem(value: 'هذا الشهر', child: Text('هذا الشهر')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedFilter = val);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data?.docs ?? [];
            final now = DateTime.now();
            final currentMonthPrefix = DateFormat('yyyy-MM').format(now);

            final filteredDocs = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              if (_selectedFilter == 'هذا الشهر') {
                final dateStr = data['date']?.toString() ?? '';
                return dateStr.startsWith(currentMonthPrefix);
              }
              return true;
            }).toList();

            double totalRevenue = 0.0;
            int completedMatches = 0;
            int upcomingMatches = 0;

            final Map<String, int> slotPopularity = {};
            final Map<String, Map<String, dynamic>> teamStats = {};
            final Map<String, int> dayOfWeekStats = {
              'الجمعة': 0, 'السبت': 0, 'الأحد': 0, 'الإثنين': 0, 'الثلاثاء': 0, 'الأربعاء': 0, 'الخميس': 0,
            };

            // دالة مساعدة لتسجيل إحصائيات الفريق
            void recordTeamStat(String teamName, double price, String matchStatus) {
              if (teamName.isNotEmpty && teamName != 'بانتظار الخصم') {
                if (!teamStats.containsKey(teamName)) {
                  teamStats[teamName] = {'count': 0, 'spent': 0.0};
                }
                teamStats[teamName]!['count'] = (teamStats[teamName]!['count'] as int) + 1;
                if (matchStatus == 'completed') {
                  // تقسيم المبلغ على 2 بافتراض أن الفريقين يتشاركان الدفع
                  teamStats[teamName]!['spent'] = (teamStats[teamName]!['spent'] as double) + (price / 2);
                }
              }
            }

            for (var d in filteredDocs) {
              final data = d.data() as Map<String, dynamic>;
              final status = data['status'];
              final price = (data['price'] as num?)?.toDouble() ?? 0.0;
              final slot = '${data['startTime']} - ${data['endTime']}';
              final team1 = data['teamOne']?.toString().trim() ?? '';
              final team2 = data['teamTwo']?.toString().trim() ?? ''; // إضافة قراءة الفريق الثاني
              final dateStr = data['date']?.toString() ?? '';

              if (status == 'completed') {
                totalRevenue += price;
                completedMatches++;
              } else if (status == 'upcoming') {
                upcomingMatches++;
              }

              if (slot.isNotEmpty && slot != ' - ') {
                slotPopularity[slot] = (slotPopularity[slot] ?? 0) + 1;
              }

              // تسجيل إحصائيات كلا الفريقين بدلاً من فريق واحد
              recordTeamStat(team1, price, status);
              recordTeamStat(team2, price, status);

              try {
                if (dateStr.isNotEmpty) {
                  final dt = DateTime.parse(dateStr);
                  final arabicDay = _getArabicDay(dt.weekday);
                  if (dayOfWeekStats.containsKey(arabicDay)) {
                    dayOfWeekStats[arabicDay] = dayOfWeekStats[arabicDay]! + 1;
                  }
                }
              } catch (_) {}
            }

            final sortedSlots = slotPopularity.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            final sortedTeams = teamStats.entries.toList()..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... [نفس واجهة كروت الإحصائيات وبناء الأعمدة البيانية تم الحفاظ عليها هنا]
                  // تم اقتصاص واجهة الرسوم البيانية لتوضيح التعديل البرمجي الأهم (يمكنك لصق كود الواجهة القديم هنا فهو سليم تماماً)
                  const Text('أفضل الفرق والزبائن الأكثر حجزاً 🏅', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: sortedTeams.isEmpty
                        ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('لا توجد فرق مسجلة بعد', style: TextStyle(color: Colors.grey))))
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedTeams.take(5).length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final item = sortedTeams[idx];
                              final teamName = item.key;
                              final count = item.value['count'] as int;
                              final spent = item.value['spent'] as double;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: idx == 0 ? Colors.amber : (idx == 1 ? Colors.grey.shade400 : Colors.brown.shade300),
                                  foregroundColor: Colors.white,
                                  child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                title: Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('عدد الحجوزات: $count مباراة'),
                                trailing: Text('${currencyFormatter.format(spent)} د.ع', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 13)),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getArabicDay(int weekday) {
    switch (weekday) {
      case DateTime.friday: return 'الجمعة';
      case DateTime.saturday: return 'السبت';
      case DateTime.sunday: return 'الأحد';
      case DateTime.monday: return 'الإثنين';
      case DateTime.tuesday: return 'الثلاثاء';
      case DateTime.wednesday: return 'الأربعاء';
      case DateTime.thursday: return 'الخميس';
      default: return '';
    }
  }
}
