import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'auth_screen.dart';
import 'player/tabs/player_explore_tab.dart';
import 'player/tabs/player_bookings_tab.dart';
import 'tournaments/tournament_screen.dart';

class PlayerScreen extends StatefulWidget {
  final String userPhone;

  const PlayerScreen({super.key, required this.userPhone});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _currentIndex = 0;

  // بيانات اللاعب
  String _userName = '';
  String _teamName = '';
  String _position = 'مهاجم ⚽';
  String _governorate = 'بغداد';
  String _area = 'الكرخ';
  double _teamRating = 5.0;
  int _matchesPlayed = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).get();
      if (doc.exists && mounted) {
        final d = doc.data()!;
        setState(() {
          _userName = (d['name'] ?? 'كابتن').toString();
          _teamName = (d['teamName'] ?? '').toString();
          _position = (d['position'] ?? 'مهاجم ⚽').toString();
          _governorate = (d['governorate'] ?? 'بغداد').toString();
          _area = (d['area'] ?? 'الكرخ').toString();
          _teamRating = (d['teamRating'] as num?)?.toDouble() ?? 5.0;
          _matchesPlayed = (d['matchesPlayed'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  void _openPlayerSettingsSheet() {
    final nameCtrl = TextEditingController(text: _userName);
    final teamCtrl = TextEditingController(text: _teamName);
    String selectedPos = _position;
    String selectedGov = _governorate;
    String selectedArea = _area;
    bool isSaving = false;

    final positionsList = [
      'حارس مرمى 🧤',
      'مدافع 🛡️',
      'خط وسط ⚙️',
      'جناح ⚡',
      'مهاجم ⚽',
    ];

    if (!positionsList.contains(selectedPos)) selectedPos = 'مهاجم ⚽';

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
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 12),

                  // شريط العنوان
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.manage_accounts_rounded, color: Color(0xFF1B5E20), size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'إعدادات الملف الشخصي والكابتن',
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
                          // كرت التقييم
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
                                  radius: 24,
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20), size: 26),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        teamCtrl.text.isNotEmpty ? teamCtrl.text : 'فريقك الكروي',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
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
                                                  'تقييم الفريق: $_teamRating',
                                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('$_matchesPlayed مباريات مكتملة', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // الحقول
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
                                const Text('البيانات الأساسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'الاسم الكامل',
                                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1B5E20)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: teamCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'اسم فريقك',
                                    prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1B5E20)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                                const SizedBox(height: 12),
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
                                const SizedBox(height: 12),
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
                          const SizedBox(height: 20),

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
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(Icons.check_circle_rounded, color: Colors.white),
                                                SizedBox(width: 8),
                                                Text('تم تحديث بياناتك بنجاح ✔️'),
                                              ],
                                            ),
                                            backgroundColor: const Color(0xFF1B5E20),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                            tileColor: Colors.red.shade50,
                            leading: Icon(Icons.logout_rounded, color: Colors.red.shade700),
                            title: Text(
                              'تسجيل الخروج من الحساب',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                            ),
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                                  (route) => false,
                                );
                              }
                            },
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
                    .where('phone', isEqualTo: widget.userPhone)
                    .where('seenByPlayer', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final unread = snapshot.data?.docs.length ?? 0;
                  return Badge(
                    isLabelVisible: unread > 0,
                    backgroundColor: Colors.red,
                    label: Text('$unread', style: const TextStyle(fontSize: 10, color: Colors.white)),
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
