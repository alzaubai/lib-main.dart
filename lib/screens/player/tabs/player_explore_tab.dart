import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../constants.dart';
import '../../../services/location_service.dart';
import '../widgets/pitch_explore_card.dart';

class PlayerExploreTab extends StatefulWidget {
  final String userPhone;
  final bool showOnlyFavorites;

  const PlayerExploreTab({
    super.key,
    required this.userPhone,
    this.showOnlyFavorites = false,
  });

  @override
  State<PlayerExploreTab> createState() => _PlayerExploreTabState();
}

class _PlayerExploreTabState extends State<PlayerExploreTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedGov = 'الكل';
  String _selectedArea = 'الكل';
  String _selectedSurface = 'الكل';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    _currentPosition = await LocationService.getCurrentLocation();
    if (mounted) setState(() {});
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

  Future<void> _toggleFavorite(String pitchName, bool isCurrentlyFav) async {
    try {
      if (isCurrentlyFav) {
        await _firestore.collection('users').doc(widget.userPhone).set({
          'favorites': FieldValue.arrayRemove([pitchName]),
        }, SetOptions(merge: true));
        _showCenterToast('تمت الإزالة من المفضلة');
      } else {
        await _firestore.collection('users').doc(widget.userPhone).set({
          'favorites': FieldValue.arrayUnion([pitchName]),
        }, SetOptions(merge: true));
        _showCenterToast('تمت الإضافة إلى المفضلة');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.userPhone).snapshots(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>?;
          final List<String> favoritePitches = List<String>.from(userData?['favorites'] ?? []);

          return Column(
            children: [
              if (!widget.showOnlyFavorites) _buildFilterHeader(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('pitches').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    List<Map<String, dynamic>> pitchesWithDistance = [];

                    for (var doc in docs) {
                      final d = doc.data() as Map<String, dynamic>;
                      final pName = (d['name'] ?? doc.id).toString();
                      final nameLower = pName.toLowerCase();
                      final gov = (d['governorate'] ?? '').toString();
                      final area = (d['area'] ?? '').toString();
                      final surface = (d['surfaceType'] ?? '').toString();

                      if (widget.showOnlyFavorites && !favoritePitches.contains(pName)) {
                        continue;
                      }

                      final matchesQuery = _searchQuery.isEmpty ||
                          nameLower.contains(_searchQuery) ||
                          gov.toLowerCase().contains(_searchQuery) ||
                          area.toLowerCase().contains(_searchQuery);

                      final matchesGov = _selectedGov == 'الكل' || gov == _selectedGov;
                      final matchesArea = _selectedArea == 'الكل' || area == _selectedArea;
                      final matchesSurface = _selectedSurface == 'الكل' || surface == _selectedSurface;

                      if (matchesQuery && matchesGov && matchesArea && matchesSurface) {
                        double? distKm;
                        final lat = (d['latitude'] as num?)?.toDouble();
                        final lng = (d['longitude'] as num?)?.toDouble();

                        if (_currentPosition != null && lat != null && lng != null) {
                          distKm = LocationService.calculateDistanceKm(
                            startLatitude: _currentPosition!.latitude,
                            startLongitude: _currentPosition!.longitude,
                            endLatitude: lat,
                            endLongitude: lng,
                          );
                        }

                        final mapItem = Map<String, dynamic>.from(d);
                        mapItem['name'] = pName;
                        mapItem['calculatedDistance'] = distKm;
                        pitchesWithDistance.add(mapItem);
                      }
                    }

                    pitchesWithDistance.sort((a, b) {
                      final double? d1 = a['calculatedDistance'];
                      final double? d2 = b['calculatedDistance'];
                      if (d1 != null && d2 != null) return d1.compareTo(d2);
                      if (d1 != null) return -1;
                      if (d2 != null) return 1;
                      return 0;
                    });

                    if (pitchesWithDistance.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.showOnlyFavorites ? Icons.star_border_rounded : Icons.stadium_outlined,
                              size: 54,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.showOnlyFavorites ? 'قائمة المفضلة فارغة حالياً' : 'لا توجد ملاعب مطابقة للبحث',
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: pitchesWithDistance.length,
                      itemBuilder: (context, idx) {
                        final pitch = pitchesWithDistance[idx];
                        final pName = pitch['name'] ?? 'ملعب رياضي';
                        return PitchExploreCard(
                          pitchData: pitch,
                          userPhone: widget.userPhone,
                          isFavorite: favoritePitches.contains(pName),
                          onToggleFavorite: () => _toggleFavorite(pName, favoritePitches.contains(pName)),
                          onShowToast: _showCenterToast,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
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
                DropdownButton<String>(
                  value: _selectedGov,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  items: iraqGovernoratesList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() {
                    _selectedGov = v!;
                    _selectedArea = 'الكل';
                  }),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: getAreasListForGov(_selectedGov).contains(_selectedArea) ? _selectedArea : 'الكل',
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  items: getAreasListForGov(_selectedGov).map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (v) => setState(() => _selectedArea = v!),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedSurface,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  items: pitchSurfaceTypesList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSurface = v!),
                ),
                if (_selectedGov != 'الكل' || _selectedArea != 'الكل' || _selectedSurface != 'الكل') ...[
                  const SizedBox(width: 8),
                  ActionChip(
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
    );
  }
}
