import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
  }
  runApp(const PitchBookingApp());
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

class PitchBookingApp extends StatelessWidget {
  const PitchBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ملعبي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Tajawal',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFF57F17),
          surface: const Color(0xFFF8FBF8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F4),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
      ),
      home: const Directionality(
        textDirection: ui.TextDirection.rtl,
        child: RoleSelectionScreen(),
      ),
    );
  }
}

// -------------------------------------------------------------
// الشاشة الرئيسية لاختيار الحساب
// -------------------------------------------------------------
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPitch = prefs.getString('current_pitch_name');
    final savedPlayerPhone = prefs.getString('current_player_phone');

    if (savedPitch != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: OwnerDashboardScreen(pitchName: savedPitch),
          ),
        ),
      );
    } else if (savedPlayerPhone != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: PlayerMainScreen(playerPhone: savedPlayerPhone),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.sports_soccer, size: 95, color: Color(0xFF1B5E20)),
              const SizedBox(height: 12),
              const Text('تطبيق مَلعَبي', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 6),
              const Text('المنصة الرياضية لحجز وتنظيم ملاعب كرة القدم', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.stadium),
                label: const Text('دخول صاحب ملعب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _openOwnerLoginModal(context),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.app_registration),
                label: const Text('تسجيل ملعب جديد لأول مرة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: () => _openOwnerRegisterModal(context),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('بوابة اللاعبين والفرق', style: TextStyle(color: Colors.grey, fontSize: 12))),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.login),
                label: const Text('تسجيل دخول كابتن / لاعب', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: () => _openPlayerLoginModal(context),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueGrey.shade800,
                  side: BorderSide(color: Colors.blueGrey.shade800, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.person_add),
                label: const Text('إنشاء حساب كابتن جديد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: () => _openPlayerRegisterModal(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOwnerLoginModal(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('تسجيل دخول صاحب ملعب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 14),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف المسجل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 10),
              TextField(controller: pinCtrl, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const InputDecoration(labelText: 'رمز PIN (4 أرقام)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final phone = phoneCtrl.text.trim();
                  final pin = pinCtrl.text.trim();

                  final q = await FirebaseFirestore.instance.collection('pitches').where('phone', isEqualTo: phone).where('pin', isEqualTo: pin).limit(1).get();
                  if (q.docs.isNotEmpty) {
                    final pitchName = q.docs.first.data()['name'] as String;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('current_pitch_name', pitchName);
                    if (mounted) {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: ui.TextDirection.rtl, child: OwnerDashboardScreen(pitchName: pitchName))));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف أو الرمز غير صحيح'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOwnerRegisterModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '15000');

    String selectedGov = 'بغداد';
    String selectedDist = 'أبو غريب';
    String selectedType = 'سباعي (7 ضد 7)';
    int matchDurationMinutes = 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final dists = iraqLocations[selectedGov]!.where((d) => d != 'الكل').toList();
          if (!dists.contains(selectedDist)) selectedDist = dists.first;

          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('تسجيل ملعب جديد في مَلعَبي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الملعب (مثال: ملعب النجوم)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGov,
                            decoration: const InputDecoration(labelText: 'المحافظة', border: OutlineInputBorder()),
                            items: iraqLocations.keys.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedGov = val;
                                  selectedDist = iraqLocations[val]!.where((d) => d != 'الكل').first;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDist,
                            decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder()),
                            items: dists.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedDist = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'نوع وحجم الملعب', border: OutlineInputBorder()),
                      items: pitchTypesList.where((t) => t != 'الكل').map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: matchDurationMinutes,
                      decoration: const InputDecoration(labelText: 'مدة الحجز للمباراة الواحدة', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 60, child: Text('ساعة واحدة')),
                        DropdownMenuItem(value: 90, child: Text('ساعة ونصف')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => matchDurationMinutes = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر الحجز للملعب (د.ع)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتف الحجز والتواصل', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: pinCtrl, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'رمز PIN للدخول (4 أرقام)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final pin = pinCtrl.text.trim();
                        final rate = double.tryParse(rateCtrl.text.trim()) ?? 15000.0;

                        if (name.isNotEmpty && phone.isNotEmpty && pin.length == 4) {
                          await FirebaseFirestore.instance.collection('pitches').doc(name).set({
                            'name': name,
                            'governorate': selectedGov,
                            'area': selectedDist,
                            'pitchType': selectedType,
                            'phone': phone,
                            'pin': pin,
                            'matchDurationMinutes': matchDurationMinutes,
                            'hourlyRate': rate,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('current_pitch_name', name);

                          if (mounted) {
                            Navigator.pop(ctx);
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: ui.TextDirection.rtl, child: OwnerDashboardScreen(pitchName: name))));
                          }
                        }
                      },
                      child: const Text('تثبيت الملعب وبدء العمل', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPlayerLoginModal(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('تسجيل دخول لاعب / كابتن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 14),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف المسجل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 10),
              TextField(controller: pinCtrl, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const InputDecoration(labelText: 'رمز PIN (4 أرقام)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final phone = phoneCtrl.text.trim();
                  final pin = pinCtrl.text.trim();

                  final doc = await FirebaseFirestore.instance.collection('players').doc(phone).get();
                  if (doc.exists && doc.data()?['pin'] == pin) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('current_player_phone', phone);
                    if (mounted) {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: ui.TextDirection.rtl, child: PlayerMainScreen(playerPhone: phone))));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف أو الرمز السري غير صحيح'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('دخول', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlayerRegisterModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final teamCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('إنشاء حساب كابتن جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 14),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الكابتن الكامل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 10),
                TextField(controller: teamCtrl, decoration: const InputDecoration(labelText: 'اسم فريقك (مثال: الصقور)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.shield))),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف للتواصل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 10),
                TextField(controller: pinCtrl, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'رمز PIN للدخول (4 أرقام)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    final phone = phoneCtrl.text.trim();
                    final name = nameCtrl.text.trim();
                    final team = teamCtrl.text.trim();
                    final pin = pinCtrl.text.trim();

                    if (phone.isNotEmpty && name.isNotEmpty && pin.length == 4) {
                      await FirebaseFirestore.instance.collection('players').doc(phone).set({
                        'name': name,
                        'teamName': team.isEmpty ? 'فريق $name' : team,
                        'phone': phone,
                        'pin': pin,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('current_player_phone', phone);

                      if (mounted) {
                        Navigator.pop(ctx);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: ui.TextDirection.rtl, child: PlayerMainScreen(playerPhone: phone))));
                      }
                    }
                  },
                  child: const Text('تسجيل وبدء الاستخدام', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// لوحة تحكم صاحب الملعب
// -------------------------------------------------------------
class OwnerDashboardScreen extends StatefulWidget {
  final String pitchName;
  const OwnerDashboardScreen({super.key, required this.pitchName});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _pendingSeen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && mounted) {
        setState(() => _pendingSeen = true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, pendingSnapshot) {
        final pendingCount = pendingSnapshot.data?.docs.length ?? 0;
        final showPendingBadge = !_pendingSeen && pendingCount > 0;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B5E20),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pitchName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('إدارة الحجوزات والاشتراكات الدائمة', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet, color: Colors.amberAccent),
                tooltip: 'كشف الحساب المالي',
                onPressed: () => _openFinancialReportModal(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'تسجيل خروج',
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('current_pitch_name');
                  if (mounted) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.amberAccent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                const Tab(icon: Icon(Icons.event_available), text: 'المباريات والجدول'),
                Tab(
                  icon: Badge(
                    isLabelVisible: showPendingBadge,
                    label: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.notifications_active),
                  ),
                  text: 'الطلبات المعلقة',
                ),
                const Tab(icon: Icon(Icons.repeat), text: 'الحجوزات الدائمة'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildConfirmedTab(currencyFormatter),
              _buildPendingTab(pendingSnapshot),
              _buildRecurringBookingsTab(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('حجز موعد جديد', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _openAddManualSheet(context),
          ),
        );
      },
    );
  }

  Widget _buildConfirmedTab(NumberFormat currencyFormatter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).where('status', whereIn: ['upcoming', 'completed']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        double actualRevenueReceived = 0.0;
        double expectedRevenueUpcoming = 0.0;

        for (var doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final price = (d['price'] as num?)?.toDouble() ?? 0.0;
          final status = d['status'];

          if (status == 'completed') {
            actualRevenueReceived += price;
          } else if (status == 'upcoming') {
            expectedRevenueUpcoming += price;
          }
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الوارد الفعلي المقبوض', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('${currencyFormatter.format(actualRevenueReceived)} د.ع', style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المبلغ المتوقع (مؤكد)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('${currencyFormatter.format(expectedRevenueUpcoming)} د.ع', style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? const Center(child: Text('لا توجد مباريات مؤكدة'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final isDone = data['status'] == 'completed';
                        final isRecurring = data['isRecurring'] == true;
                        final phone = data['phone'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('التاريخ: ${data['date']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        if (isRecurring)
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                                            child: const Text('دائم / أسبوعي', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: isDone ? Colors.green.shade100 : Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                                          child: Text(
                                            isDone ? 'مكتملة ومقبوضة' : 'مؤكدة (بانتظار اللعب)',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDone ? Colors.green.shade900 : Colors.orange.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${data['teamOne']} ⚔️ ${data['teamTwo']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                const SizedBox(height: 4),
                                Text('الوقت: ${data['startTime']} إلى ${data['endTime']}  |  المبلغ: ${currencyFormatter.format(data['price'] ?? 0)} د.ع', style: const TextStyle(fontWeight: FontWeight.w600)),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    if (phone.toString().isNotEmpty) ...[
                                      IconButton(icon: const Icon(Icons.phone, color: Colors.green), tooltip: 'اتصال', onPressed: () => launchCallDirect(phone)),
                                      IconButton(icon: const Icon(Icons.message, color: Colors.teal), tooltip: 'واتساب', onPressed: () => launchWhatsAppDirect(phone)),
                                    ],
                                    const Spacer(),
                                    if (!isDone)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                                        onPressed: () => _confirmMatchCompletion(context, doc.reference),
                                        icon: const Icon(Icons.check_circle, size: 16),
                                        label: const Text('تحديد كمكتملة وتنزيل الوارد'),
                                      )
                                    else
                                      const Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.green, size: 18),
                                          SizedBox(width: 4),
                                          Text('تم استلام الوارد نهائياً', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => doc.reference.delete(),
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

  void _confirmMatchCompletion(BuildContext context, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد استلام الوارد'),
          content: const Text(
            'هل أنت متأكد من انتهاء المباراة واستلام الوارد؟\n\nتنبيه: بعد التأكيد سيتم إدخال المبلغ في الوارد الفعلي بشكل نهائي ولن تتمكن من إلغائها أو التراجع عنها.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                await docRef.update({'status': 'completed'});
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('نعم، تأكيد واستلام الوارد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) return const Center(child: Text('لا توجد أي طلبات حجز معلقة'));

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final phone = data['phone'] ?? '';
        final isLookingForOpponent = data['teamTwo'] == 'بانتظار الخصم';

        return Card(
          color: Colors.amber.shade50,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('طلب لموعد: ${data['date']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                    Chip(
                      label: Text(isLookingForOpponent ? 'طلب (يبحث عن خصم)' : 'حجز فريقين', style: const TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: isLookingForOpponent ? Colors.deepOrange : Colors.green.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('الفريق الطالب: ${data['teamOne']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (!isLookingForOpponent) Text('الخصم: ${data['teamTwo']}'),
                Text('الوقت: ${data['startTime']} - ${data['endTime']}'),
                Text('المبلغ المتوقع: ${data['price']} د.ع'),
                const Divider(height: 16),
                Row(
                  children: [
                    if (phone.toString().isNotEmpty) ...[
                      IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => launchCallDirect(phone)),
                      IconButton(icon: const Icon(Icons.message, color: Colors.teal), onPressed: () => launchWhatsAppDirect(phone)),
                    ],
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('رفض'),
                      onPressed: () => _showRejectDialog(context, doc.reference),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                      label: const Text('تثبيت وقبول', style: TextStyle(color: Colors.white)),
                      onPressed: () => doc.reference.update({'status': 'upcoming'}),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecurringBookingsTab() {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('recurring_rules').where('pitchName', isEqualTo: widget.pitchName).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد حجوزات أسبوعية ثابتة مضافة حتى الآن'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: Colors.purple.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.repeat, color: Colors.white)),
                  title: Text('كل يوم ${data['dayOfWeek']} (${data['timeSlot']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('محجوز دائماً لـ: ${data['teamName']}  |  هاتف: ${data['phone']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => doc.reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('إضافة حجز أسبوعي ثابت'),
        onPressed: () => _openAddRecurringDialog(context),
      ),
    );
  }

  void _openAddRecurringDialog(BuildContext context) {
    String day = 'الجمعة';
    final slotCtrl = TextEditingController(text: '08:00 م - 09:30 م');
    final teamCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '15000');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل حجز ثابت أسبوعياً'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: day,
                    decoration: const InputDecoration(labelText: 'يوم الحجز في كل أسبوع', border: OutlineInputBorder()),
                    items: weekDaysList.map((d) => DropdownMenuItem(value: d, child: Text('كل يوم $d'))).toList(),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => day = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: slotCtrl, decoration: const InputDecoration(labelText: 'وقت الحجز (مثال: 08:00 م - 09:30 م)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: teamCtrl, decoration: const InputDecoration(labelText: 'اسم الفريق أو الكابتن الدائم', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتف الفريق', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ لكل مباراة (د.ع)', border: OutlineInputBorder())),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade800),
                onPressed: () async {
                  if (teamCtrl.text.isNotEmpty) {
                    await _firestore.collection('recurring_rules').add({
                      'pitchName': widget.pitchName,
                      'dayOfWeek': day,
                      'timeSlot': slotCtrl.text.trim(),
                      'teamName': teamCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text.trim()) ?? 15000.0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('حفظ كحجز ثابت', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFinancialReportModal(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).snapshots(),
        builder: (context, snapshot) {
          double completedTotal = 0;
          double upcomingTotal = 0;
          double pendingTotal = 0;

          if (snapshot.hasData) {
            for (var d in snapshot.data!.docs) {
              final data = d.data() as Map<String, dynamic>;
              final p = (data['price'] as num?)?.toDouble() ?? 0.0;
              final st = data['status'];
              if (st == 'completed') completedTotal += p;
              if (st == 'upcoming') upcomingTotal += p;
              if (st == 'pending') pendingTotal += p;
            }
          }

          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('كشف الحساب المالي الشامل للملعب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 16),
                  ListTile(
                    tileColor: Colors.green.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Text('الوارد الفعلي المقبوض (مكتمل)'),
                    trailing: Text('${currencyFormatter.format(completedTotal)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    tileColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Text('المبلغ المتوقع (حجوزات مؤكدة قادمة)'),
                    trailing: Text('${currencyFormatter.format(upcomingTotal)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    tileColor: Colors.amber.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Text('مبالغ قيد الانتظار (طلبات معلقة)'),
                    trailing: Text('${currencyFormatter.format(pendingTotal)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    tileColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Text('إجمالي الدخل المتوقع الكلي', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('${currencyFormatter.format(completedTotal + upcomingTotal)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق الكشف', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRejectDialog(BuildContext context, DocumentReference docRef) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('سبب الرفض والاعتذار'),
          content: TextField(
            controller: reasonCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'اكتب سبب الاعتذار (مثال: محجوز حضورياً أو صيانة)', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final r = reasonCtrl.text.trim();
                await docRef.update({'status': 'rejected', 'rejectReason': r.isEmpty ? 'الملعب غير متاح لهذا الوقت' : r});
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('تأكيد الرفض', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddManualSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: FullAddBookingSheet(pitchName: widget.pitchName),
      ),
    );
  }
}

// -------------------------------------------------------------
// واجهة اللاعب الرئيسية (مع نظام إخفاء الشارة فور الدخول)
// -------------------------------------------------------------
class PlayerMainScreen extends StatefulWidget {
  final String playerPhone;
  const PlayerMainScreen({super.key, required this.playerPhone});

  @override
  State<PlayerMainScreen> createState() => _PlayerMainScreenState();
}

class _PlayerMainScreenState extends State<PlayerMainScreen> {
  int _currentIndex = 0;
  List<String> _favPitches = [];
  bool _matchesBadgeSeen = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favPitches = prefs.getStringList('fav_pitches') ?? [];
    });
  }

  Future<void> _toggleFavorite(String pitchName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favPitches.contains(pitchName)) {
        _favPitches.remove(pitchName);
      } else {
        _favPitches.add(pitchName);
      }
    });
    await prefs.setStringList('fav_pitches', _favPitches);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('phone', isEqualTo: widget.playerPhone).snapshots(),
      builder: (context, snapshot) {
        int updatesCount = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final st = (doc.data() as Map<String, dynamic>)['status'];
            if (st == 'upcoming' || st == 'rejected') updatesCount++;
          }
        }

        // إخفاء الشارة عند دخول اللاعب لتبويب مبارياتي
        final showMatchBadge = !_matchesBadgeSeen && updatesCount > 0;

        final pages = [
          PlayerExplorePitchesTab(
            favPitches: _favPitches,
            onToggleFav: _toggleFavorite,
            playerPhone: widget.playerPhone,
          ),
          PlayerFavoritesTab(
            favPitches: _favPitches,
            onToggleFav: _toggleFavorite,
            playerPhone: widget.playerPhone,
          ),
          PlayerMyBookingsTab(playerPhone: widget.playerPhone),
          PlayerProfileTab(playerPhone: widget.playerPhone),
        ];

        return Scaffold(
          body: pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF1B5E20),
            unselectedItemColor: Colors.grey,
            onTap: (idx) {
              setState(() {
                _currentIndex = idx;
                if (idx == 2) {
                  _matchesBadgeSeen = true; // مسح الإشعار فور الضغط عليه
                }
              });
            },
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'استكشاف'),
              const BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'المفضلة'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: showMatchBadge,
                  label: Text('$updatesCount', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.sports_soccer),
                ),
                label: 'مبارياتي',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'بروفايلي'),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// تبويب استكشاف الملاعب
// -------------------------------------------------------------
class PlayerExplorePitchesTab extends StatefulWidget {
  final List<String> favPitches;
  final Function(String) onToggleFav;
  final String playerPhone;

  const PlayerExplorePitchesTab({super.key, required this.favPitches, required this.onToggleFav, required this.playerPhone});

  @override
  State<PlayerExplorePitchesTab> createState() => _PlayerExplorePitchesTabState();
}

class _PlayerExplorePitchesTabState extends State<PlayerExplorePitchesTab> {
  String _selectedGov = 'بغداد';
  String _selectedArea = 'الكل';
  String _selectedPitchType = 'الكل';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final areas = iraqLocations[_selectedGov] ?? ['الكل'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('ملاعب كرة القدم', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGov,
                        decoration: const InputDecoration(labelText: 'المحافظة', isDense: true, border: OutlineInputBorder()),
                        items: iraqLocations.keys.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGov = val;
                              _selectedArea = 'الكل';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedArea,
                        decoration: const InputDecoration(labelText: 'المنطقة', isDense: true, border: OutlineInputBorder()),
                        items: areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedArea = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPitchType,
                        decoration: const InputDecoration(labelText: 'نوع الملعب', isDense: true, border: OutlineInputBorder()),
                        items: pitchTypesList.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPitchType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'اسم الملعب...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pitches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final gov = data['governorate'] ?? 'بغداد';
                  final area = data['area'] ?? '';
                  final pitchType = data['pitchType'] ?? 'سباعي (7 ضد 7)';
                  final name = (data['name'] ?? '').toString().toLowerCase();

                  final matchesGov = gov == _selectedGov;
                  final matchesArea = _selectedArea == 'الكل' || area == _selectedArea;
                  final matchesType = _selectedPitchType == 'الكل' || pitchType == _selectedPitchType;
                  final matchesSearch = name.contains(_search);

                  return matchesGov && matchesArea && matchesType && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'لا توجد ملاعب مطابقة للبحث في\n$_selectedGov - $_selectedArea (${_selectedPitchType == 'الكل' ? 'جميع الأحجام' : _selectedPitchType})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index].data() as Map<String, dynamic>;
                    final pitchName = data['name'] ?? 'ملعب';
                    final area = data['area'] ?? '';
                    final gov = data['governorate'] ?? '';
                    final pitchType = data['pitchType'] ?? 'ملعب سباعي';
                    final rate = (data['hourlyRate'] as num?)?.toDouble() ?? 15000.0;
                    final duration = data['matchDurationMinutes'] ?? 60;
                    final isFav = widget.favPitches.contains(pitchName);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.sports_soccer, color: Color(0xFF1B5E20))),
                        title: Text(pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$gov - $area  |  النوع: $pitchType', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('مدة المباراة: $duration دقيقة  |  السعر: ${rate.toInt()} د.ع', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                          onPressed: () => widget.onToggleFav(pitchName),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Directionality(
                                textDirection: ui.TextDirection.rtl,
                                child: PitchScheduleViewScreen(
                                  pitchName: pitchName,
                                  hourlyRate: rate,
                                  durationMinutes: duration,
                                  playerPhone: widget.playerPhone,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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

// -------------------------------------------------------------
// جدول المواعيد (مع منع اللاعب من قبول تحدي فريقه بنفسه)
// -------------------------------------------------------------
class PitchScheduleViewScreen extends StatefulWidget {
  final String pitchName;
  final double hourlyRate;
  final int durationMinutes;
  final String playerPhone;

  const PitchScheduleViewScreen({super.key, required this.pitchName, required this.hourlyRate, required this.durationMinutes, required this.playerPhone});

  @override
  State<PitchScheduleViewScreen> createState() => _PitchScheduleViewScreenState();
}

class _PitchScheduleViewScreenState extends State<PitchScheduleViewScreen> {
  DateTime _selectedDate = DateTime.now();

  List<String> _generateSlots() {
    final List<String> generated = [];
    DateTime start = DateTime(2026, 1, 1, 16, 0);
    final DateTime end = DateTime(2026, 1, 2, 1, 0);

    while (start.isBefore(end)) {
      final DateTime slotEnd = start.add(Duration(minutes: widget.durationMinutes));
      final sStr = DateFormat('hh:mm a').format(start).replaceAll('AM', 'ص').replaceAll('PM', 'م');
      final eStr = DateFormat('hh:mm a').format(slotEnd).replaceAll('AM', 'ص').replaceAll('PM', 'م');
      generated.add('$sStr - $eStr');
      start = slotEnd;
    }
    return generated;
  }

  String _getArabicDayName(DateTime date) {
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

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final currentDayArabic = _getArabicDayName(_selectedDate);
    final slots = _generateSlots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text('جدول ${widget.pitchName}', style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Text('اليوم: $currentDayArabic ($dateStr)', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('تغيير التاريخ'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('recurring_rules').where('pitchName', isEqualTo: widget.pitchName).where('dayOfWeek', isEqualTo: currentDayArabic).snapshots(),
              builder: (context, recurringSnap) {
                final recurringDocs = recurringSnap.data?.docs ?? [];
                final Map<String, String> recurringMap = {};
                for (var r in recurringDocs) {
                  final rd = r.data() as Map<String, dynamic>;
                  recurringMap[rd['timeSlot']] = rd['teamName'];
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).where('date', isEqualTo: dateStr).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data?.docs ?? [];
                    final Map<String, DocumentSnapshot> bookedMap = {};

                    for (var d in docs) {
                      final data = d.data() as Map<String, dynamic>;
                      final slotKey = '${data['startTime']} - ${data['endTime']}';
                      final st = data['status'];
                      if (st == 'upcoming' || st == 'pending' || st == 'completed') {
                        bookedMap[slotKey] = d;
                      }
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final bookingDoc = bookedMap[slot];
                        final recurringTeam = recurringMap[slot];

                        if (recurringTeam != null) {
                          return Card(
                            color: Colors.purple.shade50,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.lock_clock, color: Colors.purple),
                              title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('حجز أسبوعي ثابت لفريق: $recurringTeam'),
                              trailing: const Chip(label: Text('حجز دائم', style: TextStyle(color: Colors.purple, fontSize: 11))),
                            ),
                          );
                        }

                        if (bookingDoc == null) {
                          return Card(
                            color: Colors.green.shade50,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(Icons.check_circle, color: Colors.green.shade700),
                              title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('متاح للحجز الكامل (${widget.hourlyRate.toInt()} د.ع) أو طلب تحدي'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                                onPressed: () => _openBookingDialog(context, slot, dateStr),
                                child: const Text('حجز', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          );
                        }

                        final bData = bookingDoc.data() as Map<String, dynamic>;
                        final isLookingForOpponent = bData['teamTwo'] == 'بانتظار الخصم';
                        final creatorPhone = bData['phone'] ?? '';
                        final isMyOwnBooking = creatorPhone == widget.playerPhone; // التحقق من هوية صاحب الطلب

                        if (isLookingForOpponent) {
                          final halfPrice = widget.hourlyRate / 2;

                          return Card(
                            color: Colors.orange.shade50,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.flash_on, color: Colors.deepOrange),
                              title: Text('$slot (تحدي مفتوح!)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              subtitle: Text(
                                isMyOwnBooking
                                    ? 'هذا طلب فريقك (${bData['teamOne']})\nبانتظار انضمام فريق منافس'
                                    : 'فريق (${bData['teamOne']}) يبحث عن خصم!\nتكلفة فريقك: ${halfPrice.toInt()} د.ع (النصف فقط)',
                              ),
                              trailing: isMyOwnBooking
                                  ? OutlinedButton(
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () => _cancelMyChallenge(context, bookingDoc.reference),
                                      child: const Text('إلغاء طلبي'),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                                      onPressed: () => _acceptChallengeDialog(context, bookingDoc, bData),
                                      child: const Text('قبول التحدي', style: TextStyle(color: Colors.white)),
                                    ),
                            ),
                          );
                        } else {
                          return Card(
                            color: Colors.red.shade50,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.cancel, color: Colors.red),
                              title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('محجوز: ${bData['teamOne']} ⚔️ ${bData['teamTwo']}'),
                              trailing: const Chip(label: Text('محجوز', style: TextStyle(color: Colors.red))),
                            ),
                          );
                        }
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

  void _cancelMyChallenge(BuildContext context, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء طلب التحدي'),
          content: const Text('هل تريد سحب طلبك وإلغاء هذا الحجز؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await docRef.delete();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('نعم، إلغاء الحجز', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openBookingDialog(BuildContext context, String slot, String dateStr) {
    final teamCtrl = TextEditingController();
    final opponentCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: widget.playerPhone == 'owner_preview' ? '' : widget.playerPhone);
    bool hasOpponent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final fullPrice = widget.hourlyRate;
          final halfPrice = fullPrice / 2;
          final payablePrice = hasOpponent ? fullPrice : halfPrice;

          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: Text('طلب حجز ($slot)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: teamCtrl, decoration: const InputDecoration(labelText: 'اسم فريقك', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('عندي فريق خصم جاهز؟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      value: hasOpponent,
                      onChanged: (val) => setDlgState(() => hasOpponent = val),
                    ),
                    if (hasOpponent) ...[
                      const SizedBox(height: 8),
                      TextField(controller: opponentCtrl, decoration: const InputDecoration(labelText: 'اسم فريق الخصم', border: OutlineInputBorder())),
                    ],
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتفك للتأكيد', border: OutlineInputBorder())),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        hasOpponent
                            ? 'المبلغ الإجمالي للحجز: ${fullPrice.toInt()} د.ع'
                            : 'أنت تدفع النصف فقط: ${payablePrice.toInt()} د.ع\n(النصف الثاني يدفعه الخصم عند انضمامه)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                  onPressed: () async {
                    if (teamCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                      final times = slot.split(' - ');
                      await FirebaseFirestore.instance.collection('bookings').add({
                        'pitchName': widget.pitchName,
                        'teamOne': teamCtrl.text.trim(),
                        'teamTwo': hasOpponent ? opponentCtrl.text.trim() : 'بانتظار الخصم',
                        'startTime': times[0],
                        'endTime': times.length > 1 ? times[1] : '',
                        'phone': phoneCtrl.text.trim(),
                        'price': payablePrice,
                        'totalMatchPrice': fullPrice,
                        'date': dateStr,
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلبك بنجاح!'), backgroundColor: Colors.green));
                      }
                    }
                  },
                  child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _acceptChallengeDialog(BuildContext context, DocumentSnapshot doc, Map<String, dynamic> bData) {
    final opponentTeamCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: widget.playerPhone == 'owner_preview' ? '' : widget.playerPhone);
    final halfPrice = widget.hourlyRate / 2;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('قبول تحدي فريق (${bData['teamOne']})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: opponentTeamCtrl, decoration: const InputDecoration(labelText: 'اسم فريقك المنافس', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتفك للتأكيد', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Text('المبلغ المطلوب من فريقك: ${halfPrice.toInt()} د.ع فقط (نصف الحجز)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () async {
                if (opponentTeamCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  await doc.reference.update({
                    'teamTwo': opponentTeamCtrl.text.trim(),
                    'challengerPhone': phoneCtrl.text.trim(),
                    'price': widget.hourlyRate,
                  });

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الانضمام وإكمال المباراة بنجاح!'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('تأكيد وقبول التحدي', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// تبويب الملاعب المفضلة
// -------------------------------------------------------------
class PlayerFavoritesTab extends StatelessWidget {
  final List<String> favPitches;
  final Function(String) onToggleFav;
  final String playerPhone;

  const PlayerFavoritesTab({super.key, required this.favPitches, required this.onToggleFav, required this.playerPhone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('ملاعبي المفضلة', style: TextStyle(color: Colors.white)),
      ),
      body: favPitches.isEmpty
          ? const Center(child: Text('لم تضف أي ملعب للمفضلة بعد\nاضغط على رمز القلب عند أي ملعب لحفظه هنا', textAlign: TextAlign.center))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pitches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs.where((d) => favPitches.contains(d.id)).toList() ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'ملعب';
                    final area = data['area'] ?? '';
                    final gov = data['governorate'] ?? '';
                    final pitchType = data['pitchType'] ?? 'ملعب سباعي';
                    final rate = (data['hourlyRate'] as num?)?.toDouble() ?? 15000.0;
                    final duration = data['matchDurationMinutes'] ?? 60;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.stadium, color: Color(0xFF1B5E20), size: 36),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('$gov - $area | $pitchType | $rate د.ع'),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => onToggleFav(name),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Directionality(
                                textDirection: ui.TextDirection.rtl,
                                child: PitchScheduleViewScreen(
                                  pitchName: name,
                                  hourlyRate: rate,
                                  durationMinutes: duration,
                                  playerPhone: playerPhone,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// -------------------------------------------------------------
// تبويب طلبات ومباريات اللاعب
// -------------------------------------------------------------
class PlayerMyBookingsTab extends StatelessWidget {
  final String playerPhone;
  const PlayerMyBookingsTab({super.key, required this.playerPhone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('طلباتي ومبارياتي', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').where('phone', isEqualTo: playerPhone).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('لم تقم بإرسال أي طلبات حجز بعد'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final st = data['status'] ?? 'pending';
              final reason = data['rejectReason'] ?? '';

              Color color = Colors.orange;
              String statusTxt = 'قيد المراجعة والانتظار';
              if (st == 'upcoming') {
                color = Colors.green;
                statusTxt = 'تم التأكيد والموافقة!';
              } else if (st == 'completed') {
                color = Colors.blueGrey;
                statusTxt = 'مباراة منتهية ومكتملة';
              } else if (st == 'rejected') {
                color = Colors.red;
                statusTxt = 'تم الاعتذار / الرفض';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['pitchName'] ?? 'الملعب', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Chip(label: Text(statusTxt, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)), backgroundColor: color.withOpacity(0.1)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('التاريخ: ${data['date']}  |  الوقت: ${data['startTime']} - ${data['endTime']}'),
                      Text('المباراة: ${data['teamOne']} ⚔️ ${data['teamTwo']}'),
                      Text('المبلغ: ${data['price']} د.ع'),
                      if (st == 'rejected' && reason.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('سبب الرفض: $reason', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// شاشة بروفايل اللاعب
// -------------------------------------------------------------
class PlayerProfileTab extends StatelessWidget {
  final String playerPhone;
  const PlayerProfileTab({super.key, required this.playerPhone});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('ملفي الشخصي (كابتن)', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'تسجيل خروج',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('current_player_phone');
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('players').doc(playerPhone).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? 'كابتن الفريق';
          final team = data?['teamName'] ?? 'فريق غير محدد';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').where('phone', isEqualTo: playerPhone).snapshots(),
            builder: (context, bookingSnap) {
              int totalMatches = 0;
              double totalSpent = 0;

              if (bookingSnap.hasData) {
                totalMatches = bookingSnap.data!.docs.length;
                for (var b in bookingSnap.data!.docs) {
                  final bd = b.data() as Map<String, dynamic>;
                  if (bd['status'] == 'completed' || bd['status'] == 'upcoming') {
                    totalSpent += (bd['price'] as num?)?.toDouble() ?? 0.0;
                  }
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Color(0xFF1B5E20),
                      child: Icon(Icons.person, size: 55, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(team, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('رقم الهاتف: $playerPhone', style: const TextStyle(color: Colors.blueGrey)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.shade200)),
                            child: Column(
                              children: [
                                const Text('إجمالي المباريات', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text('$totalMatches', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.teal.shade200)),
                            child: Column(
                              children: [
                                const Text('مجموع المبالغ', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text('${currencyFormatter.format(totalSpent)} د.ع', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20)),
                      title: const Text('اسم الفريق المعتمد'),
                      subtitle: Text(team),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone_android, color: Color(0xFF1B5E20)),
                      title: const Text('رقم الهاتف للتواصل الميداني'),
                      subtitle: Text(playerPhone),
                    ),
                    const Divider(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('تسجيل خروج من الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('current_player_phone');
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// نموذج الحجز اليدوي المباشر
// -------------------------------------------------------------
class FullAddBookingSheet extends StatefulWidget {
  final String pitchName;
  const FullAddBookingSheet({super.key, required this.pitchName});

  @override
  State<FullAddBookingSheet> createState() => _FullAddBookingSheetState();
}

class _FullAddBookingSheetState extends State<FullAddBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _teamOneController = TextEditingController();
  final _teamTwoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController(text: '15000');
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 14),
              const Text('حجز موعد مباراة يدوي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _teamOneController, decoration: const InputDecoration(labelText: 'الفريق الأول', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'مطلوب' : null)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('⚔️')),
                  Expanded(child: TextFormField(controller: _teamTwoController, decoration: const InputDecoration(labelText: 'الفريق الثاني', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'مطلوب' : null)),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 90)));
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 8),
                      Text('التاريخ: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                        child: Text('البدء: ${_startTime.format(context)}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                        child: Text('الانتهاء: ${_endTime.format(context)}'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ (د.ع)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'ملاحظات إضافية', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await FirebaseFirestore.instance.collection('bookings').add({
                        'pitchName': widget.pitchName,
                        'teamOne': _teamOneController.text.trim(),
                        'teamTwo': _teamTwoController.text.trim(),
                        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
                        'startTime': _startTime.format(context),
                        'endTime': _endTime.format(context),
                        'phone': _phoneController.text.trim(),
                        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
                        'notes': _notesController.text.trim(),
                        'status': 'upcoming',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('تثبيت الحجز في السيرفر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
