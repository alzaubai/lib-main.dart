import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'auth_screen.dart';
import 'tournaments/tournament_screen.dart';

class PlayerMainScreen extends StatefulWidget {
  final String playerPhone;
  const PlayerMainScreen({super.key, required this.playerPhone});

  @override
  State<PlayerMainScreen> createState() => _PlayerMainScreenState();
}

class _PlayerMainScreenState extends State<PlayerMainScreen> {
  int _currentIndex = 0;
  List<String> _favPitches = [];
  int _lastSeenUpdatesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadPlayerBadgeCache();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favPitches = prefs.getStringList('fav_pitches') ?? [];
    });
  }

  Future<void> _loadPlayerBadgeCache() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSeenUpdatesCount = prefs.getInt('player_seen_updates_${widget.playerPhone}') ?? 0;
    });
  }

  Future<void> _markPlayerUpdatesSeen(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_seen_updates_${widget.playerPhone}', count);
    setState(() {
      _lastSeenUpdatesCount = count;
    });
  }

  Future<void> _toggleFavorite(String pitchName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favPitches.contains(pitchName)) {
        _favPitches.remove(pitchName);
      } else {
        _favPitches.add(pitchName);
      }
    });
    await prefs.setStringList('fav_pitches', _favPitches);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('phone', isEqualTo: widget.playerPhone).snapshots(),
      builder: (context, snapshot) {
        int updatesCount = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final st = (doc.data() as Map<String, dynamic>)['status'];
            if (st == 'upcoming' || st == 'rejected') updatesCount++;
          }
        }

        final unreadCount = updatesCount - _lastSeenUpdatesCount;
        final showMatchBadge = unreadCount > 0;

        final pages = [
          PlayerExplorePitchesTab(
            favPitches: _favPitches,
            onToggleFav: _toggleFavorite,
            playerPhone: widget.playerPhone,
          ),
          TournamentScreen(
            userPhone: widget.playerPhone,
            isOwner: false,
          ),
          PlayerFavoritesTab(
            favPitches: _favPitches,
            onToggleFav: _toggleFavorite,
            playerPhone: widget.playerPhone,
          ),
          PlayerMyBookingsTab(playerPhone: widget.playerPhone),
          PlayerProfileTab(playerPhone: widget.playerPhone),
        ];

        return Scaffold(
          body: pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1B5E20),
            unselectedItemColor: Colors.grey.shade500,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 10,
            onTap: (idx) {
              setState(() => _currentIndex = idx);
              if (idx == 3 && updatesCount > 0) {
                _markPlayerUpdatesSeen(updatesCount);
              }
            },
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'استكشاف'),
              const BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'البطولات 🏆'),
              const BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'المفضلة'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: showMatchBadge,
                  label: Text('$unreadCount', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.sports_soccer_rounded),
                ),
                label: 'مبارياتي',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'بروفايلي'),
            ],
          ),
        );
      },
    );
  }
}

class PlayerExplorePitchesTab extends StatefulWidget {
  final List<String> favPitches;
  final Function(String) onToggleFav;
  final String playerPhone;

  const PlayerExplorePitchesTab({super.key, required this.favPitches, required this.onToggleFav, required this.playerPhone});

  @override
  State<PlayerExplorePitchesTab> createState() => _PlayerExplorePitchesTabState();
}

