import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import 'auth_screen.dart';
import 'tournaments/tournament_screen.dart';
import 'owner/owner_analytics_screen.dart';
import 'owner/tabs/owner_schedule_tab.dart';
import 'owner/tabs/owner_requests_tab.dart';
import 'owner/tabs/owner_recurring_tab.dart';
import 'owner/sheets/add_manual_booking_sheet.dart';
import 'owner/sheets/add_recurring_booking_sheet.dart';

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
                OwnerScheduleTab(pitchName: widget.pitchName),
                OwnerRequestsTab(pitchName: widget.pitchName),
                OwnerRecurringTab(pitchName: widget.pitchName),
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
        onPressed: () => _openAddRecurringSheet(context),
      );
    }
    return null;
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
      builder: (_) => ModernAddBookingSheet(
        pitchName: widget.pitchName,
        durationMinutes: duration,
        defaultRate: defaultPrice,
      ),
    );
  }

  void _openAddRecurringSheet(BuildContext context) async {
    final pitchDoc = await _firestore.collection('pitches').doc(widget.pitchName).get();
    final defaultPrice = (pitchDoc.data()?['hourlyRate'] as num?)?.toDouble() ?? 25000.0;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecurringBookingSheet(
        pitchName: widget.pitchName,
        defaultRate: defaultPrice,
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

    // معالجة وحماية أنواع الأرضيات من القيم القديمة
    String rawType = data['pitchType'] ?? 'سباعي (7 ضد 7)';
    String currentType = pitchTypesList.contains(rawType) && rawType != 'الكل'
        ? rawType
        : 'سباعي (7 ضد 7)';

    String rawSurface = data['surfaceType'] ?? 'ثيل 🌿';
    String currentSurface = pitchSurfaceTypesList.contains(rawSurface) && rawSurface != 'الكل'
        ? rawSurface
        : 'ثيل 🌿';

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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
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
                            color: currentLat != null ? Colors.green.shade900 : Colors.blue.shade900,
                          ),
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
}
