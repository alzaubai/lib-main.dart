import 'package:url_launcher/url_launcher.dart';

// قائمة المحافظات العراقية
const List<String> iraqGovernoratesList = [
  'الكل',
  'بغداد',
  'البصرة',
  'أربيل',
  'النجف',
  'كربلاء',
  'نينوى',
  'كركوك',
  'السليمانية',
  'دهوك',
  'الأنبار',
  'بابل',
  'ديالى',
  'واسط',
  'ميسان',
  'ذي قار',
  'المثنى',
  'القادسية',
  'صلاح الدين',
];

// اسم مرادف للتوافق القديم
const List<String> iraqGovernorates = iraqGovernoratesList;

// مناطق ومحلات كل محافظة
final Map<String, List<String>> iraqAreasData = {
  'بغداد': [
    'الكل',
    'الكرخ',
    'الرصافة',
    'أبو غريب',
    'المنصور',
    'اليرموك',
    'الدورة',
    'السيدية',
    'العامرية',
    'الغزالية',
    'الشعلة',
    'الكاظمية',
    'الحرية',
    'الكرادة',
    'الجادرية',
    'زيونة',
    'شارع فلسطين',
    'مدينة الصدر',
    'الأعظمية',
    'الشعب',
    'البنوك',
    'القاهرة',
    'الزعفرانية',
    'المحمودية',
    'التاجي',
  ],
  'البصرة': ['الكل', 'العشار', 'الجبيلة', 'القرنة', 'الزبير', 'شط العرب', 'أبو الخصيب', 'المعقل', 'الطويسة'],
  'أربيل': ['الكل', 'عينكاوة', 'الشارع الستيني', 'الشارع المئة', 'بختياري', 'طيراوة', 'شورش'],
  'النجف': ['الكل', 'الكوفة', 'المشخاب', 'الحنانة', 'حي الأمير', 'حي الغدير', 'حي السعد'],
  'كربلاء': ['الكل', 'مركز المدينة', 'الهندية', 'عين التمر', 'حي الحسين', 'حي المعلمين', 'حي العباس'],
  'الأنبار': ['الكل', 'الرمادي', 'الفلوجة', 'هيت', 'القائم', 'حديثة', 'الخالدية'],
  'بابل': ['الكل', 'الحلة', 'المحاويل', 'المسيب', 'القاسم', 'الهاشمية'],
  'ديالى': ['الكل', 'بعقوبة', 'المقدادية', 'الخالص', 'خانقين', 'بلدروز'],
};

// دالة إرجاع المناطق حسب المحافظة
List<String> getAreasListForGov(String gov) {
  return iraqAreasData[gov] ?? ['الكل', 'المركز', 'شمال المحافظة', 'جنوب المحافظة'];
}

// اسم مرادف للتوافق
List<String> getAreasForGovernorate(String gov) => getAreasListForGov(gov);

// أنواع وأحجام الملاعب
const List<String> pitchTypesList = [
  'الكل',
  'خماسي (5 ضد 5)',
  'سداسي (6 ضد 6)',
  'سباعي (7 ضد 7)',
  'تساعي (9 ضد 9)',
  'ملعب قانوني (11 ضد 11)',
];

// أنواع الأرضيات
const List<String> pitchSurfaceTypesList = [
  'الكل',
  'ثيل 🌿',
  'تارتان صلب 🔴',
  'ترابي 🏜️',
];

// توليد فترات وساعات اللعب من العصر حتى الفجر (قائمة ثابتة قديمة - أبقيناها للتوافق)
List<String> buildPitchSlots(int durationMinutes) {
  return [
    '04:00 م - 05:00 م',
    '05:00 م - 06:00 م',
    '06:00 م - 07:00 م',
    '07:00 م - 08:00 م',
    '08:00 م - 09:00 م',
    '09:00 م - 10:00 م',
    '10:00 م - 11:00 م',
    '11:00 م - 12:00 ص',
    '12:00 ص - 01:00 ص',
    '01:00 ص - 02:00 ص',
    '02:00 ص - 03:00 ص',
  ];
}

// تحويل نص وقت عربي (مثال: "04:00 م") إلى (ساعة 24، دقيقة)
List<int> _parseArabicHourMinute(String raw) {
  final clean = raw.trim();
  final isPM = clean.contains('م') && !clean.contains('ص');
  final isAM = clean.contains('ص');
  final digitsOnly = clean.replaceAll(RegExp(r'[^0-9:]'), '');
  final parts = digitsOnly.split(':');
  int hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

  if (isPM && hour < 12) hour += 12;
  if (isAM && hour == 12) hour = 0;
  return [hour, minute];
}

// تحويل (ساعة 24، دقيقة) إلى نص عربي بصيغة "hh:mm ص/م"
String _formatArabicHourMinute(int hour24, int minute) {
  final isPM = hour24 >= 12;
  int hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;
  final hh = hour12.toString().padLeft(2, '0');
  final mm = minute.toString().padLeft(2, '0');
  return '$hh:$mm ${isPM ? 'م' : 'ص'}';
}

/// توليد فترات الحجز الفعلية بالاعتماد على دوام الملعب الحقيقي (openTime/closeTime)
/// المُدخلة والمُخرجة بصيغة عربية (ص/م) متوافقة مع باقي التطبيق
List<String> buildPitchSlotsForRange({
  required String openTime,
  required String closeTime,
  int durationMinutes = 60,
}) {
  try {
    final startParts = _parseArabicHourMinute(openTime);
    final endParts = _parseArabicHourMinute(closeTime);

    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day, startParts[0], startParts[1]);
    DateTime end = DateTime(now.year, now.month, now.day, endParts[0], endParts[1]);

    // إذا كانت نهاية الدوام قبل أو تساوي بدايته، يعني الدوام يمتد لليوم التالي (بعد منتصف الليل)
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    final List<String> slots = [];
    DateTime current = start;
    while (current.isBefore(end)) {
      final next = current.add(Duration(minutes: durationMinutes));
      if (next.isAfter(end)) break;
      final sLabel = _formatArabicHourMinute(current.hour, current.minute);
      final eLabel = _formatArabicHourMinute(next.hour, next.minute);
      slots.add('$sLabel - $eLabel');
      current = next;
    }

    // في حال فشل الحساب أو رجعت فارغة، نرجع للقائمة الثابتة كحل احتياطي
    if (slots.isEmpty) return buildPitchSlots(durationMinutes);
    return slots;
  } catch (_) {
    return buildPitchSlots(durationMinutes);
  }
}

// دوال فتح الاتصال والخرائط والواتساب
Future<void> launchCallDirect(String phone) async {
  final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final uri = Uri.parse('tel:$cleanPhone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> launchWhatsAppDirect(String phone) async {
  var cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (cleanPhone.startsWith('07')) {
    cleanPhone = '964${cleanPhone.substring(1)}';
  }
  final uri = Uri.parse('https://wa.me/$cleanPhone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> launchMapDirect(double lat, double lng) async {
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// مرادف بنفس الاسم القديم
Future<void> launchMapsDirect(double lat, double lng) => launchMapDirect(lat, lng);
