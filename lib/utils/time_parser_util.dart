class TimeParserUtil {
  /// تحويل رقم اليوم إلى اسم اليوم باللغة العربية
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

  /// تحويل نصوص التاريخ والوقت إلى كائن DateTime للمقارنة
  static DateTime? parseMatchDateTime(String dateStr, String timeStr) {
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) return null;

      final clean = timeStr.trim();
      final isPM = clean.contains('م') || clean.toLowerCase().contains('pm');
      final parts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// فحص هل باقي أقل من 3 ساعات على موعد المباراة
  static bool isLessThan3Hours(String dateStr, String timeStr) {
    final matchTime = parseMatchDateTime(dateStr, timeStr);
    if (matchTime == null) return false;
    final diff = matchTime.difference(DateTime.now());
    return !diff.isNegative && diff.inMinutes < 180;
  }

  /// فحص هل انقضى وقت المباراة بالكامل
  static bool isMatchPassed(String dateStr, String timeStr) {
    final matchTime = parseMatchDateTime(dateStr, timeStr);
    if (matchTime == null) return false;
    return matchTime.difference(DateTime.now()).isNegative;
  }
}
