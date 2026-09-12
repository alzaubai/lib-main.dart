import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// -------------------------------------------------------------
// قاعدة البيانات الجغرافية للمحافظات والمناطق
// -------------------------------------------------------------
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
  }
  runApp(const PitchBookingApp());
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
// الشاشة الرئيسية لاختيار الحساب (صاحب ملعب أو لاعب)
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
              const Text(
                'تطبيق مَلعَبي',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 6),
              const Text(
                'المنصة الرياضية لحجز وتنظيم مباريات كرة القدم',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.stadium),
                label: const Text('دخول كصاحب ملعب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _openOwnerLoginModal(context),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.app_registration),
                label: const Text('تسجيل ملعب جديد لأول مرة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: () => _openOwnerRegisterModal(context),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('أو', style: TextStyle(color: Colors.grey))),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.person_pin),
                label: const Text('دخول كالاعب / فريق (حجز وتحدي)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _openPlayerLoginModal(context),
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
                            decoration: const InputDecoration(labelText: 'المنطقة / القضاء', border: OutlineInputBorder()),
                            items: dists.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedDist = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر الساعة للملعب (د.ع)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
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
                            'phone': phone,
                            'pin': pin,
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
    final nameCtrl = TextEditingController();
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
              const Text('دخول سريع للاعب / كابتن الفريق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الكابتن أو الفريق', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 10),
              TextField(controller: pinCtrl, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'رمز PIN سريع (4 أرقام)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final phone = phoneCtrl.text.trim();
                  final name = nameCtrl.text.trim();
                  final pin = pinCtrl.text.trim();

                  if (phone.isNotEmpty && pin.length == 4) {
                    await FirebaseFirestore.instance.collection('players').doc(phone).set({
                      'name': name.isEmpty ? 'كابتن' : name,
                      'phone': phone,
                      'pin': pin,
                      'lastLogin': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('current_player_phone', phone);
                    await prefs.setString('current_player_name', name);

                    if (mounted) {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: ui.TextDirection.rtl, child: PlayerMainScreen(playerPhone: phone))));
                    }
                  }
                },
                child: const Text('دخول واستعراض الملاعب', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// لوحة تحكم صاحب الملعب (مع الشارات الحمراء وقبول/رفض مع السبب)
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, pendingSnapshot) {
        final pendingCount = pendingSnapshot.data?.docs.length ?? 0;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B5E20),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pitchName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('لوحة إدارة الحجوزات السحابية', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                tooltip: 'معاينة كلاعب',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const Directionality(textDirection: ui.TextDirection.rtl, child: PlayerMainScreen(playerPhone: 'owner_preview'))));
                },
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
                const Tab(icon: Icon(Icons.event_available), text: 'المباريات المؤكدة'),
                Tab(
                  icon: Badge(
                    isLabelVisible: pendingCount > 0,
                    label: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.notifications_active),
                  ),
                  text: 'الطلبات المعلقة',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildConfirmedTab(currencyFormatter),
              _buildPendingTab(pendingSnapshot),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('حجز موعد يدوي', style: TextStyle(fontWeight: FontWeight.bold)),
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
        final now = DateTime.now();
        double todayRevenue = 0.0;
        int todayMatches = 0;

        for (var doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final date = DateTime.tryParse(d['date'] ?? '') ?? now;
          final price = (d['price'] as num?)?.toDouble() ?? 0.0;

          if (date.year == now.year && date.month == now.month && date.day == now.day) {
            todayMatches++;
            todayRevenue += price;
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
                          const Text('وارد اليوم', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${currencyFormatter.format(todayRevenue)} د.ع', style: const TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('مباريات اليوم', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$todayMatches مباريات', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? const Center(child: Text('لا توجد حجوزات مؤكدة'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final isDone = data['status'] == 'completed';
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: isDone ? Colors.grey.shade200 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text(isDone ? 'مكتملة' : 'مؤكدة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDone ? Colors.grey.shade700 : Colors.green.shade800)),
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
                                      IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => _launchCall(phone)),
                                      IconButton(icon: const Icon(Icons.message, color: Colors.teal), onPressed: () => _launchWhatsApp(phone)),
                                    ],
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => doc.reference.update({'status': isDone ? 'upcoming' : 'completed'}),
                                      icon: Icon(isDone ? Icons.undo : Icons.check, size: 18),
                                      label: Text(isDone ? 'إعادة' : 'إكمال'),
                                    ),
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
                      IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => _launchCall(phone)),
                      IconButton(icon: const Icon(Icons.message, color: Colors.teal), onPressed: () => _launchWhatsApp(phone)),
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
// واجهة اللاعب الرئيسية (تنقل سفلي: استكشاف، مفضلة، طلباتي)
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
        ];

        return Scaffold(
          body: pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFF1B5E20),
            onTap: (idx) => setState(() => _currentIndex = idx),
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'استكشاف الملاعب'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: _favPitches.isNotEmpty,
                  label: Text('${_favPitches.length}'),
                  child: const Icon(Icons.favorite),
                ),
                label: 'المفضلة',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: updatesCount > 0,
                  label: Text('$updatesCount', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.sports_soccer),
                ),
                label: 'طلباتي ومبارياتي',
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// تبويب استكشاف الملاعب مع فلاتر المحافظة والمنطقة
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
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final areas = iraqLocations[_selectedGov] ?? ['الكل'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('ملاعب كرة القدم', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'تبديل الحساب',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('current_player_phone');
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
              }
            },
          ),
        ],
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
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الملعب...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
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
                  final name = (data['name'] ?? '').toString().toLowerCase();

                  final matchesGov = gov == _selectedGov;
                  final matchesArea = _selectedArea == 'الكل' || area == _selectedArea;
                  final matchesSearch = name.contains(_search);

                  return matchesGov && matchesArea && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('لا توجد ملاعب مسجلة في $_selectedGov - $_selectedArea حتى الآن', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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
                    final rate = data['hourlyRate'] ?? 15000;
                    final isFav = widget.favPitches.contains(pitchName);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.sports_soccer, color: Color(0xFF1B5E20))),
                        title: Text(pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$gov - $area', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('سعر الساعة: $rate د.ع  (النصف: ${rate / 2} د.ع)', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                  hourlyRate: (rate as num).toDouble(),
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
        title: const Text('ملاعبي المفضلة (❤️)', style: TextStyle(color: Colors.white)),
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
                    final rate = (data['hourlyRate'] as num?)?.toDouble() ?? 15000.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.stadium, color: Color(0xFF1B5E20), size: 36),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('$gov - $area | $rate د.ع/ساعة'),
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
// جدول مواعيد الملعب + نظام التحدي وحساب النصف / الحجز الكامل
// -------------------------------------------------------------
class PitchScheduleViewScreen extends StatefulWidget {
  final String pitchName;
  final double hourlyRate;
  final String playerPhone;

