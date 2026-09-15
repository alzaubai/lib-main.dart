import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/location_service.dart';

class PitchLocationCard extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final Function(double lat, double lng) onLocationCaptured;

  const PitchLocationCard({
    super.key,
    this.initialLat,
    this.initialLng,
    required this.onLocationCaptured,
  });

  @override
  State<PitchLocationCard> createState() => _PitchLocationCardState();
}

class _PitchLocationCardState extends State<PitchLocationCard> {
  double? _lat;
  double? _lng;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat;
    _lng = widget.initialLng;
  }

  @override
  void didUpdateWidget(covariant PitchLocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLat != oldWidget.initialLat || widget.initialLng != oldWidget.initialLng) {
      _lat = widget.initialLat;
      _lng = widget.initialLng;
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isLocating = true);
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      widget.onLocationCaptured(pos.latitude, pos.longitude);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تثبيت إحداثيات الملعب بنجاح'), behavior: SnackBarBehavior.floating),
      );
    }
    if (mounted) setState(() => _isLocating = false);
  }

  void _testWazeNavigation() async {
    if (_lat == null || _lng == null) return;
    final uri = Uri.parse('waze://?ll=$_lat,$_lng&navigate=yes');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_lat,$_lng');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: Color(0xFF1B5E20), size: 20),
              SizedBox(width: 8),
              Text(
                'الموقع الجغرافي الدقيق (Waze و Maps)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _lat != null && _lng != null
                ? 'الإحداثيات: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                : 'لم يتم تثبيت إحداثيات الملعب بدقة بعد.',
            style: TextStyle(
              fontSize: 11.5,
              color: _lat != null ? const Color(0xFF1B5E20) : const Color(0xFF64748B),
              fontWeight: _lat != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: _isLocating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('تثبيت موقع الملعب من الـ GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _isLocating ? null : _captureLocation,
                ),
              ),
              if (_lat != null && _lng != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  icon: const Icon(Icons.near_me_rounded, size: 16),
                  label: const Text('تجربة Waze', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: _testWazeNavigation,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
