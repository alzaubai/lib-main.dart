import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/player_notification_service.dart';
import 'player/tabs/player_explore_tab.dart';
import 'player/tabs/player_bookings_tab.dart';
import 'tournaments/tournaments_tab.dart' if (dart.library.io) 'tournament_screen.dart';
import 'auth_screen.dart';

class PlayerScreen extends StatefulWidget {
  final String userPhone;
  final String? userName;
  final String? userProvince;
  final String? userDistrict;

  const PlayerScreen({
    super.key,
    required this.userPhone,
    this.userName,
    this.userProvince,
    this.userDistrict,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _currentIndex = 0;
  String _displayName = 'الكابتن';
  String _province = '';
  String _district = '';
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlayerNotificationService.listen(context, widget.userPhone);
    });
  }

  Future<void> _fetchUserData() async {
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      setState(() {
        _displayName = widget.userName!;
        _province = widget.userProvince ?? '';
        _district = widget.userDistrict ?? '';
        _isLoadingUserData = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userPhone)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _displayName = data?['name'] ?? 'الكابتن';
          _province = data?['province'] ?? '';
          _district = data?['district'] ?? '';
          _isLoadingUserData = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingUserData = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUserData = false);
    }
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
    if (_isLoadingUserData) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
        ),
      );
    }

    final List<Widget> tabs = [
      PlayerExploreTab(
        userPhone: widget.userPhone,
      ),
      PlayerBookingsTab(
        userPhone: widget.userPhone,
      ),
      const TournamentScreen(
        userPhone: 'player',
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
                    'كابتن $_displayName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (_province.isNotEmpty)
                    Text(
                      '$_province - $_district',
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
