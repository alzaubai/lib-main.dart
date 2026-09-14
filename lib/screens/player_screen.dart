import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/player_notification_service.dart';
import 'player/tabs/player_explore_tab.dart';
import 'player/tabs/player_bookings_tab.dart';
import 'tournaments/tournament_screen.dart';
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
  String _teamName = '';
  String _province = '';
  String _district = '';
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PlayerNotificationService.listen(context, widget.userPhone);
      }
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _displayName = data?['name'] ?? 'الكابتن';
          _teamName = data?['teamName'] ?? '';
          _province = data?['governorate'] ?? data?['province'] ?? '';
          _district = data?['area'] ?? data?['district'] ?? '';
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

  void _openPlayerSettingsDialog() {
    final nameCtrl = TextEditingController(text: _displayName);
    final teamCtrl = TextEditingController(text: _teamName);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إعدادات حساب اللاعب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: teamCtrl,
                decoration: const InputDecoration(labelText: 'اسم الفريق الأساسي', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).update({
                  'name': nameCtrl.text.trim(),
                  'teamName': teamCtrl.text.trim(),
                });
                setState(() {
                  _displayName = nameCtrl.text.trim();
                  _teamName = teamCtrl.text.trim();
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
      PlayerExploreTab(userPhone: widget.userPhone, showOnlyFavorites: false),
      PlayerExploreTab(userPhone: widget.userPhone, showOnlyFavorites: true),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'كابتن $_displayName',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_rounded, size: 12, color: Colors.amber.shade900),
                              const SizedBox(width: 2),
                              Text(
                                _teamName.isNotEmpty ? _teamName : 'فريق نشط',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_province.isNotEmpty)
                      Text('$_province - $_district', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
              tooltip: 'الإعدادات',
              onPressed: _openPlayerSettingsDialog,
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
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFF1B5E20)),
              label: 'استكشاف',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline_rounded),
              selectedIcon: Icon(Icons.favorite_rounded, color: Color(0xFF1B5E20)),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)),
              label: 'حجوزاتي',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events_rounded, color: Color(0xFF1B5E20)),
              label: 'البطولات',
            ),
          ],
        ),
      ),
    );
  }
}
