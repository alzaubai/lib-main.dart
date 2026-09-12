import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../screens/auth_screen.dart';
import '../screens/tournaments/tournament_screen.dart';

class PlayerMainScreen extends StatefulWidget {
  final String userPhone;
  const PlayerMainScreen({super.key, required this.userPhone});

  @override
  State<PlayerMainScreen> createState() => _PlayerMainScreenState();
}

class _PlayerMainScreenState extends State<PlayerMainScreen> {
  int _currentIndex = 0;
  String _selectedGovernorate = 'بغداد';
  String _selectedArea = 'الكل';
  String _selectedSubArea = 'الكل';
  String _selectedPitchType = 'الكل';
  String _selectedSurfaceType = 'الكل';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currencyFormatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _loadSavedPlayerArea();
  }

  Future<void> _loadSavedPlayerArea() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedGovernorate = prefs.getString('saved_gov') ?? 'بغداد';
      _selectedArea = prefs.getString('saved_area') ?? 'الكل';
      _selectedSubArea = prefs.getString('saved_sub_area') ?? 'الكل';
    });
  }

  Future<void> _savePlayerArea(String gov, String area, String subArea) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_gov', gov);
    await prefs.setString('saved_area', area);
    await prefs.setString('saved_sub_area', subArea);
  }

  Future<void> _toggleFavorite(String pitchDocId, bool isFav) async {
    final favRef = _firestore.collection('players').doc(widget.userPhone).collection('favorites').doc(pitchDocId);
    if (isFav) {
      await favRef.delete();
    } else {
      await favRef.set({'pitchId': pitchDocId, 'addedAt': FieldValue.serverTimestamp()});
    }
  }

  void _openPitchBookingSheet(BuildContext context, String pitchName, double price) {
    DateTime selectedDate = DateTime.now();
    final slots = buildPitchSlots(60);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('جدول مواعيد: $pitchName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 8),
                      Text('التاريخ: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 14)),
                          );
                          if (picked != null) setSheetState(() => selectedDate = picked);
                        },
                        child: const Text('تغيير اليوم'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 12, color: Colors.green),
                      SizedBox(width: 4),
                      Text('متاح للحجز', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 20),
                      Icon(Icons.circle, size: 12, color: Colors.red),
                      SizedBox(width: 4),
                      Text('محجوز مسبقاً', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('bookings').where('pitchName', isEqualTo: pitchName).where('date', isEqualTo: dateStr).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final bookedDocs = snapshot.data!.docs;
                        final bookedSlots = bookedDocs
                            .where((d) => (d.data() as Map)['status'] != 'rejected')
                            .map((d) => '${(d.data() as Map)['startTime']} - ${(d.data() as Map)['endTime']}')
                            .toList();

                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.3,
                          ),
                          itemCount: slots.length,
                          itemBuilder: (context, index) {
                            final slot = slots[index];
                            final isBooked = bookedSlots.contains(slot);

                            return InkWell(
                              onTap: isBooked
                                  ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، هذه الفترة محجوزة مسبقاً')))
                                  : () => _confirmBookSlot(context, pitchName, dateStr, slot, price),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isBooked ? Colors.red.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isBooked ? Colors.red : Colors.green, width: 1.5),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(slot, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isBooked ? Colors.red.shade900 : Colors.green.shade900)),
                                      Text(isBooked ? 'محجوز ❌' : 'متاح للتثبيت ✔️', style: TextStyle(fontSize: 11, color: isBooked ? Colors.red : Colors.green.shade700)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
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

  void _confirmBookSlot(BuildContext context, String pitchName, String dateStr, String slot, double price) {
    final teamCtrl = TextEditingController();
    final times = slot.split(' - ');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد إرسال طلب الحجز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الملعب: $pitchName\nالموعد: $dateStr ($slot)\nالسعر: ${currencyFormatter.format(price)} د.ع'),
              const SizedBox(height: 12),
              TextField(
                controller: teamCtrl,
                decoration: const InputDecoration(labelText: 'اسم فريقك الرياضي', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                if (teamCtrl.text.isNotEmpty) {
                  await _firestore.collection('bookings').add({
                    'pitchName': pitchName,
                    'teamOne': teamCtrl.text.trim(),
                    'teamTwo': 'بانتظار الخصم',
                    'date': dateStr,
                    'startTime': times[0],
                    'endTime': times[1],
                    'phone': widget.userPhone,
                    'price': price,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الحجز بنجاح!'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('إرسال الحجز', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildExploreTab(),
      TournamentScreen(userPhone: widget.userPhone, isOwner: false),
      _buildFavoritesTab(),
      _buildMyBookingsTab(),
      _buildProfileTab(),
    ];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF1B5E20),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'استكشاف'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'البطولات 🏆'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'المفضلة'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'مبارياتي'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'بروفايلي'),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab() {
    final areas = iraqLocations[_selectedGovernorate] ?? ['الكل'];
    final subAreas = subLocationsMap[_selectedArea];

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('استكشاف ملاعب العراق 🏟️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF1B5E20)), onPressed: () => setState(() {})),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGovernorate,
                        decoration: const InputDecoration(labelText: 'المحافظة', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                        items: iraqLocations.keys.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGovernorate = val;
                              _selectedArea = 'الكل';
                              _selectedSubArea = 'الكل';
                            });
                            _savePlayerArea(_selectedGovernorate, _selectedArea, _selectedSubArea);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: areas.contains(_selectedArea) ? _selectedArea : 'الكل',
                        decoration: const InputDecoration(labelText: 'المنطقة', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                        items: areas.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedArea = val;
                              _selectedSubArea = 'الكل';
                            });
                            _savePlayerArea(_selectedGovernorate, _selectedArea, _selectedSubArea);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (subAreas != null) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: subAreas.contains(_selectedSubArea) ? _selectedSubArea : 'الكل',
                    decoration: const InputDecoration(labelText: 'الحي الفرعي الدقيق', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                    items: ['الكل', ...subAreas].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSubArea = val);
                        _savePlayerArea(_selectedGovernorate, _selectedArea, _selectedSubArea);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('pitches').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final pGov = data['governorate'] ?? 'بغداد';
                  final pArea = data['area'] ?? '';
                  final pSubArea = data['subArea'] ?? 'الكل';

                  if (_selectedGovernorate != 'الكل' && pGov != _selectedGovernorate) return false;
                  if (_selectedArea != 'الكل' && pArea != _selectedArea) return false;
                  if (_selectedSubArea != 'الكل' && pSubArea != _selectedSubArea) return false;
                  return true;
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('لا توجد ملاعب مطابقة لبحثك'));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => _buildPitchCard(docs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'ملعب';
    final area = data['area'] ?? 'بغداد';
    final subArea = data['subArea'] ?? '';
    final locationText = subArea.isNotEmpty && subArea != 'الكل' ? '$area - $subArea' : area;
    final price = (data['hourlyRate'] as num?)?.toDouble() ?? 25000.0;
    final type = data['pitchType'] ?? 'سباعي (7 ضد 7)';
    final surface = data['surfaceType'] ?? 'ثيل 🌿';
    final phone = data['phone'] ?? '';
    final desc = data['description'] ?? '';
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('players').doc(widget.userPhone).collection('favorites').doc(doc.id).snapshots(),
      builder: (context, favSnap) {
        final isFav = favSnap.data?.exists ?? false;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)))),
                        IconButton(
                          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                          onPressed: () => _toggleFavorite(doc.id, isFav),
                        ),
                        Chip(label: Text(surface, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    Text('الموقع: $locationText', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    if (desc.toString().isNotEmpty) Text('نقطة دالة: $desc', style: const TextStyle(color: Colors.brown, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${currencyFormatter.format(price)} د.ع / مباراة', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                        Text(type, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.phone, size: 18, color: Colors.green),
                      label: const Text('اتصال', style: TextStyle(color: Colors.green)),
                      onPressed: () => launchCallDirect(phone),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                      label: const Text('واتساب', style: TextStyle(color: Color(0xFF25D366))),
                      onPressed: () => launchWhatsAppDirect(phone),
                    ),
                    if (lat != null && lng != null)
                      TextButton.icon(
                        icon: const Icon(Icons.map, size: 18, color: Colors.blue),
                        label: const Text('الموقع', style: TextStyle(color: Colors.blue)),
                        onPressed: () => showMapChooserSheet(context, lat, lng, name),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                      onPressed: () => _openPitchBookingSheet(context, name, price),
                      child: const Text('عرض المواعيد 📅', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('players').doc(widget.userPhone).collection('favorites').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final favDocs = snapshot.data!.docs;
        if (favDocs.isEmpty) return const Center(child: Text('قائمة المفضلة فارغة'));

        final pitchIds = favDocs.map((d) => d.id).toList();
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('pitches').snapshots(),
          builder: (context, pitchSnap) {
            if (!pitchSnap.hasData) return const Center(child: CircularProgressIndicator());
            final pitches = pitchSnap.data!.docs.where((p) => pitchIds.contains(p.id)).toList();
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pitches.length,
              itemBuilder: (context, index) => _buildPitchCard(pitches[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildMyBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bookings').where('phone', isEqualTo: widget.userPhone).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('لا توجد حجوزات مسجلة برقمك'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['pitchName'] ?? 'ملعب'),
                subtitle: Text('${data['date']} (${data['startTime']} - ${data['endTime']})'),
                trailing: Text(data['status'] == 'upcoming' ? 'مؤكدة ✔️' : (data['status'] == 'pending' ? 'قيد المراجعة' : data['status']), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 40, backgroundColor: Color(0xFF1B5E20), child: Icon(Icons.person, size: 50, color: Colors.white)),
          const SizedBox(height: 12),
          Text(widget.userPhone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
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
      ),
    );
  }
}