class _PlayerExplorePitchesTabState extends State<PlayerExplorePitchesTab> {
  String _selectedGov = 'بغداد';
  String _selectedArea = 'الكل';
  String _selectedPitchType = 'الكل';
  String _search = '';
  final currencyFormatter = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final areas = iraqLocations[_selectedGov] ?? ['الكل'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('استكشف ملاعب العراق', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGov,
                        decoration: InputDecoration(
                          labelText: 'المحافظة',
                          isDense: true,
                          prefixIcon: const Icon(Icons.location_city, size: 18, color: Color(0xFF1B5E20)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: iraqLocations.keys.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGov = val;
                              _selectedArea = 'الكل';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedArea,
                        decoration: InputDecoration(
                          labelText: 'المنطقة',
                          isDense: true,
                          prefixIcon: const Icon(Icons.place, size: 18, color: Color(0xFF1B5E20)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedArea = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPitchType,
                        decoration: InputDecoration(
                          labelText: 'حجم الملعب',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: pitchTypesList.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPitchType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'بحث باسم الملعب...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pitches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final gov = data['governorate'] ?? 'بغداد';
                  final area = data['area'] ?? '';
                  final pitchType = data['pitchType'] ?? 'سباعي (7 ضد 7)';
                  final name = (data['name'] ?? '').toString().toLowerCase();

                  final matchesGov = gov == _selectedGov;
                  final matchesArea = _selectedArea == 'الكل' || area == _selectedArea;
                  final matchesType = _selectedPitchType == 'الكل' || pitchType == _selectedPitchType;
                  final matchesSearch = name.contains(_search);

                  return matchesGov && matchesArea && matchesType && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer_outlined, size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد ملاعب مطابقة لبحثك في\n$_selectedGov - $_selectedArea',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index].data() as Map<String, dynamic>;
                    final pitchName = data['name'] ?? 'ملعب';
                    final area = data['area'] ?? '';
                    final gov = data['governorate'] ?? '';
                    final pitchType = data['pitchType'] ?? 'ملعب سباعي';
                    final rate = (data['hourlyRate'] as num?)?.toDouble() ?? 15000.0;
                    final duration = data['matchDurationMinutes'] ?? 60;
                    final pitchPhone = data['phone'] ?? '';
                    final isFav = widget.favPitches.contains(pitchName);

                    final lat = (data['latitude'] as num?)?.toDouble();
                    final lng = (data['longitude'] as num?)?.toDouble();

                    final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
                    final ratingCount = data['ratingCount'] ?? 0;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          InkWell(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Directionality(
                                    textDirection: ui.TextDirection.rtl,
                                    child: PitchScheduleViewScreen(
                                      pitchName: pitchName,
                                      hourlyRate: rate,
                                      durationMinutes: duration,
                                      playerPhone: widget.playerPhone,
                                      pitchPhone: pitchPhone,
                                      latitude: lat,
                                      longitude: lng,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFFE8F5E9),
                                    child: const Icon(Icons.stadium, color: Color(0xFF1B5E20), size: 30),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade300)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                                                  const SizedBox(width: 3),
                                                  Text(ratingCount > 0 ? rating.toStringAsFixed(1) : 'جديد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                            const SizedBox(width: 2),
                                            Text('$gov - $area  •  $pitchType', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6)),
                                          child: Text(
                                            'سعر المباراة: ${currencyFormatter.format(rate)} د.ع ($duration دقيقة)',
                                            style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? Colors.red : Colors.grey.shade400),
                                    onPressed: () => widget.onToggleFav(pitchName),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Container(
                            color: Colors.grey.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: Row(
                              children: [
                                if (lat != null && lng != null) ...[
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue.shade800,
                                      side: BorderSide(color: Colors.blue.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.navigation_rounded, size: 16, color: Colors.blue),
                                    label: const Text('الموقع (Waze)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => showMapChooserSheet(context, lat, lng, pitchName),
                                  ),
                                ],
                                const Spacer(),
                                if (pitchPhone.toString().isNotEmpty) ...[
                                  IconButton(
                                    style: IconButton.styleFrom(backgroundColor: Colors.green.shade50),
                                    icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 18),
                                    tooltip: 'اتصال هاتفي',
                                    onPressed: () => launchCallDirect(pitchPhone),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.chat_bubble_rounded, size: 15),
                                    label: const Text('واتساب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => launchWhatsAppDirect(pitchPhone),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PitchScheduleViewScreen extends StatefulWidget {
  final String pitchName;
  final double hourlyRate;
  final int durationMinutes;
  final String playerPhone;
  final String pitchPhone;
  final double? latitude;
  final double? longitude;

  const PitchScheduleViewScreen({
    super.key,
    required this.pitchName,
    required this.hourlyRate,
    required this.durationMinutes,
    required this.playerPhone,
    required this.pitchPhone,
    this.latitude,
    this.longitude,
  });

  @override
  State<PitchScheduleViewScreen> createState() => _PitchScheduleViewScreenState();
}

class _PitchScheduleViewScreenState extends State<PitchScheduleViewScreen> {
  DateTime _selectedDate = DateTime.now();
  final currencyFormatter = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final currentDayArabic = getArabicDayName(_selectedDate);
    final slots = buildPitchSlots(widget.durationMinutes);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: Text('جدول ${widget.pitchName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (widget.pitchPhone.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.phone_rounded, color: Colors.white),
              tooltip: 'اتصال بصاحب الملعب',
              onPressed: () => launchCallDirect(widget.pitchPhone),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
              tooltip: 'محادثة واتساب',
              onPressed: () => launchWhatsAppDirect(widget.pitchPhone),
            ),
          ],
          if (widget.latitude != null && widget.longitude != null)
            IconButton(
              icon: const Icon(Icons.navigation_rounded, color: Colors.white),
              tooltip: 'طريق الملعب (Waze / Maps)',
              onPressed: () => showMapChooserSheet(context, widget.latitude!, widget.longitude!, widget.pitchName),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Text('$currentDayArabic ($dateStr)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    foregroundColor: const Color(0xFF1B5E20),
                  ),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                  label: const Text('تغيير اليوم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('recurring_rules').where('pitchName', isEqualTo: widget.pitchName).where('dayOfWeek', isEqualTo: currentDayArabic).snapshots(),
              builder: (context, recurringSnap) {
                final recurringDocs = recurringSnap.data?.docs ?? [];
                final Map<String, String> recurringMap = {};
                for (var r in recurringDocs) {
                  final rd = r.data() as Map<String, dynamic>;
                  recurringMap[rd['timeSlot']] = rd['teamName'];
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bookings').where('pitchName', isEqualTo: widget.pitchName).where('date', isEqualTo: dateStr).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data?.docs ?? [];
                    final Map<String, DocumentSnapshot> bookedMap = {};

                    for (var d in docs) {
                      final data = d.data() as Map<String, dynamic>;
                      final slotKey = '${data['startTime']} - ${data['endTime']}';
                      final st = data['status'];
                      if (st == 'upcoming' || st == 'pending' || st == 'completed') {
                        bookedMap[slotKey] = d;
                      }
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final bookingDoc = bookedMap[slot];
                        final recurringTeam = recurringMap[slot];

                        if (recurringTeam != null) {
                          return Card(
                            color: Colors.purple.shade50,
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.purple.shade200)),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(Icons.lock_clock_rounded, color: Colors.purple),
                              title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('حجز أسبوعي ثابت لفريق: $recurringTeam'),
                              trailing: const Chip(label: Text('حجز دائم', style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold))),
                            ),
                          );
                        }

                        if (bookingDoc == null) {
                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.green.shade200)),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 28),
                              title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('متاح للحجز الكامل (${currencyFormatter.format(widget.hourlyRate)} د.ع) أو طلب تحدي'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B5E20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _openBookingDialog(context, slot, dateStr),
                                child: const Text('حجز الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        }

                        final bData = bookingDoc.data() as Map<String, dynamic>;
                        final isLookingForOpponent = bData['teamTwo'] == 'بانتظار الخصم';
                        final creatorPhone = bData['phone'] ?? '';
                        final isMyOwnBooking = creatorPhone == widget.playerPhone;

                        if (isLookingForOpponent) {
                          final halfPrice = widget.hourlyRate / 2;

                          return Card(
                            color: Colors.orange.shade50,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.orange.shade300)),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(Icons.bolt_rounded, color: Colors.deepOrange, size: 30),
                              title: Text('$slot (مباراة تحدي مفتوحة!)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              subtitle: Text(
                                isMyOwnBooking
                                    ? 'هذا طلب فريقك (${bData['teamOne']})\nبانتظار قبول فريق منافس'
                                    : 'فريق (${bData['teamOne']}) بانتظار خصم!\nحصتكم: ${currencyFormatter.format(halfPrice)} د.ع (نصف الإيجار)',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: isMyOwnBooking
                                  ? OutlinedButton(
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () => _cancelMyChallenge(context, bookingDoc.reference),
                                      child: const Text('إلغاء طلبي'),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      onPressed: () => _acceptChallengeDialog(context, bookingDoc, bData),
                                      child: const Text('قبول التحدي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                            ),
                          );
                        } else {
                          return Card(
                            color: Colors.grey.shade100,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
                              title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              subtitle: Text('محجوز: ${bData['teamOne']} ⚔️ ${bData['teamTwo']}'),
                              trailing: const Chip(label: Text('محجوز', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11))),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _cancelMyChallenge(BuildContext context, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إلغاء طلب التحدي'),
          content: const Text('هل تريد سحب طلبك وإلغاء هذا الحجز؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await docRef.delete();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('نعم، إلغاء الحجز', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openBookingDialog(BuildContext context, String slot, String dateStr) {
    final teamCtrl = TextEditingController();
    final opponentCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: widget.playerPhone == 'owner_preview' ? '' : widget.playerPhone);
    bool hasOpponent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final fullPrice = widget.hourlyRate;
          final halfPrice = fullPrice / 2;
          final payablePrice = hasOpponent ? fullPrice : halfPrice;

          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('طلب حجز ($slot)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: teamCtrl, decoration: const InputDecoration(labelText: 'اسم فريقك', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('عندي فريق خصم جاهز؟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      value: hasOpponent,
                      onChanged: (val) => setDlgState(() => hasOpponent = val),
                    ),
                    if (hasOpponent) ...[
                      const SizedBox(height: 8),
                      TextField(controller: opponentCtrl, decoration: const InputDecoration(labelText: 'اسم فريق الخصم', border: OutlineInputBorder())),
                    ],
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتفك للتأكيد', border: OutlineInputBorder())),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                      child: Text(
                        hasOpponent
                            ? 'المبلغ الإجمالي للمباراة: ${currencyFormatter.format(fullPrice)} د.ع'
                            : 'أنت تدفع النصف فقط: ${currencyFormatter.format(payablePrice)} د.ع\n(النصف الثاني يدفعه الخصم عند انضمامه)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                  onPressed: () async {
                    if (teamCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                      final times = slot.split(' - ');
                      await FirebaseFirestore.instance.collection('bookings').add({
                        'pitchName': widget.pitchName,
                        'teamOne': teamCtrl.text.trim(),
                        'teamTwo': hasOpponent ? opponentCtrl.text.trim() : 'بانتظار الخصم',
                        'startTime': times[0],
                        'endTime': times.length > 1 ? times[1] : '',
                        'phone': phoneCtrl.text.trim(),
                        'price': payablePrice,
                        'totalMatchPrice': fullPrice,
                        'date': dateStr,
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الحجز بنجاح وبانتظار موافقة الملعب'), backgroundColor: Colors.green));
                      }
                    }
                  },
                  child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _acceptChallengeDialog(BuildContext context, DocumentSnapshot doc, Map<String, dynamic> bData) {
    final opponentTeamCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: widget.playerPhone == 'owner_preview' ? '' : widget.playerPhone);
    final halfPrice = widget.hourlyRate / 2;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('قبول تحدي فريق (${bData['teamOne']})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: opponentTeamCtrl, decoration: const InputDecoration(labelText: 'اسم فريقك المنافس', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتفك للتأكيد', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Text('المبلغ المطلوب من فريقكم: ${currencyFormatter.format(halfPrice)} د.ع فقط', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () async {
                if (opponentTeamCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  await doc.reference.update({
                    'teamTwo': opponentTeamCtrl.text.trim(),
                    'challengerPhone': phoneCtrl.text.trim(),
                    'price': widget.hourlyRate,
                  });

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تأكيد انضمامك للتحدي بنجاح!'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('تأكيد وقبول التحدي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerFavoritesTab extends StatelessWidget {
  final List<String> favPitches;
  final Function(String) onToggleFav;
  final String playerPhone;

  const PlayerFavoritesTab({super.key, required this.favPitches, required this.onToggleFav, required this.playerPhone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('ملاعبي المفضلة', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: favPitches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('قائمتك المفضلة فارغة', style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('اضغط على رمز القلب عند أي ملعب لحفظه هنا', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pitches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs.where((d) => favPitches.contains(d.id)).toList() ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'ملعب';
                    final area = data['area'] ?? '';
                    final gov = data['governorate'] ?? '';
                    final pitchType = data['pitchType'] ?? 'ملعب سباعي';
                    final rate = (data['hourlyRate'] as num?)?.toDouble() ?? 15000.0;
                    final duration = data['matchDurationMinutes'] ?? 60;
                    final pitchPhone = data['phone'] ?? '';
                    final lat = (data['latitude'] as num?)?.toDouble();
                    final lng = (data['longitude'] as num?)?.toDouble();

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.stadium, color: Color(0xFF1B5E20))),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('$gov - $area | $pitchType | ${rate.toInt()} د.ع'),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                          onPressed: () => onToggleFav(name),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Directionality(
                                textDirection: ui.TextDirection.rtl,
                                child: PitchScheduleViewScreen(
                                  pitchName: name,
                                  hourlyRate: rate,
                                  durationMinutes: duration,
                                  playerPhone: playerPhone,
                                  pitchPhone: pitchPhone,
                                  latitude: lat,
                                  longitude: lng,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class PlayerMyBookingsTab extends StatelessWidget {
  final String playerPhone;
  const PlayerMyBookingsTab({super.key, required this.playerPhone});

  void _openRatePitchDialog(BuildContext context, DocumentSnapshot doc, String pitchName) {
    double selectedStars = 5.0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setRateState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('تقييم $pitchName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('كيف كانت جودة الملعب وتجربة اللعب فيه؟'),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starVal = index + 1.0;
                    return IconButton(
                      icon: Icon(
                        selectedStars >= starVal ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 34,
                      ),
                      onPressed: () => setRateState(() => selectedStars = starVal),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(labelText: 'ملاحظة مختصرة للملعب (اختياري)', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                onPressed: () async {
                  await doc.reference.update({
                    'isRated': true,
                    'ratingScore': selectedStars,
                    'ratingComment': commentCtrl.text.trim(),
                  });

                  final pitchRef = FirebaseFirestore.instance.collection('pitches').doc(pitchName);
                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    final pSnapshot = await transaction.get(pitchRef);
                    if (pSnapshot.exists) {
                      final pData = pSnapshot.data() as Map<String, dynamic>;
                      final currentRating = (pData['rating'] as num?)?.toDouble() ?? 5.0;
                      final count = (pData['ratingCount'] as num?)?.toInt() ?? 0;

                      final newCount = count + 1;
                      final newAverage = ((currentRating * count) + selectedStars) / newCount;

                      transaction.update(pitchRef, {
                        'rating': double.parse(newAverage.toStringAsFixed(1)),
                        'ratingCount': newCount,
                      });
                    }
                  });

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكراً لتقييمك للملعب!'), backgroundColor: Colors.green));
                  }
                },
                child: const Text('إرسال التقييم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('طلباتي ومبارياتي', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').where('phone', isEqualTo: playerPhone).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('لم تسجل أي حجوزات بعد', style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('تصفح الملاعب واحجز موعد مباراتك القادمة', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final st = data['status'] ?? 'pending';
              final reason = data['rejectReason'] ?? '';
              final pitchName = data['pitchName'] ?? 'الملعب';
              final isRated = data['isRated'] == true;

              Color color = Colors.orange;
              String statusTxt = 'قيد المراجعة والانتظار ⏳';
              if (st == 'upcoming') {
                color = Colors.green;
                statusTxt = 'تم التأكيد والموافقة! ✔️';
              } else if (st == 'completed') {
                color = Colors.blueGrey;
                statusTxt = 'مباراة منتهية ومكتملة ⚽';
              } else if (st == 'rejected') {
                color = Colors.red;
                statusTxt = 'تم الاعتذار / الرفض ❌';
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(statusTxt, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('التاريخ: ${data['date']}  |  الوقت: ${data['startTime']} - ${data['endTime']}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('المباراة: ${data['teamOne']} ⚔️ ${data['teamTwo']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                      Text('المبلغ: ${data['price']} د.ع', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      if (st == 'rejected' && reason.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('سبب الاعتذار: $reason', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                      if (st == 'completed') ...[
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isRated)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                icon: const Icon(Icons.star_rounded, size: 16),
                                label: const Text('تقييم جودة الملعب'),
                                onPressed: () => _openRatePitchDialog(context, doc, pitchName),
                              )
                            else
                              const Row(
                                children: [
                                  Icon(Icons.verified_rounded, color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text('تم تقييم هذا الملعب بنجاح', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PlayerProfileTab extends StatelessWidget {
  final String playerPhone;
  const PlayerProfileTab({super.key, required this.playerPhone});

  void _openEditProfileDialog(BuildContext context, String currentName, String currentTeam, String currentPin) {
    final nameCtrl = TextEditingController(text: currentName);
    final teamCtrl = TextEditingController(text: currentTeam);
    final pinCtrl = TextEditingController(text: currentPin);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الكابتن / اللاعب', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teamCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الفريق المعتمد', border: OutlineInputBorder(), prefixIcon: Icon(Icons.shield)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'رمز PIN للدخول (4 أرقام)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newTeam = teamCtrl.text.trim();
                final newPin = pinCtrl.text.trim();

                if (newName.isNotEmpty && newPin.length == 4) {
                  await FirebaseFirestore.instance.collection('players').doc(playerPhone).update({
                    'name': newName,
                    'teamName': newTeam.isEmpty ? 'فريق $newName' : newTeam,
                    'pin': newPin,
                  });

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات بنجاح'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('الملف الشخصي للكابتن', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'تسجيل خروج',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('current_player_phone');
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('players').doc(playerPhone).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? 'كابتن الفريق';
          final team = data?['teamName'] ?? 'فريق غير محدد';
          final pin = data?['pin'] ?? '';
          final isTrusted = data?['isTrustedTeam'] == true;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').where('phone', isEqualTo: playerPhone).snapshots(),
            builder: (context, bookingSnap) {
              int totalMatches = 0;
              double totalSpent = 0;

              if (bookingSnap.hasData) {
                totalMatches = bookingSnap.data!.docs.length;
                for (var b in bookingSnap.data!.docs) {
                  final bd = b.data() as Map<String, dynamic>;
                  if (bd['status'] == 'completed' || bd['status'] == 'upcoming') {
                    totalSpent += (bd['price'] as num?)?.toDouble() ?? 0.0;
                  }
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: const Color(0xFF1B5E20),
                          child: const Icon(Icons.sports_soccer_rounded, size: 50, color: Colors.white),
                        ),
                        if (isTrusted)
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.amber,
                            child: Icon(Icons.verified_rounded, size: 18, color: Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        if (isTrusted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
                            child: const Text('فريق موثوق 🏅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
                          ),
                        ],
                      ],
                    ),
                    Text(team, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('رقم الهاتف: $playerPhone', style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B5E20),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('تعديل الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _openEditProfileDialog(context, name, team, pin),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                            child: Column(
                              children: [
                                const Text('إجمالي المباريات', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text('$totalMatches', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                            child: Column(
                              children: [
                                const Text('مجموع المبالغ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text('${currencyFormatter.format(totalSpent)} د.ع', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20)),
                            title: const Text('اسم الفريق المعتمد'),
                            subtitle: Text(team),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.phone_android_rounded, color: Color(0xFF1B5E20)),
                            title: const Text('رقم الهاتف للتواصل الميداني'),
                            subtitle: Text(playerPhone),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      label: const Text('تسجيل خروج من الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('current_player_phone');
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
