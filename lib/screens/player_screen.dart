import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/player_notification_service.dart';
import 'tabs/player_explore_tab.dart';
import 'tabs/player_bookings_tab.dart';
import '../tournaments/tournament_list_tab.dart';
import '../auth_screen.dart';

class PlayerHomeScreen extends StatefulWidget {
  final String userPhone;
  final String userName;
  final String userProvince;
  final String userDistrict;

  const PlayerHomeScreen({
    super.key,
    required this.userPhone,
    required this.userName,
    required this.userProvince,
    required this.userDistrict,
  });

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // تفعيل الاستماع الفوري لإشعارات استبعاد البطولة ومواعيد القرعة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlayerNotificationService.listen(context, widget.userPhone);
    });
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
      PlayerExploreTab(
        userPhone: widget.userPhone,
        userProvince: widget.userProvince,
        userDistrict: widget.userDistrict,
      ),
      PlayerBookingsTab(
        userPhone: widget.userPhone,
      ),
      TournamentListTab(
        userPhone: widget.userPhone,
        isOwner: false,
      ),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  color: Color(0xFF1B5E20),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كابتن ${widget.userName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${widget.userProvince} - ${widget.userDistrict}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من تسجيل الخروج من التطبيق؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _logout();
                        },
                        child: const Text(
                          'تأكيد الخروج',
                          style: TextStyle(color: Colors.white),
                        ),
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
              .where('phone', isEqualTo: widget.userPhone)
              .where('seenByPlayer', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

            return Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFE8F5E9),
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.explore_outlined, color: Color(0xFF64748B)),
                    selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFF1B5E20)),
                    label: 'استكشاف الملاعب',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0,
                      backgroundColor: Colors.redAccent,
                      label: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF64748B)),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: unreadCount > 0,
                      backgroundColor: Colors.redAccent,
                      label: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)),
                    ),
                    label: 'حجوزاتي',
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
