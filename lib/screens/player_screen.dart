import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/player_notification_service.dart';
import 'player/tabs/player_explore_tab.dart';
import 'player/tabs/player_bookings_tab.dart';
import 'tournaments/tournament_screen.dart'; // هذا هو السطر الذي كان مفقوداً
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).get();
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
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
      );
    }

    final List<Widget> tabs = <Widget>[
      PlayerExploreTab(userPhone: widget.userPhone),
      PlayerBookingsTab(userPhone: widget.userPhone),
      TournamentScreen(userPhone: widget.userPhone, isOwner: false),
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
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20), size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كابتن $_displayName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  if (_province.isNotEmpty) Text('$_province - $_district', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
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
        body: IndexedStack(index: _currentIndex, children: tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE8F5E9),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFF1B5E20)), label: 'الملاعب'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)), label: 'حجوزاتي'),
            NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events_rounded, color: Color(0xFF1B5E20)), label: 'البطولات'),
          ],
        ),
      ),
    );
  }
}
