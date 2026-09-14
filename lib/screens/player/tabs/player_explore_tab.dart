import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants.dart';
import '../sheets/player_booking_sheet.dart';

class PlayerExploreTab extends StatefulWidget {
  final String userPhone;
  const PlayerExploreTab({super.key, required this.userPhone});

  @override
  State<PlayerExploreTab> createState() => _PlayerExploreTabState();
}

class _PlayerExploreTabState extends State<PlayerExploreTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat currencyFormatter = NumberFormat('#,###');

  String _searchQuery = '';
  String _selectedGov = 'الكل';
  String _selectedArea = 'الكل';
  String _selectedSurface = 'الكل';
  bool _isLoadingUserLocation = true;

  @override
  void initState() {
    super.initState();
    _loadUserDefaultLocation();
  }

  Future<void> _loadUserDefaultLocation() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userPhone).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        final userGov = (data?['governorate'] ?? '').toString().trim();
        final userArea = (data?['area'] ?? '').toString().trim();

        setState(() {
          if (userGov.isNotEmpty && iraqGovernoratesList.contains(userGov)) {
            _selectedGov = userGov;
            final availableAreas = getAreasListForGov(userGov);
            if (userArea.isNotEmpty && availableAreas.contains(userArea)) {
              _selectedArea = userArea;
            }
          }
          _isLoadingUserLocation = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingUserLocation = false);
    }
  }

  void _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\s+|-'), '');
    if (cleanPhone.startsWith('07')) {
      cleanPhone = '964${cleanPhone.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchWazeToPitch(String pitchName, double? lat, double? lng) async {
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    } else {
      uri = Uri.parse('https://waze.com/ul?q=${Uri.encodeComponent(pitchName)}');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final webUri = Uri.parse(lat != null && lng != null
            ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
            : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(pitchName)}');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          // شريط البحث والفلاتر العلوية
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الملعب، المنطقة، أو المحافظة...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // فلتر المحافظة
                      DropdownButton<String>(
                        value: _selectedGov,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        items: iraqGovernoratesList
                            .map((g) => DropdownMenuItem(value: g, child: Text('📍 $g')))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedGov = v!;
                          _selectedArea = 'الكل';
                        }),
                      ),
                      const SizedBox(width: 8),
                      // فلتر المنطقة
                      DropdownButton<String>(
                        value: getAreasListForGov(_selectedGov).contains(_selectedArea)
                            ? _selectedArea
                            : 'الكل',
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        items: getAreasListForGov(_selectedGov)
                            .map((a) => DropdownMenuItem(value: a, child: Text('🏘️ $a')))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedArea = v!),
                      ),
                      const SizedBox(width: 8),
                      // فلتر الأرضية
                      DropdownButton<String>(
                        value: _selectedSurface,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        items: pitchSurfaceTypesList
                            .map((s) => DropdownMenuItem(value: s, child: Text(s == 'الكل' ? 'الأرضية: الكل' : s)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSurface = v!),
                      ),
                      if (_selectedGov != 'الكل' || _selectedArea != 'الكل' || _selectedSurface != 'الكل') ...[
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.refresh, size: 14, color: Colors.red),
                          label: const Text('عرض الكل', style: TextStyle(fontSize: 11, color: Colors.red)),
                          backgroundColor: Colors.red.shade50,
                          side: BorderSide(color: Colors.red.shade200),
                          onPressed: () {
                            setState(() {
                              _selectedGov = 'الكل';
                              _selectedArea = 'الكل';
                              _selectedSurface = 'الكل';
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // قائمة الملاعب
          Expanded(
            child: _isLoadingUserLocation
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('pitches').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final filteredPitches = docs.where((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final name = (d['name'] ?? '').toString().toLowerCase();
                        final gov = (d['governorate'] ?? '').toString();
                        final area = (d['area'] ?? '').toString();
                        final surface = (d['surfaceType'] ?? '').toString();

                        final matchesQuery = _searchQuery.isEmpty ||
                            name.contains(_searchQuery) ||
                            gov.toLowerCase().contains(_searchQuery) ||
                            area.toLowerCase().contains(_searchQuery);

                        final matchesGov = _selectedGov == 'الكل' || gov == _selectedGov;
                        final matchesArea = _selectedArea == 'الكل' || area == _selectedArea;
                        final matchesSurface = _selectedSurface == 'الكل' || surface == _selectedSurface;

                        return matchesQuery && matchesGov && matchesArea && matchesSurface;
                      }).toList();

                      if (filteredPitches.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stadium_outlined, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _selectedArea != 'الكل'
                                    ? 'لا توجد ملاعب مسجلة حالياً في منطقة ($_selectedArea)'
                                    : 'لا توجد ملاعب مطابقة للبحث أو الفلترة',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.explore_rounded, color: Color(0xFF1B5E20)),
                                label: const Text(
                                  'استكشاف ملاعب كافة المناطق',
                                  style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedGov = 'الكل';
                                    _selectedArea = 'الكل';
                                    _selectedSurface = 'الكل';
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: filteredPitches.length,
                        itemBuilder: (context, idx) {
                          final d = filteredPitches[idx].data() as Map<String, dynamic>;
                          final pName = d['name'] ?? 'ملعب رياضي';
                          final phone = (d['phone'] ?? d['ownerPhone'] ?? '').toString().trim();
                          final price = (d['hourlyRate'] as num?)?.toDouble() ?? 25000.0;
                          final pType = d['pitchType'] ?? 'سباعي';
                          final surface = d['surfaceType'] ?? 'ثيل 🌿';
                          final gov = d['governorate'] ?? '';
                          final area = d['area'] ?? '';
                          final desc = d['description'] ?? '';
                          final lat = (d['latitude'] as num?)?.toDouble();
                          final lng = (d['longitude'] as num?)?.toDouble();

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20), size: 24),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(pName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text('📍 $gov - $area',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade300),
                                        ),
                                        child: Text('${currencyFormatter.format(price)} د.ع',
                                            style: TextStyle(
                                                color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _tagChip(pType, Icons.straighten_rounded, Colors.blue.shade50, Colors.blue.shade800),
                                      _tagChip(surface, Icons.grass_rounded, Colors.teal.shade50, Colors.teal.shade800),
                                      if (desc.toString().isNotEmpty)
                                        _tagChip(desc, Icons.place_outlined, Colors.grey.shade100, Colors.grey.shade700),
                                    ],
                                  ),
                                  const Divider(height: 20),

                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1B5E20),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        icon: const Icon(Icons.event_available_rounded, size: 18),
                                        label: const Text('حجز موعد ⚡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => PlayerBookingSheet(
                                              pitchName: pName,
                                              hourlyRate: price,
                                              userPhone: widget.userPhone,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),

                                      InkWell(
                                        onTap: () => _launchWazeToPitch(pName, lat, lng),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.lightBlue.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.lightBlue.shade300),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.near_me_rounded, color: Colors.blueAccent, size: 16),
                                              SizedBox(width: 4),
                                              Text('Waze', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const Spacer(),

                                      if (phone.isNotEmpty)
                                        InkWell(
                                          onTap: () => _openWhatsApp(phone),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF25D366),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.chat_rounded, color: Colors.white, size: 16),
                                                SizedBox(width: 6),
                                                Text('واتساب', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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
    );
  }

  Widget _tagChip(String label, IconData icon, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}
