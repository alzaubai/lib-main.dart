import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
// import '../screens/tournaments/tournament_screen.dart'; // تأكد من المسار

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
  String _selectedPitchType = 'الكل';
  String _selectedSurfaceType = 'الكل';
  List<String> _favoritePitches = []; // قائمة المفضلة
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currencyFormatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _loadSavedPlayerArea();
    _loadFavorites();
  }

  Future<void> _loadSavedPlayerArea() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedGovernorate = prefs.getString('saved_gov') ?? 'بغداد';
      _selectedArea = prefs.getString('saved_area') ?? 'الكل';
    });
  }

  Future<void> _savePlayerArea(String gov, String area) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_gov', gov);
    await prefs.setString('saved_area', area);
  }

  // تحميل المفضلة
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritePitches = prefs.getStringList('favorites_${widget.userPhone}') ?? [];
    });
  }

  // تبديل حالة المفضلة
  Future<void> _toggleFavorite(String pitchId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoritePitches.contains(pitchId)) {
        _favoritePitches.remove(pitchId);
      } else {
        _favoritePitches.add(pitchId);
      }
    });
    await prefs.setStringList('favorites_${widget.userPhone}', _favoritePitches);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildExploreTab(),
      const Center(child: Text("شاشة البطولات")), // TournamentScreen(userPhone: widget.userPhone, isOwner: false),
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
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'البطولات'),
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
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('استكشاف ملاعب العراق 🏟️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF1B5E20)), onPressed: () => setState(() {}))
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGovernorate,
                        decoration: InputDecoration(labelText: 'المحافظة', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: iraqLocations.keys.map((gov) => DropdownMenuItem(value: gov, child: Text(gov))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGovernorate = val;
                              _selectedArea = 'الكل';
                            });
                            _savePlayerArea(_selectedGovernorate, _selectedArea);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: areas.contains(_selectedArea) ? _selectedArea : 'الكل',
                        decoration: InputDecoration(labelText: 'المنطقة', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: areas.map((area) => DropdownMenuItem(value: area, child: Text(area, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedArea = val);
                            _savePlayerArea(_selectedGovernorate, _selectedArea);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('pitches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_selectedGovernorate != 'الكل' && data['governorate'] != _selectedGovernorate) return false;
                  if (_selectedArea != 'الكل' && data['area'] != _selectedArea) return false;
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('لا توجد ملاعب مطابقة لبحثك', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) => _buildPitchCard(filteredDocs[index]),
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
    final pitchId = doc.id;
    final name = data['name'] ?? 'ملعب رياضي';
    final area = data['area'] ?? 'بغداد';
    final price = (data['price'] as num?)?.toDouble() ?? 25000.0;
    final type = data['type'] ?? 'خماسي';
    final surface = data['surfaceType'] ?? 'ثيل 🌿';
    final phone = data['phone'] ?? '';
    final isFav = _favoritePitches.contains(pitchId);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)))),
                    IconButton(
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                      onPressed: () => _toggleFavorite(pitchId),
                    ),
                  ],
                ),
                Text('سعر الساعة: ${currencyFormatter.format(price)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 15)),
                const SizedBox(height: 12),
                // تم إضافة زر الحجز الذي كان مفقوداً
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF57F17), foregroundColor: Colors.white),
                    child: const Text("احجز الآن", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      // هنا تفتح BottomSheet أو Screen لاختيار الأوقات باستخدام buildPitchSlots
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم فتح شاشة الأوقات...')));
                    },
                  ),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(icon: const Icon(Icons.phone, size: 18), label: const Text('اتصال'), onPressed: () => launchCallDirect(phone)),
                TextButton.icon(icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)), label: const Text('واتساب', style: TextStyle(color: Color(0xFF25D366))), onPressed: () => launchWhatsAppDirect(phone)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تفعيل مفضلة اللاعب برمجياً
  Widget _buildFavoritesTab() {
    return SafeArea(
      child: _favoritePitches.isEmpty 
      ? const Center(child: Text('لا توجد ملاعب في المفضلة', style: TextStyle(color: Colors.grey, fontSize: 16)))
      : StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('pitches').where(FieldPath.documentId, whereIn: _favoritePitches).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data?.docs ?? [];
            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: docs.length,
              itemBuilder: (context, index) => _buildPitchCard(docs[index]),
            );
          },
      ),
    );
  }

  Widget _buildMyBookingsTab() {
     // ... [نفس كود التبويب السابق الخاص بالحجوزات]
     return const Center(child: Text("قائمة الحجوزات"));
  }

  // تم حل مشكلة تسجيل الخروج بمسح الجلسة
  Widget _buildProfileTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFF1B5E20), child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 16),
            const Text('كابتن الفريق الرياضي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(widget.userPhone, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // مسح الجلسة تماماً لحل خطأ الحلقة المغلقة
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }
}
