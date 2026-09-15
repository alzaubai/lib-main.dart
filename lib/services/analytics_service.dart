import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsData {
  final double actualRevenue;
  final double upcomingRevenue;
  final int totalHoursPlayed;
  final double occupancyRate;
  final String peakSlot;
  final int peakSlotCount;
  final String peakDay;
  final int peakDayCount;
  final int completedCount;
  final int cancelledCount;
  final List<MapEntry<String, Map<String, dynamic>>> topTeams;

  AnalyticsData({
    required this.actualRevenue,
    required this.upcomingRevenue,
    required this.totalHoursPlayed,
    required this.occupancyRate,
    required this.peakSlot,
    required this.peakSlotCount,
    required this.peakDay,
    required this.peakDayCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.topTeams,
  });
}

class AnalyticsService {
  static String getArabicDayName(DateTime date) {
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

  static AnalyticsData calculateAnalytics({
    required List<QueryDocumentSnapshot> allDocs,
    required int filterDays,
  }) {
    final now = DateTime.now();

    // 1. تطبيق فلترة التاريخ
    final filteredDocs = allDocs.where((doc) {
      if (filterDays == 0) return true;
      final d = doc.data() as Map<String, dynamic>;
      final dateStr = (d['date'] ?? '').toString();
      final bookingDate = DateTime.tryParse(dateStr);
      if (bookingDate == null) return true;
      return now.difference(bookingDate).inDays <= filterDays;
    }).toList();

    double actualRevenue = 0.0;
    double upcomingRevenue = 0.0;
    int totalHoursPlayed = 0;
    int completedCount = 0;
    int cancelledCount = 0;

    final Map<String, int> slotFrequency = {};
    final Map<String, int> dayFrequency = {};
    final Map<String, Map<String, dynamic>> teamStats = {};

    for (var doc in filteredDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final price = (d['price'] as num?)?.toDouble() ?? 0.0;
      final status = d['status'] ?? 'pending';
      final slot = (d['startTime'] ?? '').toString().trim();
      final team1 = (d['teamOne'] ?? '').toString().trim();
      final isTrusted = d['teamTrustedRated'] == true;

      // حساب الإيرادات وساعات التشغيل
      if (status == 'completed') {
        actualRevenue += price;
        totalHoursPlayed += 1;
        completedCount++;
      } else if (status == 'upcoming' || status == 'tournament_match' || status == 'confirmed') {
        upcomingRevenue += price;
      } else if (status == 'rejected') {
        cancelledCount++;
      }

      // حساب ساعات الذروة
      if (slot.isNotEmpty && (status == 'completed' || status == 'upcoming' || status == 'confirmed')) {
        slotFrequency[slot] = (slotFrequency[slot] ?? 0) + 1;
      }

      // حساب أيام الذروة
      final dateStr = (d['date'] ?? '').toString();
      final bookingDate = DateTime.tryParse(dateStr);
      if (bookingDate != null && (status == 'completed' || status == 'upcoming' || status == 'confirmed')) {
        final dayName = getArabicDayName(bookingDate);
        dayFrequency[dayName] = (dayFrequency[dayName] ?? 0) + 1;
      }

      // إحصائيات الفرق
      if (team1.isNotEmpty && !team1.startsWith('مباراة بطولة')) {
        if (!teamStats.containsKey(team1)) {
          teamStats[team1] = {'count': 0, 'paid': 0.0, 'trusted': isTrusted};
        }
        teamStats[team1]!['count'] = (teamStats[team1]!['count'] as int) + 1;
        if (status == 'completed') {
          teamStats[team1]!['paid'] = (teamStats[team1]!['paid'] as double) + price;
        }
        if (isTrusted) {
          teamStats[team1]!['trusted'] = true;
        }
      }
    }

    // استخراج ساعة الذروة الأولى
    String peakSlot = 'غير محدد';
    int peakSlotCount = 0;
    slotFrequency.forEach((k, v) {
      if (v > peakSlotCount) {
        peakSlotCount = v;
        peakSlot = k;
      }
    });

    // استخراج يوم الذروة
    String peakDay = 'غير محدد';
    int peakDayCount = 0;
    dayFrequency.forEach((k, v) {
      if (v > peakDayCount) {
        peakDayCount = v;
        peakDay = k;
      }
    });

    // حساب نسبة الإشغال التقديرية (7 ساعات تشغيل يومياً)
    final int daysCount = filterDays == 0 ? 30 : filterDays;
    final int maxCapacityHours = daysCount * 7;
    final double occupancyRate = maxCapacityHours > 0
        ? ((totalHoursPlayed / maxCapacityHours) * 100).clamp(0, 100).toDouble()
        : 0.0;

    // ترتيب الفرق تنازلياً
    final sortedTeams = teamStats.entries.toList()
      ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));

    return AnalyticsData(
      actualRevenue: actualRevenue,
      upcomingRevenue: upcomingRevenue,
      totalHoursPlayed: totalHoursPlayed,
      occupancyRate: occupancyRate,
      peakSlot: peakSlot,
      peakSlotCount: peakSlotCount,
      peakDay: peakDay,
      peakDayCount: peakDayCount,
      completedCount: completedCount,
      cancelledCount: cancelledCount,
      topTeams: sortedTeams,
    );
  }
}
