import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../constants.dart';
import '../../../services/location_service.dart';
import '../sheets/player_booking_sheet.dart';

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
  final NumberFormat currencyFormatter = NumberFormat('#,###');

  String _searchQuery = '';
  String _selectedGov = 'الكل';
  String _selectedArea = 'الكل';
  String _selectedSurface = 'الكل';
  bool _isLoading = true;
  List<String> _favoritePitches = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // إشعار HUD الشفاف في منتصف الشاشة
  void _showCenterHudToast(String message, {bool isError = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.80),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.star_rounded,
                    color: isError ? Colors.redAccent : Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // جلب المفضلة سحابياً من حساب المستخدم في Firestore
  Future<void> _loadInitialData() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userPhone).get();
      if (doc.exists && mounted) {
        final d = doc.data();
        setState(() {
          _favoritePitches = List<String>.from(d?['favorites'] ?? []);
        });
      }
    } catch (_) {}

    _currentPosition = await LocationService.getCurrentLocation();
    if (mounted) setState(() => _isLoading = false);
  }

  // مزامنة المفضلة سحابياً ومحلياً فوراً
  Future<void> _toggleFavorite(String pitchName) async {
    final isFav = _favoritePitches.contains(pitchName);
    setState(() {
      if (isFav) {
        _favoritePitches.remove(pitchName);
      } else {
        _favoritePitches.add(pitchName);
      }
    });

    try {
      if (isFav) {
        await _firestore.collection('users').doc(widget.userPhone).set({
          'favorites': FieldValue.arrayRemove([pitchName]),
        }, SetOptions(merge: true));
        _showCenterHudToast('تمت الإزالة من المفضلة');
      } else {
        await _firestore.collection('users').doc(widget.userPhone).set({
          'favorites': FieldValue.arrayUnion([pitchName]),
        }, SetOptions(merge: true));
        _showCenterHudToast('تمت الإضافة إلى المفضلة ⭐');
      }
    } catch (_) {}
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

  void _showPitchImagesViewer(BuildContext context, String pitchName, List<String> images) {
    if (images.isEmpty) {
      _showCenterHudToast('لا توجد صور للملعب بعد', isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (dialogCtx) {
        int activeIndex = 0;
        final pageCtrl = PageController();

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pitchName,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'صورة ${activeIndex + 1} من ${images.length}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: PageView.builder(
                          controller: pageCtrl,
                          itemCount: images.length,
                          onPageChanged: (idx) => setDialogState(() => activeIndex = idx),
                          itemBuilder: (ctx, idx) {
                            final rawImage = images[idx];
                            Widget imageWidget;

                            if (!rawImage.startsWith('http')) {
                              try {
                                final bytes = base64Decode(rawImage);
                                imageWidget = Image.memory(bytes, fit: BoxFit.contain);
                              } catch (_) {
                                imageWidget = const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60);
                              }
                            } else {
                              imageWidget = Image.network(
                                rawImage,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60),
                              );
                            }

                            return InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: Center(child: imageWidget),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (images.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (i) {
                            final isActive = i == activeIndex;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 20 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF4CAF50) : Colors.white38,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          if (!widget.showOnlyFavorites) ...[
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
            ),
          ],

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : StreamBuilder<QuerySnapshot>(
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

                        if (widget.showOnlyFavorites && !_favoritePitches.contains(pName)) {
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
                                widget.showOnlyFavorites ? Icons.favorite_border_rounded : Icons.stadium_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.showOnlyFavorites ? 'قائمة المفضلة فارغة حالياً' : 'لا توجد ملاعب مطابقة للبحث',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.showOnlyFavorites
                                    ? 'اضغط على رمز النجمة بجانب أي ملعب لحفظه هنا'
                                    : 'جرب تصفير الفلترة أو كتابة اسم مختلف',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: pitchesWithDistance.length,
                        itemBuilder: (context, idx) {
                          final d = pitchesWithDistance[idx];
                          final pName = d['name'] ?? 'ملعب رياضي';
                          final phone = (d['phone'] ?? d['ownerPhone'] ?? '').toString().trim();
                          final price = (d['hourlyRate'] as num?)?.toDouble() ?? 25000.0;
                          final pType = d['pitchType'] ?? 'سباعي';
                          final surface = d['surfaceType'] ?? 'ثيل';
                          final gov = d['governorate'] ?? 'بغداد';
                          final area = d['area'] ?? 'المركز';
                          final desc = d['description'] ?? '';
                          final openTime = d['openTime'] ?? '04:00 م';
                          final closeTime = d['closeTime'] ?? '03:00 ص';
                          final lat = (d['latitude'] as num?)?.toDouble();
                          final lng = (d['longitude'] as num?)?.toDouble();
                          final double? distanceKm = d['calculatedDistance'];
                          final isFav = _favoritePitches.contains(pName);
                          final images = List<String>.from(d['images'] ?? []);

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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    pName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  constraints: const BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                  icon: Icon(
                                                    isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                                    color: isFav ? Colors.amber : Colors.grey,
                                                    size: 26,
                                                  ),
                                                  tooltip: 'إضافة للمفضلة',
                                                  onPressed: () => _toggleFavorite(pName),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text('$gov - $area', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                if (distanceKm != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'يبعد ${LocationService.formatDistance(distanceKm)}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blue.shade800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
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
                                        child: Text(
                                          '${currencyFormatter.format(price)} د.ع',
                                          style: TextStyle(
                                            color: Colors.green.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      InkWell(
                                        onTap: () => _showPitchImagesViewer(context, pName, images),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: images.isNotEmpty ? Colors.amber.shade50 : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: images.isNotEmpty ? Colors.amber.shade300 : Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.photo_library_rounded, size: 13, color: images.isNotEmpty ? Colors.amber.shade900 : Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                images.isNotEmpty ? '${images.length} صور 📸' : 'بدون صور',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: images.isNotEmpty ? Colors.amber.shade900 : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      _tagChip(pType, Icons.straighten_rounded, Colors.blue.shade50, Colors.blue.shade800),
                                      _tagChip(surface, Icons.grass_rounded, Colors.teal.shade50, Colors.teal.shade800),
                                      _tagChip('النشاط: $openTime - $closeTime', Icons.schedule_rounded, Colors.purple.shade50, Colors.purple.shade800),
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
                                        label: const Text('حجز موعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
