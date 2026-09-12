import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
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

  // تحميل المنطقة المحفوظة مسبقاً للكابتن لتوفير الوقت
  Future<void> _loadSavedPlayerArea() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedGovernorate = prefs.getString('saved_gov') ?? 'بغداد';
      _selectedArea = prefs.getString('saved_area') ?? 'الكل';
      _selectedSubArea = prefs.getString('saved_sub_area') ?? 'الكل';
    });
  }

  // حفظ المنطقة المفضلة للكابتن
  Future<void> _savePlayerArea(String gov, String area, String subArea) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_gov', gov);
    await prefs.setString('saved_area', area);
    await prefs.setString('saved_sub_area', subArea);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
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

  // 1. تبويب استكشاف الملاعب مع الفلاتر الجغرافية الدقيقة وأنواع الأرضيات المتجاوبة
  Widget _buildExploreTab() {
    final areas = iraqLocations[_selectedGovernorate] ?? ['الكل'];
    final subAreas = subLocationsMap[_selectedArea];

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
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF1B5E20)),
                      onPressed: () => setState(() {}),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                // فلاتر المحافظة والمنطقة
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
                        decoration: InputDecoration(labelText: 'المنطقة / القضاء', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: areas.map((area) => DropdownMenuItem(value: area, child: Text(area, overflow: TextOverflow.ellipsis))).toList(),
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
                // فلتر المنطقة الفرعية الدقيقة (يظهر فقط إذا كان للمنطقة فروع)
                if (subAreas != null) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: subAreas.contains(_selectedSubArea) ? _selectedSubArea : 'الكل',
                    decoration: InputDecoration(labelText: 'الحي / المنطقة الدقيقة', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: ['الكل', ...subAreas].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSubArea = val);
                        _savePlayerArea(_selectedGovernorate, _selectedArea, _selectedSubArea);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 10),
                // فلتر نوع الأرضية وحجم الملعب
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: pitchSurfaceTypesList.contains(_selectedSurfaceType) ? _selectedSurfaceType : 'الكل',
                        decoration: InputDecoration(labelText: 'نوع الأرضية', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: pitchSurfaceTypesList.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                        onChanged: (val) => setState(() => _selectedSurfaceType = val ?? 'الكل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: pitchTypesList.contains(_selectedPitchType) ? _selectedPitchType : 'الكل',
                        decoration: InputDecoration(labelText: 'حجم الملعب', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: pitchTypesList.map((pt) => DropdownMenuItem(value: pt, child: Text(pt, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedPitchType = val ?? 'الكل'),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // فلترة الملاعب برمجياً حسب خيارات الكابتن الشاملة
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final pGov = data['governorate'] ?? 'بغداد';
                  final pArea = data['area'] ?? '';
                  final pSubArea = data['subArea'] ?? 'الكل';
                  final pType = data['pitchType'] ?? data['type'] ?? ''; 
                  final pSurface = data['surfaceType'] ?? 'ثيل 🌿';

                  if (_selectedGovernorate != 'الكل' && pGov != _selectedGovernorate) return false;
                  if (_selectedArea != 'الكل' && pArea != _selectedArea) return false;
                  if (_selectedSubArea != 'الكل' && pSubArea != _selectedSubArea) return false;
                  if (_selectedPitchType != 'الكل' && !pType.contains(_selectedPitchType)) return false;
                  if (_selectedSurfaceType != 'الكل' && pSurface != _selectedSurfaceType) return false;

                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stadium_outlined, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('لا توجد ملاعب مطابقة لبحثك', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 600;

                    if (isWide) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) => _buildPitchCard(filteredDocs[index]),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) => _buildPitchCard(filteredDocs[index]),
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

  Widget _buildPitchCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'ملعب رياضي';
    final area = data['area'] ?? 'بغداد';
    final subArea = data['subArea'] ?? '';
    final locationText = subArea.isNotEmpty && subArea != 'الكل' ? '$area - $subArea' : area;
    final price = (data['hourlyRate'] as num?)?.toDouble() ?? (data['price'] as num?)?.toDouble() ?? 15000.0;
    final type = data['pitchType'] ?? data['type'] ?? 'سباعي (7 ضد 7)';
    final surface = data['surfaceType'] ?? 'ثيل 🌿';
    final phone = data['phone'] ?? '';
    final lat = (data['latitude'] as num?)?.toDouble() ?? (data['lat'] as num?)?.toDouble() ?? 33.3128;
    final lng = (data['longitude'] as num?)?.toDouble() ?? (data['lng'] as num?)?.toDouble() ?? 44.3615;

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
                    Chip(
                      label: Text(surface, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green.shade50,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text('الموقع: $locationText', style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 12),
                    const Icon(Icons.sports_soccer, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(type.split(' ')[0], style: const TextStyle(color: Colors.grey, fontSize: 13)), // يطبع خماسي أو سداسي
                  ],
                ),
                const SizedBox(height: 8),
                Text('سعر المباراة: ${currencyFormatter.format(price)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 15)),
              ],
            ),
          ),
          // فوتير الكارت الإجراءات السريعة (اتصال، واتساب، موقع)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('اتصال'),
                  onPressed: () => launchCallDirect(phone),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF25D366)),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('واتساب'),
                  onPressed: () => launchWhatsAppDirect(phone),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('الموقع'),
                  onPressed: () => showMapChooserSheet(context, lat, lng, name),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. تبويب المفضلة
  Widget _buildFavoritesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline_rounded, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('قائمة الملاعب المفضلة فارغة', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 3. تبويب مبارياتي وحجوزاتي
  Widget _buildMyBookingsTab() {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bookings').where('playerPhone', isEqualTo: widget.userPhone).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('لا توجد حجوزات مسجلة باسمك حالياً', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final pitchName = data['pitchName'] ?? 'ملعب';
              final date = data['date'] ?? '';
              final timeSlot = '${data['startTime']} - ${data['endTime']}';
              final status = data['status'] ?? 'pending';

              Color badgeColor = Colors.orange;
              String statusText = 'قيد المراجعة ⏳';
              if (status == 'upcoming' || status == 'confirmed') {
                badgeColor = Colors.green;
                statusText = 'مؤكدة ✔️';
              } else if (status == 'completed') {
                badgeColor = Colors.teal;
                statusText = 'منتهية ومقيمة 🏅';
              } else if (status == 'rejected') {
                badgeColor = Colors.red;
                statusText = 'مرفوضة';
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(pitchName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(statusText, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('التاريخ: $date', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('الوقت: $timeSlot', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

  // 4. تبويب بروفائل اللاعب
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
            const SizedBox(height: 6),
            Text(widget.userPhone, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('saved_phone');
                await prefs.remove('saved_role');
                if (mounted) {
                   Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
