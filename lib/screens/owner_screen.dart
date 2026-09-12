import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import 'auth_screen.dart';
import 'tournaments/tournament_screen.dart';
import 'owner/owner_analytics_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this);
    _loadPendingSeenCache();
    _tabController.addListener(() {
      setState(() {});
      if (_tabController.index == 1) _markPendingAsSeen();
    });
  }

  Future<void> _loadPendingSeenCache() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSeenPendingCount = prefs.getInt('owner_pending_seen_${widget.pitchName}') ?? 0;
    });
  }

  Future<void> _markPendingAsSeen() async {
    final query = await _firestore
        .collection('bookings')
        .where('pitchName', isEqualTo: widget.pitchName)
        .where('status', isEqualTo: 'pending')
        .get();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('owner_pending_seen_${widget.pitchName}', query.docs.length);
    setState(() => _lastSeenPendingCount = query.docs.length);
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
      stream: _firestore
          .collection('bookings')
          .where('pitchName', isEqualTo: widget.pitchName)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, pendingSnapshot) {
        final pendingCount = pendingSnapshot.data?.docs.length ?? 0;
        final hasUnreadPending = pendingCount > _lastSeenPendingCount;

        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F6F8),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF1B5E20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.stadium, color: Colors.amberAccent, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pitchName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text('لوحة تحكّم الملعب', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.insights_rounded, color: Colors.lightGreenAccent),
                  tooltip: 'التحليلات المالية والذروة',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OwnerAnalyticsScreen(pitchName: widget.pitchName)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  tooltip: 'إعدادات الملعب والـ GPS',
                  onPressed: () => _openPitchSettingsModal(context),
                ),
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.amberAccent),
                  tooltip: 'كشف الحساب المالي',
                  onPressed: () => _openFinancialReportModal(context),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                  tooltip: 'تسجيل خروج',
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  color: const Color(0xFF1B5E20),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorColor: Colors.amberAccent,
                    indicatorWeight: 4,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    tabs: [
                      const Tab(icon: Icon(Icons.event_note_rounded, size: 20), text: 'الجدول'),
                      Tab(
                        icon: Badge(
                          isLabelVisible: hasUnreadPending,
                          label: Text('${pendingCount - _lastSeenPendingCount}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.redAccent,
                          child: const Icon(Icons.notifications_active_rounded, size: 20),
                        ),
                        text: 'الطلبات',
                      ),
                      const Tab(icon: Icon(Icons.repeat_rounded, size: 20), text: 'الدائمة'),
                      const Tab(icon: Icon(Icons.emoji_events_rounded, size: 20), text: 'البطولات 🏆'),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildConfirmedTab(currencyFormatter),
                _buildPendingTab(pendingSnapshot),
                _buildRecurringBookingsTab(),
                TournamentScreen(userPhone: 'owner', isOwner: true, pitchName: widget.pitchName),
              ],
            ),
            floatingActionButton: _buildFloatingAction(),
          ),
        );
      },
    );
  }

  Widget? _buildFloatingAction() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('حجز موعد يدوي', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openAddManualSheet(context),
      );
    } else if (_tabController.index == 2) {
      return FloatingActionButton.extended(
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('إضافة حجز أسبوعي دائم', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openAddRecurringDialog(context),
      );
    }
    return null;
  }

  Widget _buildConfirmedTab(NumberFormat currencyFormatter) {
    return StreamBuilder<QuerySnapshot>(
      // شمول مباريات البطولة tournament_match في استعلام الجدول للمالك
      stream: _firestore
          .collection('bookings')
          .where('pitchName', isEqualTo: widget.pitchName)
          .where('status', whereIn: ['upcoming', 'completed', 'tournament_match'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 16),
                              SizedBox(width: 4),
                              Text('الوارد الفعلي المقبوض', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${currencyFormatter.format(actualRevenueReceived)} د.ع',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.hourglass_top_rounded, color: Colors.lightGreenAccent, size: 16),
                              SizedBox(width: 4),
                              Text('المبلغ المؤكد القادم', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${currencyFormatter.format(expectedRevenueUpcoming)} د.ع',
                              style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_rounded, size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا توجد مباريات مسجلة حالياً',
                              style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'];
                        final isDone = status == 'completed';
                        final isTour = status == 'tournament_match';
                        final phone = data['phone'] ?? '';

                        return Card(
                          elevation: 3,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isTour
                                  ? Colors.amber.shade400
                                  : (isDone ? Colors.green.shade300 : Colors.grey.shade300),
                              width: isTour ? 1.8 : 1.2,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade700),
                                        const SizedBox(width: 6),
                                        Text('${data['date']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isTour
                                            ? Colors.amber.shade50
                                            : (isDone ? Colors.green.shade50 : Colors.blue.shade50),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isTour
                                              ? Colors.amber.shade700
                                              : (isDone ? Colors.green : Colors.blue.shade300),
                                        ),
                                      ),
                                      child: Text(
                                        isTour
                                            ? '🏆 مباراة بطولة رسمية'
                                            : (isDone ? 'مكتملة ومقبوضة ✔️' : 'مؤكدة (بانتظار اللعب) ⏳'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isTour
                                              ? Colors.amber.shade900
                                              : (isDone ? Colors.green.shade900 : Colors.blue.shade900),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isTour ? Colors.amber.shade50.withOpacity(0.5) : const Color(0xFFF4F7F4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${data['teamOne']}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isTour ? Colors.amber.shade900 : const Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text('⚔️', style: TextStyle(fontSize: 18)),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${data['teamTwo']}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isTour ? Colors.amber.shade900 : const Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text('${data['startTime']} إلى ${data['endTime']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const Spacer(),
                                    Text(
                                      isTour
                                          ? 'محجوزة بالبطولة'
                                          : '${currencyFormatter.format(data['price'] ?? 0)} د.ع',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isTour ? Colors.amber.shade900 : Colors.teal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    if (phone.toString().isNotEmpty) ...[
                                      IconButton(
                                        icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green),
                                        tooltip: 'اتصال',
                                        onPressed: () => launchCallDirect(phone),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                                        tooltip: 'واتساب',
                                        onPressed: () => launchWhatsAppDirect(phone),
                                      ),
                                    ],
                                    const Spacer(),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                        side: BorderSide(color: Colors.red.shade300),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                                      label: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: () => _confirmDeleteMatch(context, doc.reference),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isDone && !isTour)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1B5E20),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                                        label: const Text('إنهاء وتثبيت', style: TextStyle(fontWeight: FontWeight.bold)),
                                        onPressed: () => _confirmMatchCompletion(context, doc.reference, data),
                                      )
                                    else if (isDone)
                                      const Row(
                                        children: [
                                          Icon(Icons.verified_rounded, color: Colors.green, size: 18),
                                          SizedBox(width: 4),
                                          Text('تم القبض', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text('تأكيد إنهاء المباراة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تنبيه: بمجرد التأكيد لن تتمكن من التراجع، وسيتم تسجيل المبلغ نهائياً في الوارد الفعلي.',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('المباراة: ${bData['teamOne']} ⚔️ ${bData['teamTwo']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('المبلغ المقبوض: ${bData['price']} د.ع', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: markTrusted,
                  title: Text('فريق ملتزم بالحضور والمواعيد (${bData['teamOne']})', style: const TextStyle(fontSize: 12)),
                  subtitle: const Text('يمنح الفريق شارة "فريق موثوق 🏅"', style: TextStyle(fontSize: 11, color: Colors.grey)),
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

  void _confirmDeleteMatch(BuildContext context, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('حذف هذا الحجز نهائياً؟'),
          content: const Text('هل أنت متأكد من حذف هذه المباراة من الجدول؟ لن يتم احتسابها في الحسابات.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await docRef.delete();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('نعم، حذف الحجز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab(AsyncSnapshot<QuerySnapshot> snapshot) {
    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) return const Center(child: Text('لا توجد طلبات معلقة'));

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;

        return Card(
          color: Colors.amber.shade50,
          child: ListTile(
            title: Text('طلب من: ${data['teamOne']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('الموعد: ${data['date']} (${data['startTime']} - ${data['endTime']})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => doc.reference.update({'status': 'rejected'})),
                IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => doc.reference.update({'status': 'upcoming'})),
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
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('لا توجد حجوزات أسبوعية ثابتة'));

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.repeat, color: Colors.purple),
                title: Text('كل ${data['dayOfWeek']} (${data['timeSlot']})'),
                subtitle: Text('محجوز لـ: ${data['teamName']}'),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
              ),
            );
          },
        );
      },
    );
  }

  void _openAddRecurringDialog(BuildContext context) async {
    final availableSlots = buildPitchSlots(60);
    List<String> selectedDays = ['الجمعة'];
    String chosenSlot = availableSlots.first;
    final teamCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '25000');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة حجز أسبوعي دائم'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: chosenSlot,
                    decoration: const InputDecoration(labelText: 'الفترة'),
                    items: availableSlots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDlgState(() => chosenSlot = v!),
                  ),
                  TextField(controller: teamCtrl, decoration: const InputDecoration(labelText: 'اسم الفريق')),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (teamCtrl.text.isNotEmpty) {
                    await _firestore.collection('recurring_rules').add({
                      'pitchName': widget.pitchName,
                      'dayOfWeek': selectedDays.first,
                      'timeSlot': chosenSlot,
                      'teamName': teamCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text.trim()) ?? 25000.0,
                    });
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('تثبيت'),
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
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).snapshots(),
        builder: (context, snapshot) {
          double completedTotal = 0;
          if (snapshot.hasData) {
            for (var d in snapshot.data!.docs) {
              final data = d.data() as Map<String, dynamic>;
              if (data['status'] == 'completed') {
                completedTotal += (data['price'] as num?)?.toDouble() ?? 0.0;
              }
            }
          }
          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('كشف الحساب المالي الكلي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 16),
                  ListTile(
                    tileColor: Colors.green.shade50,
                    title: const Text('إجمالي الوارد الفعلي المقبوض:'),
                    trailing: Text('${currencyFormatter.format(completedTotal)} د.ع',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPitchSettingsModal(BuildContext context) async {
    final doc = await _firestore.collection('pitches').doc(widget.pitchName).get();
    if (!doc.exists || !mounted) return;

    final data = doc.data() as Map<String, dynamic>;
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');
    final rateCtrl = TextEditingController(text: '${data['hourlyRate']?.toInt() ?? 25000}');
    final descCtrl = TextEditingController(text: data['description'] ?? '');

    String currentType = data['pitchType'] ?? 'سباعي (7 ضد 7)';
    String currentSurface = data['surfaceType'] ?? 'ثيل 🌿';
    double? currentLat = (data['latitude'] as num?)?.toDouble();
    double? currentLng = (data['longitude'] as num?)?.toDouble();
    bool isLocating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.only(top: 16, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 16),
                  const Text('إعدادات وبيانات الملعب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم هاتف التواصل', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'سعر الحجز (د.ع)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currentType,
                          decoration: const InputDecoration(labelText: 'حجم الملعب', border: OutlineInputBorder()),
                          items: pitchTypesList
                              .where((t) => t != 'الكل')
                              .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11))))
                              .toList(),
                          onChanged: (val) => setModalState(() => currentType = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currentSurface,
                          decoration: const InputDecoration(labelText: 'نوع الأرضية', border: OutlineInputBorder()),
                          items: pitchSurfaceTypesList
                              .where((s) => s != 'الكل')
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11))))
                              .toList(),
                          onChanged: (val) => setModalState(() => currentSurface = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'العنوان التفصيلي / نقطة دالة', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text(
                          currentLat != null ? 'تم ربط موقع الملعب عبر الـ GPS بنجاح' : 'لم يتم تثبيت الموقع على الخريطة بعد',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentLat != null ? Colors.green.shade900 : Colors.blue.shade900),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                          icon: isLocating
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.my_location),
                          label: Text(isLocating ? 'جاري التحديد...' : 'تثبيت موقع الملعب الحالي'),
                          onPressed: isLocating
                              ? null
                              : () async {
                                  setModalState(() => isLocating = true);
                                  try {
                                    LocationPermission perm = await Geolocator.requestPermission();
                                    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                    setModalState(() {
                                      currentLat = pos.latitude;
                                      currentLng = pos.longitude;
                                      isLocating = false;
                                    });
                                  } catch (_) {
                                    setModalState(() => isLocating = false);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () async {
                      await _firestore.collection('pitches').doc(widget.pitchName).update({
                        'phone': phoneCtrl.text.trim(),
                        'hourlyRate': double.tryParse(rateCtrl.text.trim()) ?? 25000.0,
                        'pitchType': currentType,
                        'surfaceType': currentSurface,
                        'description': descCtrl.text.trim(),
                        if (currentLat != null) 'latitude': currentLat,
                        if (currentLng != null) 'longitude': currentLng,
                      });
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: const Text('حفظ الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddManualSheet(BuildContext context) async {
    final pitchDoc = await _firestore.collection('pitches').doc(widget.pitchName).get();
    final duration = pitchDoc.data()?['matchDurationMinutes'] ?? 60;
    final defaultPrice = (pitchDoc.data()?['hourlyRate'] as num?)?.toDouble() ?? 25000.0;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: ModernAddBookingSheet(
          pitchName: widget.pitchName,
          durationMinutes: duration,
          defaultRate: defaultPrice,
        ),
      ),
    );
  }
}

class ModernAddBookingSheet extends StatefulWidget {
  final String pitchName;
  final int durationMinutes;
  final double defaultRate;

  const ModernAddBookingSheet({
    super.key,
    required this.pitchName,
    required this.durationMinutes,
    required this.defaultRate,
  });

  @override
  State<ModernAddBookingSheet> createState() => _ModernAddBookingSheetState();
}

class _ModernAddBookingSheetState extends State<ModernAddBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _teamOneController = TextEditingController();
  final _teamTwoController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _priceController;

  DateTime _selectedDate = DateTime.now();
  late String _selectedSlot;
  late List<String> _slots;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _slots = buildPitchSlots(widget.durationMinutes);
    _selectedSlot = _slots.isNotEmpty ? _slots.first : '08:00 م - 09:00 م';
    _priceController = TextEditingController(text: '${widget.defaultRate.toInt()}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: Offset(0, -5),
          )
        ],
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_task_rounded, color: Color(0xFF1B5E20), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تسجيل مباراة وحجز مباشر ⚽',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                      Text(
                        'الملعب: ${widget.pitchName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _teamOneController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'اسم الفريق الأول',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'يرجى كتابة اسم الفريق' : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('⚔️ VS ⚔️', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    TextFormField(
                      controller: _teamTwoController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'اسم الفريق الثاني (أو اكتب: تحدي)',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.sports_soccer, color: Colors.teal),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'يرجى كتابة اسم الفريق' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 15)),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF1B5E20), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'موعد المباراة: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      const Text('تغيير 📅', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('اختر فترة وتوقيت المباراة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _slots.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final slot = _slots[index];
                    final isSelected = _selectedSlot == slot;
                    return ChoiceChip(
                      label: Text(slot, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B5E20),
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (val) setState(() => _selectedSlot = slot);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم هاتف الكابتن',
                        prefixIcon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'المبلغ (د.ع)',
                        prefixIcon: const Icon(Icons.payments_rounded, color: Colors.teal, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text('تثبيت المباراة في الجدول ⚽', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isSaving = true);
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
                              'status': 'upcoming',
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم تثبيت المباراة في الجدول بنجاح'), backgroundColor: Colors.green),
                              );
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
