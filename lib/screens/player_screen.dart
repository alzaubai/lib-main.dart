import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'player/tabs/player_explore_tab.dart';
import 'player/tabs/player_bookings_tab.dart';
import 'tournaments/tournament_screen.dart';
import '../services/player_notification_service.dart';

class PlayerScreen extends StatefulWidget {
  final String userPhone;
  const PlayerScreen({super.key, required this.userPhone});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userName = 'كابتن';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadUserData();

    // تشغيل الاستماع اللحظي لإشعارات قبول أو رفض الحجز
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlayerNotificationService.listenToBookingUpdates(context, widget.userPhone);
    });
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userPhone).get();
      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'كابتن';
        });
      }
    } catch (_) {}
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
        backgroundColor: Colors.red,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF1B5E20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_soccer, color: Colors.amberAccent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أهلاً، $_userName ⚽',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.userPhone,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
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
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: const Color(0xFF1B5E20),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.amberAccent,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  const Tab(
                    icon: Icon(Icons.search_rounded, size: 20),
                    text: 'استكشاف الملاعب',
                  ),
                  Tab(
                    icon: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('bookings')
                          .where('phone', isEqualTo: widget.userPhone)
                          .where('status', isEqualTo: 'upcoming')
                          .snapshots(),
                      builder: (context, snap) {
                        final count = snap.data?.docs.length ?? 0;
                        return Badge(
                          isLabelVisible: count > 0,
                          label: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: Colors.greenAccent.shade700,
                          child: const Icon(Icons.confirmation_number_outlined, size: 20),
                        );
                      },
                    ),
                    text: 'حجوزاتي',
                  ),
                  const Tab(
                    icon: Icon(Icons.emoji_events_rounded, size: 20),
                    text: 'البطولات 🏆',
                  ),
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
