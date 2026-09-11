import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'إدارة وحجز الملاعب',
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
        cardTheme: CardThemeData(
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

// شاشة اختيار الدور (صاحب ملعب أو زبون/لاعب)
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();
    _checkSavedPitch();
  }

  Future<void> _checkSavedPitch() async {
    final prefs = await SharedPreferences.getInstance();
    final pitchName = prefs.getString('my_pitch_name');
    if (pitchName != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: OwnerDashboardScreen(pitchName: pitchName),
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.sports_soccer, size: 90, color: Color(0xFF1B5E20)),
              const SizedBox(height: 16),
              const Text(
                'منصة حجوزات الملاعب',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر طريقة الدخول للاستمرار',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.stadium),
                label: const Text('أنا صاحب ملعب (إدارة وحسابات)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _showPitchRegisterDialog(context);
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.person_search),
                label: const Text('أنا لاعب (استعراض الملاعب وحجز موعد)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: PlayerPitchesListScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPitchRegisterDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل اسم الملعب'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'اسم الملعب (مثال: ملعب النجوم)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('my_pitch_name', name);
                  if (mounted) {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Directionality(
                          textDirection: ui.TextDirection.rtl,
                          child: OwnerDashboardScreen(pitchName: name),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('دخول', style: TextStyle(color: Colors.white)),
            ),
          ],
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

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pitchName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('لوحة إدارة الحجوزات السحابية', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'تبديل الحساب',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('my_pitch_name');
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .where('pitchName', isEqualTo: widget.pitchName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final now = DateTime.now();

          double todayRevenue = 0.0;
          int todayBookingsCount = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = DateTime.tryParse(data['date'] ?? '') ?? now;
            final price = (data['price'] as num?)?.toDouble() ?? 0.0;
            final isCompleted = data['status'] == 'completed';

            if (date.year == now.year && date.month == now.month && date.day == now.day) {
              todayBookingsCount++;
              if (isCompleted || data['status'] == 'upcoming') {
                todayRevenue += price;
              }
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
                            const Text('حجوزات اليوم', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('$todayBookingsCount مباريات', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('لا توجد حجوزات مسجلة حتى الآن'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isDone = data['status'] == 'completed';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDone ? Colors.grey.shade300 : Colors.green.shade100,
                                child: Icon(Icons.sports_soccer, color: isDone ? Colors.grey : Colors.green.shade800),
                              ),
                              title: Text('${data['teamOne']} ⚔️ ${data['teamTwo']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('الوقت: ${data['time'] ?? ''} | التاريخ: ${data['date'] ?? ''}\nالمبلغ: ${data['price'] ?? 0} د.ع - هاتف: ${data['phone'] ?? 'بدون'}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => doc.reference.delete(),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('حجز يدوي جديد'),
        onPressed: () => _openAddDialog(context),
      ),
    );
  }

  void _openAddDialog(BuildContext context) {
    final t1 = TextEditingController();
    final t2 = TextEditingController();
    final phone = TextEditingController();
    final price = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تسجيل حجز مباراة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 12),
              TextField(controller: t1, decoration: const InputDecoration(labelText: 'الفريق الأول', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: t2, decoration: const InputDecoration(labelText: 'الفريق الثاني', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر (د.ع)', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), minimumSize: const Size.fromHeight(48)),
                onPressed: () async {
                  if (t1.text.isNotEmpty && t2.text.isNotEmpty) {
                    final now = DateTime.now();
                    await _firestore.collection('bookings').add({
                      'pitchName': widget.pitchName,
                      'teamOne': t1.text.trim(),
                      'teamTwo': t2.text.trim(),
                      'phone': phone.text.trim(),
                      'price': double.tryParse(price.text.trim()) ?? 0.0,
                      'date': DateFormat('yyyy-MM-dd').format(now),
                      'time': 'حسب الطلب',
                      'status': 'upcoming',
                    });
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('حفظ الحجز سحابياً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// واجهة اللاعب/الزبون: استعراض الملاعب والأوقات المتاحة
// -------------------------------------------------------------
class PlayerPitchesListScreen extends StatelessWidget {
  const PlayerPitchesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('الملاعب المتاحة للحجز', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final Set<String> pitches = {};
          for (var d in docs) {
            final name = (d.data() as Map<String, dynamic>)['pitchName'] as String?;
            if (name != null && name.isNotEmpty) pitches.add(name);
          }

          if (pitches.isEmpty) {
            return const Center(child: Text('لا توجد ملاعب مضافة حالياً. سجل كصاحب ملعب وأضف أول حجز!'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: pitches.map((pitchName) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.stadium, color: Color(0xFF1B5E20), size: 36),
                  title: Text(pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('اضغط لمشاهدة المواعيد وطلب الحجز'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Directionality(
                          textDirection: ui.TextDirection.rtl,
                          child: PitchScheduleViewScreen(pitchName: pitchName),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class PitchScheduleViewScreen extends StatelessWidget {
  final String pitchName;
  const PitchScheduleViewScreen({super.key, required this.pitchName});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final slots = [
      '05:00 م - 06:30 م',
      '06:30 م - 08:00 م',
      '08:00 م - 09:30 م',
      '09:30 م - 11:00 م',
      '11:00 م - 12:30 ص',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text('جدول $pitchName اليوم', style: const TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('bookings')
            .where('pitchName', isEqualTo: pitchName)
            .where('date', isEqualTo: todayStr)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final bookedTimes = docs.map((d) => (d.data() as Map<String, dynamic>)['time'] ?? '').toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isBooked = bookedTimes.contains(slot);

              return Card(
                color: isBooked ? Colors.red.shade50 : Colors.green.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    isBooked ? Icons.cancel : Icons.check_circle,
                    color: isBooked ? Colors.red : Colors.green.shade700,
                  ),
                  title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isBooked ? 'هذا الوقت محجوز بالفعل' : 'متاح للحجز الآن'),
                  trailing: isBooked
                      ? const Chip(label: Text('محجوز', style: TextStyle(color: Colors.red)))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                          onPressed: () => _sendBookingRequest(context, slot),
                          child: const Text('احجز', style: TextStyle(color: Colors.white)),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _sendBookingRequest(BuildContext context, String slot) {
    final t1 = TextEditingController();
    final phone = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('طلب حجز موعد ($slot)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: t1, decoration: const InputDecoration(labelText: 'اسم فريقك', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتفك للتأكيد', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                if (t1.text.isNotEmpty && phone.text.isNotEmpty) {
                  final now = DateTime.now();
                  await FirebaseFirestore.instance.collection('bookings').add({
                    'pitchName': pitchName,
                    'teamOne': t1.text.trim(),
                    'teamTwo': 'في انتظار الخصم',
                    'phone': phone.text.trim(),
                    'price': 35000.0,
                    'date': DateFormat('yyyy-MM-dd').format(now),
                    'time': slot,
                    'status': 'upcoming',
                  });
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال وتثبيت الحجز بنجاح!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('تأكيد الحجز', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
