import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import 'auth_screen.dart';
import 'tournaments/tournament_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final String pitchName;
  const OwnerDashboardScreen({super.key, required this.pitchName});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _lastSeenPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingSeenCache();
    _tabController.addListener(() {
      setState(() {});
      if (_tabController.index == 1) {
        _markPendingAsSeen();
      }
    });
  }

  Future<void> _loadPendingSeenCache() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSeenPendingCount = prefs.getInt('owner_pending_seen_${widget.pitchName}') ?? 0;
    });
  }

  Future<void> _markPendingAsSeen() async {
    final query = await _firestore.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).where('status', isEqualTo: 'pending').get();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('owner_pending_seen_${widget.pitchName}', query.docs.length);
    setState(() {
      _lastSeenPendingCount = query.docs.length;
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
        final hasUnreadPending = pendingCount > _lastSeenPendingCount;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B5E20),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pitchName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('إدارة الحجوزات والاشتراكات والبطولات', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.emoji_events, color: Colors.amberAccent),
                tooltip: 'تنظيم البطولات والدوريات',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TournamentScreen(
                        userPhone: 'owner',
                        isOwner: true,
                        pitchName: widget.pitchName,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'إعدادات وبيانات الملعب',
                onPressed: () => _openPitchSettingsModal(context),
              ),
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
                    isLabelVisible: hasUnreadPending,
                    label: Text('${pendingCount - _lastSeenPendingCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          floatingActionButton: _tabController.index == 0
              ? FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('حجز موعد يدوي', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _openAddManualSheet(context),
                )
              : (_tabController.index == 2
                  ? FloatingActionButton.extended(
                      backgroundColor: Colors.purple.shade800,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add_task),
                      label: const Text('إضافة حجز أسبوعي ثابت', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _openAddRecurringDialog(context),
                    )
                  : null),
        );
      },
    );
  }

  void _openPitchSettingsModal(BuildContext context) async {
    final doc = await _firestore.collection('pitches').doc(widget.pitchName).get();
    if (!doc.exists || !mounted) return;

    final data = doc.data() as Map<String, dynamic>;
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');
    final rateCtrl = TextEditingController(text: '${data['hourlyRate']?.toInt() ?? 15000}');
    final pinCtrl = TextEditingController(text: data['pin'] ?? '');
    String currentType = data['pitchType'] ?? 'سباعي (7 ضد 7)';
    if (!pitchTypesList.contains(currentType) || currentType == 'الكل') {
      currentType = 'سباعي (7 ضد 7)';
    }

    double? currentLat = (data['latitude'] as num?)?.toDouble();
    double? currentLng = (data['longitude'] as num?)?.toDouble();
    bool isLocating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 8),
                      Text('إعدادات ملعب (${widget.pitchName})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم هاتف التواصل والحجز', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'سعر الحجز للمباراة (د.ع)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: currentType,
                    decoration: const InputDecoration(labelText: 'نوع وحجم الملعب', border: OutlineInputBorder()),
                    items: pitchTypesList.where((t) => t != 'الكل').map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => currentType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(labelText: 'رمز PIN للدخول (4 أرقام)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              currentLat != null ? 'الموقع محدد ومثبت على الخريطة' : 'لم يتم تحديد موقع الملعب بعد',
                              style: TextStyle(fontWeight: FontWeight.bold, color: currentLat != null ? Colors.green.shade800 : Colors.brown),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('اضغط الزر بالأسفل وأنت داخل الملعب ليتم سحب إحداثيات الـ GPS فورياً وتثبيتها للاعبين:', style: TextStyle(fontSize: 12, color: Colors.black87)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                          icon: isLocating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.my_location),
                          label: Text(isLocating ? 'جاري قراءة القمر الصناعي...' : (currentLat != null ? 'تحديث موقع الملعب الحالي' : 'تحديد موقع الملعب الحالي عبر GPS')),
                          onPressed: isLocating
                              ? null
                              : () async {
                                  setModalState(() => isLocating = true);
                                  try {
                                    LocationPermission perm = await Geolocator.checkPermission();
                                    if (perm == LocationPermission.denied) {
                                      perm = await Geolocator.requestPermission();
                                    }
                                    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب إعطاء إذن الموقع لتحديد مكان الملعب')));
                                      setModalState(() => isLocating = false);
                                      return;
                                    }
                                    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                    setModalState(() {
                                      currentLat = pos.latitude;
                                      currentLng = pos.longitude;
                                      isLocating = false;
                                    });
                                  } catch (e) {
                                    setModalState(() => isLocating = false);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ بجلب الموقع: $e')));
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () async {
                      final phone = phoneCtrl.text.trim();
                      final rate = double.tryParse(rateCtrl.text.trim()) ?? 15000.0;
                      final pin = pinCtrl.text.trim();

                      if (phone.isNotEmpty && pin.length == 4) {
                        await _firestore.collection('pitches').doc(widget.pitchName).update({
                          'phone': phone,
                          'hourlyRate': rate,
                          'pitchType': currentType,
                          'pin': pin,
                          if (currentLat != null && currentLng != null) ...{
                            'latitude': currentLat,
                            'longitude': currentLng,
                          }
                        });

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات وموقع الملعب بنجاح'), backgroundColor: Colors.green));
                        }
                      }
                    },
                    child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                                        onPressed: () => _confirmMatchCompletion(context, doc.reference, data),
                                        icon: const Icon(Icons.check_circle, size: 16),
                                        label: const Text('إنهاء وتقييم الفريق'),
                                      )
                                    else
                                      const Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.green, size: 18),
                                          SizedBox(width: 4),
                                          Text('مقبوضة ومكتملة', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
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

  void _confirmMatchCompletion(BuildContext context, DocumentReference docRef, Map<String, dynamic> bData) {
    bool markTrusted = true;
    final teamPhone = bData['phone'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد انتهاء المباراة واستلام الوارد'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('هل انتهت المباراة وتم استلام المبلغ بالكامل؟', style: TextStyle(height: 1.5)),
                const SizedBox(height: 14),
                const Divider(),
                const Text('تقييم انضباط الفريق والروح الرياضية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: markTrusted,
                  title: Text('فريق ملتزم بالحضور والمواعيد والأخلاق (${bData['teamOne']})'),
                  subtitle: const Text('يمنح الفريق شارة "فريق موثوق 🏅" بتطبيقه', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  activeColor: const Color(0xFF1B5E20),
                  onChanged: (val) => setDlgState(() => markTrusted = val ?? true),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                onPressed: () async {
                  await docRef.update({
                    'status': 'completed',
                    'teamTrustedRated': markTrusted,
                  });

                  if (teamPhone.toString().isNotEmpty) {
                    await _firestore.collection('players').doc(teamPhone).set({
                      'isTrustedTeam': markTrusted,
                    }, SetOptions(merge: true));
                  }

                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('نعم، تأكيد وتثبيت الوارد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
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
    return StreamBuilder<QuerySnapshot>(
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
    );
  }

  void _openAddRecurringDialog(BuildContext context) async {
    final pitchDoc = await _firestore.collection('pitches').doc(widget.pitchName).get();
    final duration = pitchDoc.data()?['matchDurationMinutes'] ?? 60;
    final availableSlots = buildPitchSlots(duration);

    if (!mounted) return;

    List<String> selectedDays = ['الجمعة'];
    String chosenSlot = availableSlots.isNotEmpty ? availableSlots.first : '08:00 م - 09:30 م';
    final teamCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '${pitchDoc.data()?['hourlyRate']?.toInt() ?? 15000}');

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('حدد الأيام الثابتة من الأسبوع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: weekDaysList.map((day) {
                      final isSelected = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        selectedColor: Colors.purple.shade200,
                        checkmarkColor: Colors.purple.shade900,
                        onSelected: (val) {
                          setDlgState(() {
                            if (val) {
                              selectedDays.add(day);
                            } else {
                              if (selectedDays.length > 1) {
                                selectedDays.remove(day);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: chosenSlot,
                    decoration: const InputDecoration(labelText: 'فترة الحجز المعتمدة', border: OutlineInputBorder()),
                    items: availableSlots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => chosenSlot = v);
                    },
                  ),
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
                  if (teamCtrl.text.isNotEmpty && selectedDays.isNotEmpty) {
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 15000.0;
                    for (var day in selectedDays) {
                      await _firestore.collection('recurring_rules').add({
                        'pitchName': widget.pitchName,
                        'dayOfWeek': day,
                        'timeSlot': chosenSlot,
                        'teamName': teamCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'price': price,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('تأكيد وحفظ الأيام', style: TextStyle(color: Colors.white)),
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

  void _openAddManualSheet(BuildContext context) async {
    final pitchDoc = await _firestore.collection('pitches').doc(widget.pitchName).get();
    final duration = pitchDoc.data()?['matchDurationMinutes'] ?? 60;
    final defaultPrice = (pitchDoc.data()?['hourlyRate'] as num?)?.toDouble() ?? 15000.0;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: FullAddBookingSheet(
          pitchName: widget.pitchName,
          durationMinutes: duration,
          defaultRate: defaultPrice,
        ),
      ),
    );
  }
}

class FullAddBookingSheet extends StatefulWidget {
  final String pitchName;
  final int durationMinutes;
  final double defaultRate;

  const FullAddBookingSheet({
    super.key,
    required this.pitchName,
    required this.durationMinutes,
    required this.defaultRate,
  });

  @override
  State<FullAddBookingSheet> createState() => _FullAddBookingSheetState();
}

class _FullAddBookingSheetState extends State<FullAddBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _teamOneController = TextEditingController();
  final _teamTwoController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _priceController;
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  late String _selectedSlot;
  late List<String> _slots;

  @override
  void initState() {
    super.initState();
    _slots = buildPitchSlots(widget.durationMinutes);
    _selectedSlot = _slots.isNotEmpty ? _slots.first : '06:00 م - 07:00 م';
    _priceController = TextEditingController(text: '${widget.defaultRate.toInt()}');
  }

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
              DropdownButtonFormField<String>(
                value: _selectedSlot,
                decoration: const InputDecoration(
                  labelText: 'فترة المباراة الرسمية (تطابق الجدول)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time, color: Color(0xFF1B5E20)),
                ),
                items: _slots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSlot = val);
                },
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
                      final times = _selectedSlot.split(' - ');
                      final sTime = times[0];
                      final eTime = times.length > 1 ? times[1] : '';

                      await FirebaseFirestore.instance.collection('bookings').add({
                        'pitchName': widget.pitchName,
                        'teamOne': _teamOneController.text.trim(),
                        'teamTwo': _teamTwoController.text.trim(),
                        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
                        'startTime': sTime,
                        'endTime': eTime,
                        'phone': _phoneController.text.trim(),
                        'price': double.tryParse(_priceController.text.trim()) ?? widget.defaultRate,
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
