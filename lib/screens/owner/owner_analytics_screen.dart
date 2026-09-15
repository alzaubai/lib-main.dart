import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/analytics_service.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  final String pitchName;
  const OwnerAnalyticsScreen({super.key, required this.pitchName});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat currencyFormatter = NumberFormat('#,###');

  // مدى الفلترة: 7 (أسبوع)، 30 (شهر)، 90 (3 أشهر)، 0 (الكل)
  int _selectedFilterDays = 30;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تحليلات الملعب والذروة 📊',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              Text('الملعب: ${widget.pitchName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('bookings')
              .where('pitchName', isEqualTo: widget.pitchName)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
            }

            final allDocs = snapshot.data?.docs ?? [];
            if (allDocs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.query_stats_rounded, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('لا توجد بيانات حجوزات كافية للتحليل بعد',
                        style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }

            // استخراج الحسابات عبر الخدمة المستقلة
            final data = AnalyticsService.calculateAnalytics(
              allDocs: allDocs,
              filterDays: _selectedFilterDays,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTimeFilterChips(),
                  const SizedBox(height: 16),
                  _buildFinancialCards(data.actualRevenue, data.upcomingRevenue, data.totalHoursPlayed, data.occupancyRate),
                  const SizedBox(height: 18),
                  _buildPeakAnalyticsCard(
                    data.peakSlot,
                    data.peakSlotCount,
                    data.peakDay,
                    data.peakDayCount,
                    data.completedCount,
                    data.cancelledCount,
                  ),
                  const SizedBox(height: 18),
                  _buildTopTeamsCard(data.topTeams),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChipItem('آخر 7 أيام', 7),
          const SizedBox(width: 8),
          _filterChipItem('آخر 30 يوماً', 30),
          const SizedBox(width: 8),
          _filterChipItem('آخر 3 أشهر (90 يوم)', 90),
          const SizedBox(width: 8),
          _filterChipItem('كل الحجوزات ♾️', 0),
        ],
      ),
    );
  }

  Widget _filterChipItem(String label, int days) {
    final isSelected = _selectedFilterDays == days;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: const Color(0xFF1B5E20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (val) {
        if (val) setState(() => _selectedFilterDays = days);
      },
    );
  }

  Widget _buildFinancialCards(double actual, double upcoming, int hours, double occupancy) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'الوارد الفعلي المقبوض',
                value: '${currencyFormatter.format(actual)} د.ع',
                icon: Icons.payments_rounded,
                bgColor: const Color(0xFFE8F5E9),
                accentColor: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'الإيراد المتوقع القادم',
                value: '${currencyFormatter.format(upcoming)} د.ع',
                icon: Icons.hourglass_top_rounded,
                bgColor: const Color(0xFFFFF8E1),
                accentColor: Colors.amber.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'ساعات العمل الملعوبة',
                value: '$hours ساعة تشغيل',
                icon: Icons.timer_rounded,
                bgColor: const Color(0xFFE1F5FE),
                accentColor: Colors.blue.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'نسبة إشغال الملعب',
                value: '${occupancy.toStringAsFixed(1)}%',
                icon: Icons.pie_chart_rounded,
                bgColor: const Color(0xFFF3E5F5),
                accentColor: Colors.purple.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentColor),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildPeakAnalyticsCard(
      String peakSlot, int slotCount, String peakDay, int dayCount, int completed, int cancelled) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Colors.amber, size: 22),
                SizedBox(width: 8),
                Text('أوقات الذروة والنشاط الذهبي ⚡',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20))),
              ],
            ),
            const SizedBox(height: 14),
            _buildPeakRow(
              icon: Icons.access_time_filled_rounded,
              title: 'الساعة الذهبية الأكثر طلباً:',
              value: peakSlot != 'غير محدد' ? '$peakSlot ($slotCount حجز)' : 'لا تتوفر حجوزات كافية',
              color: Colors.orange.shade800,
            ),
            const Divider(height: 20),
            _buildPeakRow(
              icon: Icons.calendar_month_rounded,
              title: 'اليوم الأكثر نشاطاً في الأسبوع:',
              value: peakDay != 'غير محدد' ? 'يوم $peakDay ($dayCount حجز)' : 'لا تتوفر حجوزات كافية',
              color: Colors.blue.shade800,
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('مباريات لُعبت: $completed ✔️',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                Text('طلبات مرفوضة/ملغاة: $cancelled ❌',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTopTeamsCard(List<MapEntry<String, Map<String, dynamic>>> teams) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.leaderboard_rounded, color: Color(0xFF1B5E20), size: 22),
                SizedBox(width: 8),
                Text('الفرق الأكثر حجزاً والتزاماً 🏆',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20))),
              ],
            ),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('لا توجد بيانات فرق مسجلة بعد', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: teams.length > 5 ? 5 : teams.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, idx) {
                  final tName = teams[idx].key;
                  final count = teams[idx].value['count'] as int;
                  final paid = teams[idx].value['paid'] as double;
                  final isTrusted = teams[idx].value['trusted'] == true;

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: idx == 0 ? Colors.amber : const Color(0xFFE8F5E9),
                        child: Text('${idx + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: idx == 0 ? Colors.black87 : const Color(0xFF1B5E20))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(tName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (isTrusted) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Colors.blue, size: 15),
                                ],
                              ],
                            ),
                            Text('حجز $count مباراة • إجمالي الدفع: ${currencyFormatter.format(paid)} د.ع',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
