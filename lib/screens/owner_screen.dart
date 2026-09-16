import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'owner/tabs/owner_schedule_tab.dart';
import 'owner/tabs/owner_requests_tab.dart';
import 'owner/tabs/owner_recurring_tab.dart';
import 'owner/owner_analytics_screen.dart';
import 'owner/owner_settings_screen.dart';
import 'owner/sheets/owner_archive_sheet.dart';
import 'owner/sheets/owner_quick_actions_sheet.dart';
import 'tournaments/tournament_screen.dart';
import 'common/dialogs/pitch_reviews_dialog.dart';

class OwnerScreen extends StatefulWidget {
  final String userPhone;
  final String pitchName;

  const OwnerScreen({
    super.key,
    required this.userPhone,
    required this.pitchName,
  });

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _listenToPlayerCancellations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _showCancellationAlert(DocumentReference ref, String teamName, String date, String time) {
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
              Text('قام كابتن ($teamName) بإلغاء موعد الحجز الخاص به.', style: const TextStyle(fontSize: 13, height: 1.4)),
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
                    Text('التاريخ: $date', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('الساعة: $time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          elevation: 2,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.stadium_rounded, color: Colors.white, size: 22),
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
                            widget.pitchName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('pitches').doc(widget.pitchName).snapshots(),
                          builder: (context, snapshot) {
                            double rating = 5.0;
                            int reviewsCount = 0;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final d = snapshot.data!.data() as Map<String, dynamic>?;
                              rating = (d?['rating'] as num?)?.toDouble() ?? 5.0;
                              reviewsCount = (d?['reviewsCount'] as num?)?.toInt() ?? 0;
                            }

                            return InkWell(
                              onTap: () {
                                PitchReviewsDialog.show(context, pitchName: widget.pitchName, currentUserPhone: widget.userPhone, canAddReview: false);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 13, color: Colors.black87),
                                    const SizedBox(width: 2),
                                    Text(
                                      reviewsCount > 0 ? '$rating ($reviewsCount)' : '$rating',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Text('لوحة التحكم والإدارة', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_toggle_off_rounded, color: Colors.white),
              tooltip: 'أرشيف المباريات المكتملة',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => OwnerArchiveSheet(pitchName: widget.pitchName),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
              tooltip: 'تحليلات الملعب والذروة',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerAnalyticsScreen(pitchName: widget.pitchName))),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              tooltip: 'الإعدادات',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerSettingsScreen(userPhone: widget.userPhone, pitchName: widget.pitchName))),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3.5,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              const Tab(icon: Icon(Icons.calendar_month_outlined, size: 20), text: 'الجدول'),
              Tab(
                icon: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).where('status', isEqualTo: 'pending').snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Badge(
                      isLabelVisible: count > 0,
                      backgroundColor: Colors.amber.shade700,
                      label: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.black)),
                      child: const Icon(Icons.notifications_outlined, size: 20),
                    );
                  },
                ),
                text: 'الطلبات',
              ),
              const Tab(icon: Icon(Icons.repeat_rounded, size: 20), text: 'الاشتراكات'),
              const Tab(icon: Icon(Icons.emoji_events_outlined, size: 20), text: 'البطولات'),
            ],
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => OwnerQuickActionsSheet(pitchName: widget.pitchName),
            );
          },
          tooltip: 'إجراء سريع',
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
}
