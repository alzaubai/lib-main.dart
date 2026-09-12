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
  String _selectedFilter = 'كل الأوقات'; // كل الأوقات, هذا الشهر
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final now = DateTime.now();
            final currentMonthPrefix = DateFormat('yyyy-MM').format(now);

            // تطبيق الفلتر الزمني
            final filteredDocs = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              if (_selectedFilter == 'هذا الشهر') {
                final dateStr = data['date']?.toString() ?? '';
                return dateStr.startsWith(currentMonthPrefix);
              }
              return true;
            }).toList();

            // الحسابات الرياضية
            double totalRevenue = 0.0;
            int completedMatches = 0;
            int upcomingMatches = 0;

            final Map<String, int> slotPopularity = {};
            final Map<String, Map<String, dynamic>> teamStats = {};
            final Map<String, int> dayOfWeekStats = {
              'الجمعة': 0,
              'السبت': 0,
              'الأحد': 0,
              'الإثنين': 0,
              'الثلاثاء': 0,
              'الأربعاء': 0,
              'الخميس': 0,
            };

            for (var d in filteredDocs) {
              final data = d.data() as Map<String, dynamic>;
              final status = data['status'];
              final price = (data['price'] as num?)?.toDouble() ?? 0.0;
              final slot = '${data['startTime']} - ${data['endTime']}';
              final team1 = data['teamOne']?.toString().trim() ?? '';
              final dateStr = data['date']?.toString() ?? '';

              if (status == 'completed') {
                totalRevenue += price;
                completedMatches++;
              } else if (status == 'upcoming') {
                upcomingMatches++;
              }

              // تتبع الأوقات الأكثر طلباً
              if (slot.isNotEmpty && slot != ' - ') {
                slotPopularity[slot] = (slotPopularity[slot] ?? 0) + 1;
              }

              // تتبع الفرق الأكثر حجزاً
              if (team1.isNotEmpty && team1 != 'بانتظار الخصم') {
                if (!teamStats.containsKey(team1)) {
                  teamStats[team1] = {'count': 0, 'spent': 0.0};
                }
                teamStats[team1]!['count'] = (teamStats[team1]!['count'] as int) + 1;
                if (status == 'completed') {
                  teamStats[team1]!['spent'] = (teamStats[team1]!['spent'] as double) + price;
                }
              }

              // تتبع الأيام
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
                  // بطاقات الإحصاءات العامة السريعة
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'إجمالي الوارد المحصل',
                          value: '${currencyFormatter.format(totalRevenue)} د.ع',
                          icon: Icons.monetization_on,
                          color: Colors.green.shade800,
                          bgColor: Colors.green.shade50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'المباريات المكتملة',
                          value: '$completedMatches مباراة',
                          icon: Icons.sports_soccer,
                          color: Colors.teal.shade800,
                          bgColor: Colors.teal.shade50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'حجوزات قادمة مؤكدة',
                          value: '$upcomingMatches موعد',
                          icon: Icons.calendar_today,
                          color: Colors.blue.shade800,
                          bgColor: Colors.blue.shade50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'معدل الدخل لكل مباراة',
                          value: completedMatches > 0 ? '${currencyFormatter.format(totalRevenue / completedMatches)} د.ع' : '0 د.ع',
                          icon: Icons.analytics,
                          color: Colors.amber.shade900,
                          bgColor: Colors.amber.shade50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ساعات الذروة (Peak Hours)
                  const Text('ساعات الذروة والأوقات الأكثر طلباً ⏰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: sortedSlots.isEmpty
                        ? const Center(child: Text('لا توجد بيانات كافية للحجوزات', style: TextStyle(color: Colors.grey)))
                        : Column(
                            children: sortedSlots.take(4).map((entry) {
                              final total = filteredDocs.isEmpty ? 1 : filteredDocs.length;
                              final ratio = entry.value / total;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('${entry.value} حجز (${(ratio * 100).toInt()}%)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // نشاط أيام الأسبوع
                  const Text('نشاط الملعب عبر أيام الأسبوع 📅', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dayOfWeekStats.entries.map((e) {
                        final count = e.value;
                        final maxCount = dayOfWeekStats.values.fold<int>(1, (max, v) => v > max ? v : max);
                        final barHeight = (count / maxCount) * 80.0 + 10.0;

                        return Column(
                          children: [
                            Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: count > 0 ? const Color(0xFF1B5E20) : Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              width: 22,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: count > 0 ? Colors.green.shade700 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(e.key, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // الفرق الأكثر حجزاً ووفاءً (Top VIP Teams)
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _getArabicDay(int weekday) {
    switch (weekday) {
      case DateTime.friday:
        return 'الجمعة';
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
      case DateTime.thursday:
        return 'الخميس';
      default:
        return '';
    }
  }
}
