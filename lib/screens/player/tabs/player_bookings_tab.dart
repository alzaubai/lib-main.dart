import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/booking_service.dart';
import '../widgets/player_booking_card.dart';

class PlayerBookingsTab extends StatefulWidget {
  final String userPhone;
  const PlayerBookingsTab({super.key, required this.userPhone});

  @override
  State<PlayerBookingsTab> createState() => _PlayerBookingsTabState();
}

class _PlayerBookingsTabState extends State<PlayerBookingsTab> with SingleTickerProviderStateMixin {
  late TabController _bookingTabCtrl;

  @override
  void initState() {
    super.initState();
    _bookingTabCtrl = TabController(length: 2, vsync: this);
    _bookingTabCtrl.addListener(() {
      if (_bookingTabCtrl.indexIsChanging) return;
      final filter = _bookingTabCtrl.index == 0 ? ['upcoming', 'pending'] : ['rejected', 'completed'];
      BookingService.markBookingsAsSeen(userPhone: widget.userPhone, statuses: filter);
    });
  }

  @override
  void dispose() {
    _bookingTabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('phone', isEqualTo: widget.userPhone)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          final allDocs = snapshot.data?.docs ?? [];
          final activeDocs = allDocs.where((d) {
            final s = (d.data() as Map<String, dynamic>)['status'];
            return s == 'pending' || s == 'upcoming';
          }).toList();

          final archiveDocs = allDocs.where((d) {
            final s = (d.data() as Map<String, dynamic>)['status'];
            return s == 'completed' || s == 'rejected';
          }).toList();

          final unreadActive = activeDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'upcoming' && (d.data() as Map<String, dynamic>)['seenByPlayer'] == false).length;
          final unreadArchive = archiveDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'rejected' && (d.data() as Map<String, dynamic>)['seenByPlayer'] == false).length;

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _bookingTabCtrl,
                  labelColor: const Color(0xFF1B5E20),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF1B5E20),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      icon: Badge(
                        isLabelVisible: unreadActive > 0,
                        backgroundColor: Colors.green.shade700,
                        label: Text('$unreadActive', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        child: const Icon(Icons.flash_on_rounded, size: 18),
                      ),
                      text: 'الحجوزات النشطة ⚡',
                    ),
                    Tab(
                      icon: Badge(
                        isLabelVisible: unreadArchive > 0,
                        backgroundColor: Colors.redAccent,
                        label: Text('$unreadArchive', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        child: const Icon(Icons.history_rounded, size: 18),
                      ),
                      text: 'أرشيف وسجل المواعيد 📁',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _bookingTabCtrl,
                  children: [
                    _buildList(activeDocs, isActive: true),
                    _buildList(archiveDocs, isActive: false),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs, {required bool isActive}) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          isActive ? 'لا توجد حجوزات نشطة حالياً' : 'سجل الأرشيف فارغ',
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, idx) => PlayerBookingCard(doc: docs[idx], isActiveTab: isActive),
    );
  }
}
