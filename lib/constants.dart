import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const Map<String, List<String>> iraqLocations = {
  'بغداد': ['الكل', 'أبو غريب', 'الكرخ', 'الرصافة', 'الكاظمية', 'المنصور', 'الدورة', 'الأعظمية', 'الشعب', 'مدينة الصدر', 'السيدية', 'الغزالية', 'حي الجامعة', 'الشعلة', 'العامرية', 'الزعفرانية', 'الكرادة', 'اليرموك'],
  'الأنبار': ['الكل', 'الرمادي', 'الفلوجة', 'هيت', 'حديثة', 'عانة', 'القائم', 'الرطبة', 'الخالدية', 'الكرمة'],
  'البصرة': ['الكل', 'البصرة القديمة', 'العشار', 'الجبيلة', 'القرنة', 'الزبير', 'شط العرب', 'أبو الخصيب', 'الفاو'],
  'النجف': ['الكل', 'النجف الأشرف', 'الكوفة', 'المناذرة', 'المشخاب', 'الحيدرية'],
  'كربلاء': ['الكل', 'مركز كربلاء', 'عين التمر', 'طويريج (الهندية)', 'الحسينية'],
  'بابل': ['الكل', 'الحلة', 'المحاويل', 'المسيب', 'القاسم', 'الهاشمية', 'الإسكندرية'],
  'أربيل': ['الكل', 'مركز أربيل', 'عنكاوا', 'شقلاوة', 'سوران', 'راوندوز'],
  'السليمانية': ['الكل', 'مركز السليمانية', 'رانية', 'دوكان', 'كلار', 'حلبجة'],
  'نينوى': ['الكل', 'الموصل (الجانب الأيمن)', 'الموصل (الجانب الأيسر)', 'تلعفر', 'الحمدانية', 'سنجار'],
  'ميسان': ['الكل', 'العمارة', 'علي الغربي', 'الميمونة', 'قلعة صالح', 'المجر الكبير'],
  'ذي قار': ['الكل', 'الناصرية', 'الشطرة', 'الرفاعي', 'سوق الشيوخ', 'الجبايش'],
  'صلاح الدين': ['الكل', 'تكريت', 'سامراء', 'بلد', 'الدجيل', 'طوزخورماتو', 'بيجي'],
  'ديالى': ['الكل', 'بعقوبة', 'المقدادية', 'الخالص', 'خانقين', 'بلدروز'],
  'واسط': ['الكل', 'الكوت', 'الحي', 'الصويرة', 'النعمانية', 'بدرة'],
  'كركوك': ['الكل', 'مركز كركوك', 'الحويجة', 'داقوق', 'دبس'],
  'الديوانية': ['الكل', 'مركز الديوانية', 'عفك', 'الشامية', 'الحمزة'],
  'المثنى': ['الكل', 'السماوة', 'الرميثة', 'الخضر', 'الوركاء'],
  'دهوك': ['الكل', 'مركز دهوك', 'زاخو', 'سميل', 'عمادية']
};

const List<String> pitchTypesList = [
  'الكل',
  'خماسي (5 ضد 5)',
  'سداسي (6 ضد 6)',
  'سباعي (7 ضد 7)',
  'ثماني (8 ضد 8)',
  'قانوني كامل (11 ضد 11)'
];

const List<String> weekDaysList = [
  'الجمعة',
  'السبت',
  'الأحد',
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس'
];

List<String> buildPitchSlots(int durationMinutes) {
  final List<String> slots = [];
  DateTime current = DateTime(2026, 1, 1, 16, 0);
  final DateTime end = DateTime(2026, 1, 2, 1, 0);

  while (current.isBefore(end)) {
    final DateTime next = current.add(Duration(minutes: durationMinutes));
    final sStr = DateFormat('hh:mm a').format(current).replaceAll('AM', 'ص').replaceAll('PM', 'م');
    final eStr = DateFormat('hh:mm a').format(next).replaceAll('AM', 'ص').replaceAll('PM', 'م');
    slots.add('$sStr - $eStr');
    current = next;
  }
  return slots;
}

String getArabicDayName(DateTime date) {
  const days = {
    DateTime.friday: 'الجمعة',
    DateTime.saturday: 'السبت',
    DateTime.sunday: 'الأحد',
    DateTime.monday: 'الإثنين',
    DateTime.tuesday: 'الثلاثاء',
    DateTime.wednesday: 'الأربعاء',
    DateTime.thursday: 'الخميس',
  };
  return days[date.weekday] ?? '';
}

Future<void> launchCallDirect(String phone) async {
  final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri(scheme: 'tel', path: clean);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Error launching dialer: $e');
  }
}

Future<void> launchWhatsAppDirect(String phone) async {
  var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.startsWith('07')) {
    clean = '964${clean.substring(1)}';
  }
  final uri = Uri.parse('https://wa.me/$clean');
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Error launching WhatsApp: $e');
  }
}

Future<void> launchWaze(double lat, double lng) async {
  final url = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Error opening Waze: $e');
  }
}

Future<void> launchGoogleMaps(double lat, double lng) async {
  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Error opening Google Maps: $e');
  }
}

void showMapChooserSheet(BuildContext context, double lat, double lng, String pitchName) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الانتقال لموقع $pitchName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            const Text('اختر تطبيق الخرائط والملاحة المفضل لديك:', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33CCFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.navigation, size: 22),
              label: const Text('فتح عبر Waze (الموصى به للطرق والزحام)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () {
                Navigator.pop(ctx);
                launchWaze(lat, lng);
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.map, size: 22),
              label: const Text('فتح عبر Google Maps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () {
                Navigator.pop(ctx);
                launchGoogleMaps(lat, lng);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