  const PitchScheduleViewScreen({super.key, required this.pitchName, required this.hourlyRate, required this.playerPhone});

  @override
  State<PitchScheduleViewScreen> createState() => _PitchScheduleViewScreenState();
}

class _PitchScheduleViewScreenState extends State<PitchScheduleViewScreen> {
  DateTime _selectedDate = DateTime.now();

  // فترات الحجز (مدة كل مباراة ساعة ونصف)
  final slots = [
    '05:00 م - 06:30 م',
    '06:30 م - 08:00 م',
    '08:00 م - 09:30 م',
    '09:30 م - 11:00 م',
    '11:00 م - 12:30 ص',
  ];

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

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
                Text('اليوم: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('pitchName', isEqualTo: widget.pitchName)
                  .where('date', isEqualTo: dateStr)
                  .snapshots(),
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

                    if (bookingDoc == null) {
                      // متاح بالكامل (أخضر)
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

                    if (isLookingForOpponent) {
                      // يبحث عن خصم (برتقالي / ذهبي)
                      final halfPrice = widget.hourlyRate / 2;
                      return Card(
                        color: Colors.orange.shade50,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.flash_on, color: Colors.deepOrange),
                          title: Text('$slot (تحدي مفتوح!)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          subtitle: Text('فريق (${bData['teamOne']}) يبحث عن خصم!\nتكلفة فريقك: ${halfPrice.toInt()} د.ع (النصف فقط)'),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                            onPressed: () => _acceptChallengeDialog(context, bookingDoc, bData),
                            child: const Text('قبول التحدي', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                    } else {
                      // مقفول بالكامل (أحمر)
                      return Card(
                        color: Colors.red.shade50,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.cancel, color: Colors.red),
                          title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('محجوز بالكامل: ${bData['teamOne']} ⚔️ ${bData['teamTwo']}'),
                          trailing: const Chip(label: Text('محجوز', style: TextStyle(color: Colors.red))),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
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
// تبويب طلبات اللاعب ومبارياته مع توضيح سبب الرفض
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
// نموذج الحجز اليدوي المباشر لصاحب الملعب
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
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 30);

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
