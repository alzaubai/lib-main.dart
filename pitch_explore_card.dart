import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/location_service.dart';
import '../../common/dialogs/full_image_viewer_dialog.dart';
import '../sheets/player_booking_sheet.dart';

class PitchExploreCard extends StatelessWidget {
  final Map<String, dynamic> pitchData;
  final String userPhone;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final Function(String) onShowToast;

  const PitchExploreCard({
    super.key,
    required this.pitchData,
    required this.userPhone,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShowToast,
  });

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

  Widget _tagChip(String label, IconData icon, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final pName = pitchData['name'] ?? 'ملعب رياضي';
    final phone = (pitchData['phone'] ?? pitchData['ownerPhone'] ?? '').toString().trim();
    final price = (pitchData['hourlyRate'] as num?)?.toDouble() ?? 25000.0;
    final pType = pitchData['pitchType'] ?? 'سباعي';
    final surface = pitchData['surfaceType'] ?? 'ثيل';
    final gov = pitchData['governorate'] ?? 'بغداد';
    final area = pitchData['area'] ?? 'المركز';
    final desc = pitchData['description'] ?? '';
    final openTime = pitchData['openTime'] ?? '04:00 م';
    final closeTime = pitchData['closeTime'] ?? '03:00 ص';
    final lat = (pitchData['latitude'] as num?)?.toDouble();
    final lng = (pitchData['longitude'] as num?)?.toDouble();
    final double? distanceKm = pitchData['calculatedDistance'];
    final images = List<String>.from(pitchData['images'] ?? []);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                              color: isFavorite ? Colors.amber : Colors.grey,
                              size: 24,
                            ),
                            tooltip: 'المفضلة',
                            onPressed: onToggleFavorite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('$gov - $area', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
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
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
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
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${currencyFormatter.format(price)} د.ع',
                    style: const TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
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
                  onTap: () {
                    if (images.isEmpty) {
                      onShowToast('لا توجد صور لهذا الملعب');
                    } else {
                      FullImageViewerDialog.show(context, title: pName, images: images);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: images.isNotEmpty ? Colors.amber.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_rounded, size: 13, color: images.isNotEmpty ? Colors.amber.shade900 : Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          images.isNotEmpty ? '${images.length} صور' : 'بدون صور',
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
            const Divider(height: 18),

            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.event_available_rounded, size: 16),
                  label: const Text('حجز موعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => PlayerBookingSheet(
                        pitchName: pName,
                        hourlyRate: price,
                        userPhone: userPhone,
                        pitchPhone: phone,
                        openTime: openTime,
                        closeTime: closeTime,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _launchWazeToPitch(pName, lat, lng),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.near_me_rounded, color: Colors.blueAccent, size: 15),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_rounded, color: Colors.white, size: 15),
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
  }
}
