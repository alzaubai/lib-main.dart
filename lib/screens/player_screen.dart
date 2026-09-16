import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import 'auth_screen.dart';
import 'player/tabs/player_explore_tab.dart';
import 'player/tabs/player_bookings_tab.dart';
import 'tournaments/tournament_screen.dart';
import 'player/player_archive_screen.dart';

class PlayerScreen extends StatefulWidget {
  final String userPhone;

  const PlayerScreen({super.key, required this.userPhone});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _currentIndex = 0;

  String _userName = '';
  String _teamName = '';
  String _position = 'مهاجم';
  String _governorate = 'بغداد';
  String _area = 'الكرخ';
  double _teamRating = 5.0;
  int _matchesPlayed = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _cleanGhostNotifications();
  }

  List<String> _getPhoneVariants(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+|-'), '');
    final variants = <String>{clean};
    if (clean.startsWith('07')) { 
      variants.add('964${clean.substring(1)}'); 
      variants.add('+964${clean.substring(1)}'); 
    } else if (clean.startsWith('964')) { 
      variants.add('0${clean.substring(3)}'); 
      variants.add('+$clean'); 
    } else if (clean.startsWith('+964')) { 
      variants.add('0${clean.substring(4)}'); 
      variants.add(clean.substring(1)); 
    }
    return variants.toList();
  }

  bool _shouldBeArchived(Map<String, dynamic> data) {
    try {
      if (data['isArchived'] == true) return true;
      final dateStr = (data['date'] ?? '').toString();
      if (dateStr.isNotEmpty) {
        final bookingDate = DateFormat('yyyy-MM-dd').parse(dateStr);
        final todayDateOnly = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        if (bookingDate.isBefore(todayDateOnly)) return true;
      }
      final status = (data['status'] ?? '').toString();
      if (['rejected', 'removed_from_tournament', 'completed', 'cancelled'].contains(status)) {
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp && DateTime.now().difference(createdAt.toDate()).inHours >= 24) return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _cleanGhostNotifications() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('phone', whereIn: _getPhoneVariants(widget.userPhone))
          .where('seenByPlayer', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;

      for (var doc in snap.docs) {
        final data = doc.data();
        if (_shouldBeArchived(data) || data['isDeleted'] == true) {
          batch.update(doc.reference, {'seenByPlayer': true});
          hasUpdates = true;
        }
      }

      if (hasUpdates) await batch.commit();
    } catch (_) {}
  }

  void _showCenterToast(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).get();
      if (doc.exists && mounted) {
        final d = doc.data()!;
        setState(() {
          _userName = (d['name'] ?? 'كابتن').toString();
          _teamName = (d['teamName'] ?? '').toString();
          _position = (d['position'] ?? 'مهاجم').toString();
          _governorate = (d['governorate'] ?? 'بغداد').toString();
          _area = (d['area'] ?? 'الكرخ').toString();
          _teamRating = (d['teamRating'] as num?)?.toDouble() ?? 5.0;
          _matchesPlayed = (d['matchesPlayed'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red, size: 22),
              SizedBox(width: 8),
              Text('تسجيل الخروج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text('هل أنت متأكد من تسجيل الخروج من حساب اللاعب؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('تأكيد الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlayerSettingsSheet() {
    final nameCtrl = TextEditingController(text: _userName);
    final teamCtrl = TextEditingController(text: _teamName);
    String selectedPos = _position;
    String selectedGov = _governorate;
    String selectedArea = _area;
    bool isSaving = false;

    final positionsList = [
      'حارس مرمى',
      'مدافع',
      'خط وسط',
      'جناح',
      'مهاجم',
    ];

    if (!positionsList.contains(selectedPos)) selectedPos = 'مهاجم';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final availableAreas = getAreasListForGov(selectedGov).where((a) => a != 'الكل').toList();
          if (!availableAreas.contains(selectedArea)) {
            selectedArea = availableAreas.isNotEmpty ? availableAreas.first : 'المركز';
          }
          final validGovs = iraqGovernoratesList.where((g) => g != 'الكل').toList();

          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.manage_accounts_rounded, color: Color(0xFF1B5E20), size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'إعدادات الحساب',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        teamCtrl.text.isNotEmpty ? teamCtrl.text : 'فريقك الكروي',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'التقييم: $_teamRating',
                                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text('($_matchesPlayed مباراة)', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(sheetCtx);
                                    _confirmLogout();
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'خروج',
                                          style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('البيانات الشخصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'الاسم الكامل',
                                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1B5E20)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: teamCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'اسم فريقك',
                                    prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1B5E20)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: selectedPos,
                                  decoration: InputDecoration(
                                    labelText: 'مركزك في اللعب',
                                    prefixIcon: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: positionsList.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                                  onChanged: (v) => setSheetState(() => selectedPos = v!),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: selectedGov,
                                        decoration: InputDecoration(
                                          labelText: 'المحافظة',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        items: validGovs.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 11)))).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setSheetState(() {
                                              selectedGov = val;
                                              final areas = getAreasListForGov(val).where((a) => a != 'الكل').toList();
                                              selectedArea = areas.isNotEmpty ? areas.first : 'المركز';
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: selectedArea,
                                        decoration: InputDecoration(
                                          labelText: 'المنطقة',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        items: availableAreas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 11)))).toList(),
                                        onChanged: (val) {
                                          if (val != null) setSheetState(() => selectedArea = val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  initialValue: widget.userPhone,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'رقم الهاتف المسجل',
                                    prefixIcon: const Icon(Icons.phone_android_rounded, color: Colors.grey),
                                    suffixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 18),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final newName = nameCtrl.text.trim();
                                      final newTeam = teamCtrl.text.trim();
                                      if (newName.isEmpty) return;

                                      setSheetState(() => isSaving = true);
                                      await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).set({
                                        'name': newName,
                                        'teamName': newTeam,
                                        'position': selectedPos,
                                        'governorate': selectedGov,
                                        'area': selectedArea,
                                        'updatedAt': FieldValue.serverTimestamp(),
                                      }, SetOptions(merge: true));

                                      await _fetchUserData();
                                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);

                                      if (mounted) {
                                        _showCenterToast('تم حفظ التعديلات');
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneVariants = _getPhoneVariants(widget.userPhone);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          elevation: 2,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
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
                            _userName.isNotEmpty ? _userName : 'كابتن',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_teamRating > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: Colors.black87),
                                const SizedBox(width: 2),
                                Text(
                                  '$_teamRating',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _teamName.isNotEmpty ? 'فريق: $_teamName ($_position)' : 'تطبيق ملعبي',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              tooltip: 'أرشيف المباريات',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerArchiveScreen(userPhone: widget.userPhone)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              tooltip: 'إعدادات الحساب',
              onPressed: _openPlayerSettingsSheet,
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            PlayerExploreTab(userPhone: widget.userPhone, showOnlyFavorites: false),
            PlayerExploreTab(userPhone: widget.userPhone, showOnlyFavorites: true),
            PlayerBookingsTab(userPhone: widget.userPhone),
            TournamentScreen(userPhone: widget.userPhone, isOwner: false),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE8F5E9),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFF1B5E20)),
              label: 'استكشاف',
            ),
            const NavigationDestination(
              icon: Icon(Icons.star_border_rounded),
              selectedIcon: Icon(Icons.star_rounded, color: Colors.amber),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('phone', whereIn: phoneVariants)
                    .where('seenByPlayer', isEqualTo: false) 
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) { // تم التصحيح هنا: snapshot.data!.docs
                       final d = doc.data() as Map<String, dynamic>;
                       if (d['isDeleted'] != true && !_shouldBeArchived(d)) {
                          unreadCount++;
                       }
                    }
                  }
                  return Badge(
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: Colors.red,
                    label: Text('$unreadCount', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    child: const Icon(Icons.calendar_month_outlined),
                  );
                },
              ),
              selectedIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)),
              label: 'حجوزاتي',
            ),
            const NavigationDestination(
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
