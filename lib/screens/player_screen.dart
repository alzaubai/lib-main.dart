import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'tournaments/tournament_screen.dart';
import 'player/tabs/player_explore_tab.dart';
import 'player/tabs/player_bookings_tab.dart';

class PlayerScreen extends StatefulWidget {
  final String userPhone;
  const PlayerScreen({super.key, required this.userPhone});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF1B5E20),
          title: const Row(
            children: [
              Icon(Icons.sports_soccer, color: Colors.amberAccent, size: 24),
              SizedBox(width: 8),
              Text(
                'ملعبي - حجز الملاعب ⚽',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          actions: [
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
            preferredSize: const Size.fromHeight(50),
            child: Container(
              color: const Color(0xFF1B5E20),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: Colors.amberAccent,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.explore_rounded, size: 18), text: 'استكشاف الملاعب'),
                  Tab(icon: Icon(Icons.bookmark_added_rounded, size: 18), text: 'حجوزاتي'),
                  Tab(icon: Icon(Icons.emoji_events_rounded, size: 18), text: 'البطولات 🏆'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            PlayerExploreTab(userPhone: widget.userPhone),
            PlayerBookingsTab(userPhone: widget.userPhone),
            TournamentScreen(userPhone: widget.userPhone, isOwner: false),
          ],
        ),
      ),
    );
  }
}
