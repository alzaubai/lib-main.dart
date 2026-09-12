import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Map<String, List<String>> iraqLocations = {
  'بغداد': [
    'الكل',
    'الكرخ الأولى',
    'الكرخ الثانية',
    'الكرخ الثالثة',
    'الرصافة الأولى',
    'الرصافة الثانية',
    'الرصافة الثالثة',
    'أبو غريب',
    'المحمودية',
    'الطارمية',
    'التاجي',
    'المدائن',
  ],
  'البصرة': ['الكل', 'العشار', 'الجبيلة', 'المعقل', 'القرنة', 'الزبير', 'شط العرب'],
  'أربيل': ['الكل', 'عنكاوا', 'الروستايا', 'بيتي', 'السركال', 'قلعة أربيل'],
  'النجف': ['الكل', 'المدينة القديمة', 'الحنانة', 'الوفاء', 'الكوفة'],
  'كربلاء': ['الكل', 'مركز المدينة', 'الحر', 'العباسية', 'المحافظة'],
  'بابل': ['الكل', 'الحلة', 'المحاويل', 'الإسكندرية', 'المدحتية', 'القاسم'],
  'السليمانية': ['الكل', 'بختياري', 'الكورنيش', 'سرجنار'],
  'نينوى': ['الكل', 'الموصل الحدباء', 'الزهور', 'العلا', 'التحرير'],
};

const Map<String, List<String>> subLocationsMap = {
  'الكرخ الأولى': ['المنصور', 'اليرموك', 'العلاوي', 'الدورة', 'البياع', 'الكاظمية'],
  'الكرخ الثانية': ['العامرية', 'الحارثية', 'الداوودي', 'الغزالية', 'العريج'],
  'الكرخ الثالثة': ['الشعلة', 'الحرية', 'الإعلام', 'الكاظمية المقدسة', 'الطارمية (أطراف)'],
  'الرصافة الأولى': ['الكرادة', 'الشارع الرئيسي', 'أبو نؤاس', 'العرصات', 'المسبح'],
  'الرصافة الثانية': ['زيونة', 'الغدير', 'البلديات', 'المصارف', 'الأمين'],
  'الرصافة الثالثة': ['الأعظمية', 'الكسرة', 'الميدان', 'باب المعظم', 'الوزيرية', 'الشعب'],
  'أبو غريب': ['مركز القضاء', 'الرسالة', 'الرشاد', 'الزيتون', 'الشحيمية', 'النصر والسلام'],
  'المحمودية': ['مركز المحمودية', 'اللطيفية', 'اليوسفية'],
  'الطارمية': ['مركز الطارمية', 'العبايجي'],
  'التاجي': ['مركز التاجي', 'المشاهدة', 'البوعيفان'],
  'المدائن': ['مركز المدائن', 'النهروان', 'الجسر'],
};

const List<String> pitchTypesList = [
  'الكل',
  'خماسي (5 ضد 5)',
  'سداسي (6 ضد 6)',
  'سباعي (7 ضد 7)',
  'تساعي (9 ضد 9)',
  'ملعب قانوني (11 ضد 11)',
];

const List<String> pitchSurfaceTypesList = [
  'الكل',
  'ثيل 🌿',
  'تارتان 🏟️',
  'ترابي 🏜️',
];

const List<String> weekDaysList = [
  'الجمعة',
  'السبت',
  'الأحد',
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
];

List<String> buildPitchSlots(int durationMinutes) {
  List<String> slots = [];
  int startHour = 16;
  int startMin = 0;
  int endHour = 2;
  int endMin = 0;

  TimeOfDay current = TimeOfDay(hour: startHour, minute: startMin);
  TimeOfDay closing = TimeOfDay(hour: endHour, minute: endMin);

  while (true) {
    TimeOfDay next = addMinutes(current, durationMinutes);
    if (isAfterOrEqual(next, closing) && current.hour >= 16) break;
    slots.add('${formatTimeAmPm(current)} - ${formatTimeAmPm(next)}');
    current = next;
    if (current.hour == closing.hour && current.minute == closing.minute) break;
  }
  return slots;
}

TimeOfDay addMinutes(TimeOfDay time, int minutes) {
  int totalMins = time.hour * 60 + time.minute + minutes;
  int newHour = (totalMins ~/ 60) % 24;
  int newMin = totalMins % 60;
  return TimeOfDay(hour: newHour, minute: newMin);
}

bool isAfterOrEqual(TimeOfDay t1, TimeOfDay t2) {
  int m1 = t1.hour * 60 + t1.minute;
  int m2 = t2.hour * 60 + t2.minute;
  if (t1.hour < 6 && t2.hour >= 16) m1 += 24 * 60;
  return m1 >= m2 + (t2.hour < 6 ? 24 * 60 : 0);
}

String formatTimeAmPm(TimeOfDay time) {
  int h = time.hour;
  String period = h >= 12 ? 'م' : 'ص';
  int hour12 = h % 12;
  if (hour12 == 0) hour12 = 12;
  String minStr = time.minute.toString().padLeft(2, '0');
  return '$hour12:$minStr $period';
}

Future<void> launchCallDirect(String phone) async {
  String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri, mode: LaunchMode.platformDefault);
  }
}

Future<void> launchWhatsAppDirect(String phone) async {
  String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
  if (cleanPhone.startsWith('0')) {
    cleanPhone = '964${cleanPhone.substring(1)}';
  }
  final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent("مرحباً كابتن، استفسر بخصوص حجز ملعب في تطبيق ملعبي")}');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

void showMapChooserSheet(BuildContext context, double lat, double lng, String pitchName) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('التوجه إلى: $pitchName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF33CCFF), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.navigation),
              label: const Text('فتح عبر Waze', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final url = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.map),
              label: const Text('فتح عبر Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
