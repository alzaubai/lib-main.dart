import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'auth_screen.dart';

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
            selectedItemColor: const Color(0xFF1B5E20),
            unselectedItemColor: Colors.grey,
            onTap: (idx) {
              setState(() => _currentIndex = idx);
              if (idx == 2 && updatesCount > 0) {
                _markPlayerUpdatesSeen(updatesCount);
              }
            },
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'استكشاف'),
              const BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'المفضلة'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: showMatchBadge,
                  label: Text('$unreadCount', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.sports_soccer),
                ),
                label: 'مبارياتي',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'بروفايلي'),
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

  @override
  Widget build(BuildContext context) {
    final areas = iraqLocations[_selectedGov] ?? ['الكل'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('ملاعب كرة القدم', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGov,
                        decoration: const InputDecoration(labelText: 'المحافظة', isDense: true, border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'المنطقة', isDense: true, border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'نوع الملعب', isDense: true, border: OutlineInputBorder()),
                        items: pitchTypesList.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
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
                          hintText: 'اسم الملعب...',
                          prefixIcon: const Icon(Icons.search, size: 20),
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
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'لا توجد ملاعب مطابقة للبحث في\n$_selectedGov - $_selectedArea (${_selectedPitchType == 'الكل' ? 'جميع الأحجام' : _selectedPitchType})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, height: 1.5),
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
                    final isFav = widget.favPitches.contains(pitchName);

                    final lat = (data['latitude'] as num?)?.toDouble();
                    final lng = (data['longitude'] as num?)?.toDouble();

                    final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
                    final ratingCount = data['ratingCount'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.sports_soccer, color: Color(0xFF1B5E20))),
                            title: Row(
                              children: [
                                Text(pitchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber.shade300)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(ratingCount > 0 ? rating.toStringAsFixed(1) : 'جديد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$gov - $area  |  النوع: $pitchType', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                Text('مدة المباراة: $duration دقيقة  |  السعر: ${rate.toInt()} د.ع', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                              onPressed: () => widget.onToggleFav(pitchName),
                            ),
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
                                      latitude: lat,
                                      longitude: lng,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (lat != null && lng != null) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.location_on, size: 18, color: Colors.blue),
                                    label: const Text('موقع الملعب والاتجاهات (Waze / Maps)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    onPressed: () => showMapChooserSheet(context, lat, lng, pitchName),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
  final double? latitude;
  final double? longitude;

  const PitchScheduleViewScreen({
    super.key,
    required this.pitchName,
    required this.hourlyRate,
    required this.durationMinutes,
    required this.playerPhone,
    this.latitude,
    this.longitude,
  });

  @override
  State<PitchScheduleViewScreen> createState() => _PitchScheduleViewScreenState();
}

class _PitchScheduleViewScreenState extends State<PitchScheduleViewScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final currentDayArabic = getArabicDayName(_selectedDate);
    final slots = buildPitchSlots(widget.durationMinutes);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text('جدول ${widget.pitchName}', style: const TextStyle(color: Colors.white)),
        actions: [
          if (widget.latitude != null && widget.longitude != null)
            IconButton(
              icon: const Icon(Icons.navigation, color: Colors.white),
              tooltip: 'طريق الملعب (Waze / Maps)',
              onPressed: () => showMapChooserSheet(context, widget.latitude!, widget.longitude!, widget.pitchName),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Text('اليوم: $currentDayArabic ($dateStr)', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('تغيير التاريخ'),
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
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.lock_clock, color: Colors.purple),
                              title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('حجز أسبوعي ثابت لفريق: $recurringTeam'),
                              trailing: const Chip(label: Text('حجز دائم', style: TextStyle(color: Colors.purple, fontSize: 11))),
                            ),
                          );
                        }

                        if (bookingDoc == null) {
                          return Card(
                            color: Colors.green.shade50,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(Icons.check_circle, color: Colors.green.shade700),
                              title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('متاح للحجز الكامل (${widget.hourlyRate.toInt()} د.ع) أو طلب تحدي'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                                onPressed: () => _openBookingDialog(context, slot, dateStr),
                                child: const Text('حجز', style: TextStyle(color: Colors.white)),
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
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.flash_on, color: Colors.deepOrange),
                              title: Text('$slot (تحدي مفتوح!)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              subtitle: Text(
                                isMyOwnBooking
                                    ? 'هذا طلب فريقك (${bData['teamOne']})\nبانتظار انضمام فريق منافس'
                                    : 'فريق (${bData['teamOne']}) يبحث عن خصم!\nتكلفة فريقك: ${halfPrice.toInt()} د.ع (النصف فقط)',
                              ),
                              trailing: isMyOwnBooking
                                  ? OutlinedButton(
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () => _cancelMyChallenge(context, bookingDoc.reference),
                                      child: const Text('إلغاء طلبي'),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                                      onPressed: () => _acceptChallengeDialog(context, bookingDoc, bData),
                                      child: const Text('قبول التحدي', style: TextStyle(color: Colors.white)),
                                    ),
                            ),
                          );
                        } else {
                          return Card(
                            color: Colors.red.shade50,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.cancel, color: Colors.red),
                              title: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('محجوز: ${bData['teamOne']} ⚔️ ${bData['teamTwo']}'),
                              trailing: const Chip(label: Text('محجوز', style: TextStyle(color: Colors.red))),
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
              title: Text('طلب حجز ($slot)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: teamCtrl, decoration: const InputDecoration(labelText: 'اسم فريقك', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('عندي فريق خصم جاهز؟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        hasOpponent
                            ? 'المبلغ الإجمالي للحجز: ${fullPrice.toInt()} د.ع'
                            : 'أنت تدفع النصف فقط: ${payablePrice.toInt()} د.ع\n(النصف الثاني يدفعه الخصم عند انضمامه)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلبك بنجاح!'), backgroundColor: Colors.green));
                      }
                    }
                  },
                  child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white)),
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
          title: Text('قبول تحدي فريق (${bData['teamOne']})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: opponentTeamCtrl, decoration: const InputDecoration(labelText: 'اسم فريقك المنافس', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتفك للتأكيد', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Text('المبلغ المطلوب من فريقك: ${halfPrice.toInt()} د.ع فقط (نصف الحجز)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الانضمام وإكمال المباراة بنجاح!'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('تأكيد وقبول التحدي', style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('ملاعبي المفضلة', style: TextStyle(color: Colors.white)),
      ),
      body: favPitches.isEmpty
          ? const Center(child: Text('لم تضف أي ملعب للمفضلة بعد\nاضغط على رمز القلب عند أي ملعب لحفظه هنا', textAlign: TextAlign.center))
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
                    final lat = (data['latitude'] as num?)?.toDouble();
                    final lng = (data['longitude'] as num?)?.toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.stadium, color: Color(0xFF1B5E20), size: 36),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('$gov - $area | $pitchType | $rate د.ع'),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
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
            title: Text('تقييم $pitchName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('كيف كانت تجربتك وجودة الملعب (الثيل، الإضاءة، المرافق)؟'),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starVal = index + 1.0;
                    return IconButton(
                      icon: Icon(
                        selectedStars >= starVal ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setRateState(() => selectedStars = starVal),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(labelText: 'ملاحظة أو تعليق مختصر (اختياري)', border: OutlineInputBorder()),
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
                child: const Text('إرسال التقييم', style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('طلباتي ومبارياتي', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').where('phone', isEqualTo: playerPhone).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('لم تقم بإرسال أي طلبات حجز بعد'));
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
              String statusTxt = 'قيد المراجعة والانتظار';
              if (st == 'upcoming') {
                color = Colors.green;
                statusTxt = 'تم التأكيد والموافقة!';
              } else if (st == 'completed') {
                color = Colors.blueGrey;
                statusTxt = 'مباراة منتهية ومكتملة';
              } else if (st == 'rejected') {
                color = Colors.red;
                statusTxt = 'تم الاعتذار / الرفض';
              }

              return Card(
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
                          Chip(label: Text(statusTxt, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)), backgroundColor: color.withOpacity(0.1)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('التاريخ: ${data['date']}  |  الوقت: ${data['startTime']} - ${data['endTime']}'),
                      Text('المباراة: ${data['teamOne']} ⚔️ ${data['teamTwo']}'),
                      Text('المبلغ: ${data['price']} د.ع'),
                      if (st == 'rejected' && reason.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('سبب الرفض: $reason', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      if (st == 'completed') ...[
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isRated)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                                icon: const Icon(Icons.star, size: 16),
                                label: const Text('تقييم جودة الملعب'),
                                onPressed: () => _openRatePitchDialog(context, doc, pitchName),
                              )
                            else
                              const Row(
                                children: [
                                  Icon(Icons.check, color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text('تم تقييم هذا الملعب', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
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
          title: const Text('تعديل بيانات الملف الشخصي'),
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
                  decoration: const InputDecoration(labelText: 'اسم الفريق الدائم', border: OutlineInputBorder(), prefixIcon: Icon(Icons.shield)),
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
              child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('ملفي الشخصي (كابتن)', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Color(0xFF1B5E20),
                          child: Icon(Icons.person, size: 55, color: Colors.white),
                        ),
                        if (isTrusted)
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.amber,
                            child: Icon(Icons.verified, size: 18, color: Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                    Text(team, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('رقم الهاتف: $playerPhone', style: const TextStyle(color: Colors.blueGrey)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B5E20),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('تعديل بيانات الملف الشخصي'),
                      onPressed: () => _openEditProfileDialog(context, name, team, pin),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.shade200)),
                            child: Column(
                              children: [
                                const Text('إجمالي المباريات', style: TextStyle(color: Colors.grey)),
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
                            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.teal.shade200)),
                            child: Column(
                              children: [
                                const Text('مجموع المبالغ', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text('${currencyFormatter.format(totalSpent)} د.ع', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20)),
                      title: const Text('اسم الفريق المعتمد'),
                      subtitle: Text(team),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone_android, color: Color(0xFF1B5E20)),
                      title: const Text('رقم الهاتف للتواصل الميداني'),
                      subtitle: Text(playerPhone),
                    ),
                    const Divider(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.logout, color: Colors.white),
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
