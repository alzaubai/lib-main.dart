import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'owner_screen.dart';
import 'player_screen.dart';

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
