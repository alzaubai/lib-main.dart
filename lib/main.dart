import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
// الشاشة الرئيسية لاختيار الدور وتسجيل الدخول
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
    _checkActiveLogin();
  }

  Future<void> _checkActiveLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPitch = prefs.getString('current_pitch_name');
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
                'منصة إدارة وحجوزات الملاعب',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 8),
              const Text(
                'سجل كصاحب ملعب لإدارة الحجوزات أو تصفح الملاعب كلاعب',
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
                icon: const Icon(Icons.login),
                label: const Text('دخول صاحب ملعب (برقم الهاتف والرمز)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
              const Divider(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.search),
                label: const Text('دخول كلاعب (استعراض الملاعب وحجز)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف المسجل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'رمز PIN (4 أرقام)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final phone = phoneCtrl.text.trim();
                  final pin = pinCtrl.text.trim();

                  final query = await FirebaseFirestore.instance
                      .collection('pitches')
                      .where('phone', isEqualTo: phone)
                      .where('pin', isEqualTo: pin)
                      .limit(1)
                      .get();

                  if (query.docs.isNotEmpty) {
                    final pitchData = query.docs.first.data();
                    final pitchName = pitchData['name'] as String;

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('current_pitch_name', pitchName);

                    if (mounted) {
                      Navigator.pop(ctx);
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('رقم الهاتف أو الرمز السري غير صحيح'), backgroundColor: Colors.red),
                    );
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
    final areaCtrl = TextEditingController();
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
                const Text('تسجيل ملعب جديد في المنصة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                const SizedBox(height: 14),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الملعب (مثال: ملعب النخيل)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'المنطقة (مثال: أبو غريب، الكرخ، إلخ)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتف الحجز والتواصل', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: pinCtrl, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'اختر رمز PIN للدخول (4 أرقام)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final area = areaCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final pin = pinCtrl.text.trim();

                    if (name.isNotEmpty && area.isNotEmpty && phone.isNotEmpty && pin.length == 4) {
                      await FirebaseFirestore.instance.collection('pitches').doc(name).set({
                        'name': name,
                        'area': area,
                        'phone': phone,
                        'pin': pin,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('current_pitch_name', name);

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
                  child: const Text('تثبيت الحساب والملعب', style: TextStyle(color: Colors.white, fontSize: 16)),
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
// لوحة تحكم صاحب الملعب (إدارة، طلبات معلقة، سبب الرفض، والتبديل)
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
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pitchName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('لوحة إدارة الملعب السحابية', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white),
            tooltip: 'معاينة كلاعب',
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'تبديل أو خروج',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('current_pitch_name');
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'المباريات المؤكدة'),
            Tab(icon: Icon(Icons.pending_actions), text: 'الطلبات المعلقة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfirmedBookingsTab(currencyFormatter),
          _buildPendingRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('حجز يدوي جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openFullAddBookingSheet(context),
      ),
    );
  }

  Widget _buildConfirmedBookingsTab(NumberFormat currencyFormatter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('pitchName', isEqualTo: widget.pitchName)
          .where('status', whereIn: ['upcoming', 'completed'])
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

          if (date.year == now.year && date.month == now.month && date.day == now.day) {
            todayBookingsCount++;
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
                  ? const Center(child: Text('لا توجد حجوزات مؤكدة حالياً'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final isCompleted = data['status'] == 'completed';
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
                                      decoration: BoxDecoration(
                                        color: isCompleted ? Colors.grey.shade200 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isCompleted ? 'مكتملة' : 'مؤكدة',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCompleted ? Colors.grey.shade700 : Colors.green.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${data['teamOne']} ⚔️ ${data['teamTwo']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Text('${data['startTime']} إلى ${data['endTime']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Text('${currencyFormatter.format(data['price'] ?? 0)} د.ع', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('ملاحظات: ${data['notes']}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    if (phone.toString().isNotEmpty) ...[
                                      IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => _launchCall(phone)),
                                      IconButton(icon: const Icon(Icons.message, color: Colors.teal), onPressed: () => _launchWhatsApp(phone)),
                                    ],
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => doc.reference.update({'status': isCompleted ? 'upcoming' : 'completed'}),
                                      icon: Icon(isCompleted ? Icons.undo : Icons.check, size: 18),
                                      label: Text(isCompleted ? 'إعادة' : 'إكمال'),
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

  Widget _buildPendingRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('pitchName', isEqualTo: widget.pitchName)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('لا توجد طلبات حجز معلقة حالياً'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final phone = data['phone'] ?? '';

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
                        const Chip(label: Text('طلب معلق', style: TextStyle(color: Colors.orange, fontSize: 11))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('فريق الحجز: ${data['teamOne']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('الوقت المطلوب: ${data['startTime']} - ${data['endTime']}'),
                    Text('رقم الهاتف: $phone'),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
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
                          onPressed: () => _showRejectReasonDialog(context, doc.reference),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                          icon: const Icon(Icons.check, size: 16, color: Colors.white),
                          label: const Text('قبول وتثبيت', style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            doc.reference.update({'status': 'upcoming'});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRejectReasonDialog(BuildContext context, DocumentReference docRef) {
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
            decoration: const InputDecoration(
              labelText: 'اكتب سبب الرفض (مثال: صيانة إنارة، أو الملعب محجوز مسبقاً)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                await docRef.update({
                  'status': 'rejected',
                  'rejectReason': reason.isEmpty ? 'تم الاعتذار لتعارض الوقت' : reason,
                });
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('تأكيد الرفض', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullAddBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: FullAddBookingSheet(pitchName: widget.pitchName),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// نافذة الحجز اليدوي المباشر لصاحب الملعب
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
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 30);

  @override
  void dispose() {
    _teamOneController.dispose();
    _teamTwoController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          _endTime = TimeOfDay(hour: (picked.hour + 1) % 24, minute: (picked.minute + 30) % 60);
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              const Text('حجز موعد مباراة جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _teamOneController,
                      decoration: InputDecoration(labelText: 'الفريق الأول', prefixIcon: const Icon(Icons.shield_outlined, color: Colors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('⚔️', style: TextStyle(fontSize: 18))),
                  Expanded(
                    child: TextFormField(
                      controller: _teamTwoController,
                      decoration: InputDecoration(labelText: 'الفريق الثاني', prefixIcon: const Icon(Icons.shield, color: Colors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 10),
                      Text('التاريخ: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Text('تغيير', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isStart: true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('وقت البدء', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(_startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isStart: false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('وقت الانتهاء', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(_endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: 'رقم هاتف الحجز', prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'السعر (د.ع)', prefixIcon: const Icon(Icons.payments_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(labelText: 'ملاحظات إضافية', prefixIcon: const Icon(Icons.edit_note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _submit,
                  child: const Text('حفظ الحجز وتثبيته', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// واجهة اللاعب: البحث والمفضلة وسجل الطلبات
// -------------------------------------------------------------
class PlayerPitchesListScreen extends StatefulWidget {
  const PlayerPitchesListScreen({super.key});

  @override
  State<PlayerPitchesListScreen> createState() => _PlayerPitchesListScreenState();
}

class _PlayerPitchesListScreenState extends State<PlayerPitchesListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedArea = 'الكل';
  List<String> _favoritePitches = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritePitches = prefs.getStringList('fav_pitches') ?? [];
    });
  }

  Future<void> _toggleFavorite(String pitchName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoritePitches.contains(pitchName)) {
        _favoritePitches.remove(pitchName);
      } else {
        _favoritePitches.add(pitchName);
      }
    });
    await prefs.setStringList('fav_pitches', _favoritePitches);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('الملاعب المتوفرة للحجز', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'سجل طلباتي والردود',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: PlayerMyRequestsScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('pitches').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final allAreas = <String>{'الكل'};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['area'] != null && (data['area'] as String).isNotEmpty) {
              allAreas.add(data['area']);
            }
          }

          final filteredList = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final area = (data['area'] ?? '').toString();

            final matchesSearch = name.contains(_searchQuery.toLowerCase());
            final matchesArea = _selectedArea == 'الكل' || area == _selectedArea;

            return matchesSearch && matchesArea;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم الملعب أو المنطقة...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: allAreas.map((area) {
                    final isSelected = _selectedArea == area;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ChoiceChip(
                        label: Text(area),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedArea = area);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredList.isEmpty
                    ? const Center(child: Text('لا توجد ملاعب مطابقة للبحث'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final data = filteredList[index].data() as Map<String, dynamic>;
                          final pitchName = data['name'] ?? 'ملعب';
                          final pitchArea = data['area'] ?? 'غير محدد';
                          final isFav = _favoritePitches.contains(pitchName);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE8F5E9),
                                child: Icon(Icons.sports_soccer, color: Color(0xFF1B5E20)),
                              ),
                              title: Text(pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(pitchArea, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                                    onPressed: () => _toggleFavorite(pitchName),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
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
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// جدول مواعيد الملعب للاعب مع خيار اختيار الأيام القادمة
// -------------------------------------------------------------
class PitchScheduleViewScreen extends StatefulWidget {
  final String pitchName;
  const PitchScheduleViewScreen({super.key, required this.pitchName});

  @override
  State<PitchScheduleViewScreen> createState() => _PitchScheduleViewScreenState();
}

class _PitchScheduleViewScreenState extends State<PitchScheduleViewScreen> {
  DateTime _selectedDate = DateTime.now();

  final slots = [
    '05:00 م - 06:30 م',
    '06:30 م - 08:00 م',
    '08:00 م - 09:30 م',
    '09:30 م - 11:00 م',
    '11:00 م - 12:30 ص',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text('جدول ${widget.pitchName}', style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Text('اليوم: $selectedDateStr', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: const Text('تغيير اليوم'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('pitchName', isEqualTo: widget.pitchName)
                  .where('date', isEqualTo: selectedDateStr)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final bookedSlots = <String>{};
                for (var d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final status = data['status'];
                  if (status == 'upcoming' || status == 'completed') {
                    bookedSlots.add('${data['startTime']} - ${data['endTime']}');
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isBooked = bookedSlots.contains(slot);

                    return Card(
                      color: isBooked ? Colors.red.shade50 : Colors.green.shade50,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          isBooked ? Icons.cancel : Icons.check_circle,
                          color: isBooked ? Colors.red : Colors.green.shade700,
                        ),
                        title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(isBooked ? 'هذا الوقت محجوز' : 'متاح للحجز الآن'),
                        trailing: isBooked
                            ? const Chip(label: Text('محجوز', style: TextStyle(color: Colors.red)))
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                                onPressed: () => _sendBookingRequest(context, slot, selectedDateStr),
                                child: const Text('طلب حجز', style: TextStyle(color: Colors.white)),
                              ),
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

  void _sendBookingRequest(BuildContext context, String slot, String dateStr) {
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
                  final times = slot.split(' - ');

                  await FirebaseFirestore.instance.collection('bookings').add({
                    'pitchName': widget.pitchName,
                    'teamOne': t1.text.trim(),
                    'teamTwo': 'بانتظار الخصم',
                    'startTime': times.isNotEmpty ? times[0] : slot,
                    'endTime': times.length > 1 ? times[1] : '',
                    'phone': phone.text.trim(),
                    'price': 35000.0,
                    'date': dateStr,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('player_last_phone', phone.text.trim());

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال طلب الحجز إلى صاحب الملعب بنجاح!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// شاشة سجل طلبات اللاعب وحالة القبول / سبب الرفض
// -------------------------------------------------------------
class PlayerMyRequestsScreen extends StatefulWidget {
  const PlayerMyRequestsScreen({super.key});

  @override
  State<PlayerMyRequestsScreen> createState() => _PlayerMyRequestsScreenState();
}

class _PlayerMyRequestsScreenState extends State<PlayerMyRequestsScreen> {
  String _myPhone = '';

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myPhone = prefs.getString('player_last_phone') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('سجل طلباتي وحالتها', style: TextStyle(color: Colors.white)),
      ),
      body: _myPhone.isEmpty
          ? const Center(child: Text('لم ترسل أي طلبات حجز بعد'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('phone', isEqualTo: _myPhone)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات مسجلة برقمك'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final rejectReason = data['rejectReason'] ?? '';

                    Color statusColor = Colors.orange;
                    String statusText = 'قيد المراجعة';
                    if (status == 'upcoming') {
                      statusColor = Colors.green;
                      statusText = 'تم تأكيد الحجز';
                    } else if (status == 'rejected') {
                      statusColor = Colors.red;
                      statusText = 'تم الاعتذار/الرفض';
                    }

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
                                Text(data['pitchName'] ?? 'الملعب', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Chip(
                                  label: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                  backgroundColor: statusColor.withOpacity(0.1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('التاريخ: ${data['date']} | الوقت: ${data['startTime']} - ${data['endTime']}'),
                            if (status == 'rejected' && rejectReason.toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Text('سبب الرفض: $rejectReason', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
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
