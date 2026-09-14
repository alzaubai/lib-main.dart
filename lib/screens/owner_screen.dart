import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'owner/tabs/owner_schedule_tab.dart';
import 'owner/tabs/owner_requests_tab.dart';
import 'owner/tabs/owner_recurring_tab.dart';
import 'owner/owner_analytics_screen.dart';
import 'tournaments/tournament_screen.dart';
import 'auth_screen.dart';

class OwnerScreen extends StatefulWidget {
  final String userPhone;
  final String pitchName;

  const OwnerScreen({
    super.key,
    required this.userPhone,
    required this.pitchName,
  });

  @override
  State<OwnerScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _listenToPlayerCancellations();
  }

  void _listenToPlayerCancellations() {
    FirebaseFirestore.instance
        .collection('bookings')
        .where('pitchName', isEqualTo: widget.pitchName)
        .where('cancelledByPlayer', isEqualTo: true)
        .where('cancellationSeenByOwner', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final teamName = data['cancellingTeamName'] ?? data['teamOne'] ?? 'فريق كابتن';
        final date = data['date'] ?? '';
        final startTime = data['startTime'] ?? '';

        _showCancellationAlert(doc.reference, teamName, date, startTime);
      }
    });
  }

  void _showCancellationAlert(
    DocumentReference ref,
    String teamName,
    String date,
    String time,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.event_busy_rounded, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'إلغاء حجز من قبل الكابتن',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'قام كابتن ($teamName) بإلغاء موعد الحجز الخاص به.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📅 التاريخ: $date', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('⏰ الساعة: $time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('تم إخلاء هذه الساعة وأصبحت متاحة للحجز مجدداً.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                await ref.update({'cancellationSeenByOwner': true});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حسناً، تم الإخلاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      OwnerScheduleTab(pitchName: widget.pitchName),
      OwnerRequestsTab(pitchName: widget.pitchName),
      OwnerRecurringTab(pitchName: widget.pitchName),
      TournamentScreen(userPhone: 'owner', isOwner: true, pitchName: widget.pitchName),
    ];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stadium_rounded, color: Color(0xFF1B5E20), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pitchName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'لوحة الإدارة والتحكم',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF1B5E20)),
              tooltip: 'الإحصائيات والأرباح',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OwnerAnalyticsScreen(pitchName: widget.pitchName),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من تسجيل الخروج من حساب الملعب؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _logout();
                        },
                        child: const Text('تأكيد الخروج', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
        bottomNavigationBar: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('pitchName', isEqualTo: widget.pitchName)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            final pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

            return Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFE8F5E9),
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined, color: Color(0xFF64748B)),
                    selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)),
                    label: 'جدول المباريات',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: pendingCount > 0,
                      backgroundColor: Colors.orange.shade800,
                      label: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      child: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: pendingCount > 0,
                      backgroundColor: Colors.orange.shade800,
                      label: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      child: const Icon(Icons.notifications_rounded, color: Color(0xFF1B5E20)),
                    ),
                    label: 'الطلبات المعلقة',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.repeat_rounded, color: Color(0xFF64748B)),
                    selectedIcon: Icon(Icons.repeat_on_rounded, color: Color(0xFF1B5E20)),
                    label: 'الحجوزات الدائمة',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.emoji_events_outlined, color: Color(0xFF64748B)),
                    selectedIcon: Icon(Icons.emoji_events_rounded, color: Color(0xFF1B5E20)),
                    label: 'البطولات',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
