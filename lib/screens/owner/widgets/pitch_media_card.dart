import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/pitch_image_service.dart';

class PitchMediaCard extends StatefulWidget {
  final String pitchName;
  final List<String> initialImages;
  final VoidCallback onImagesChanged;

  const PitchMediaCard({
    super.key,
    required this.pitchName,
    required this.initialImages,
    required this.onImagesChanged,
  });

  @override
  State<PitchMediaCard> createState() => _PitchMediaCardState();
}

class _PitchMediaCardState extends State<PitchMediaCard> {
  bool _isPicking = false;

  Future<void> _pick() async {
    setState(() => _isPicking = true);
    final success = await PitchImageService.pickImageDirectly(widget.pitchName);
    if (success) widget.onImagesChanged();
    if (mounted) setState(() => _isPicking = false);
  }

  Future<void> _remove(String img) async {
    await PitchImageService.removeImage(widget.pitchName, img);
    widget.onImagesChanged();
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
          Row(
            children: [
              const Icon(Icons.photo_library_rounded, color: Color(0xFF1B5E20), size: 20),
              const SizedBox(width: 8),
              const Text('صور الملعب والمرافق', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                icon: _isPicking
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add_a_photo_rounded, size: 16),
                label: const Text('إضافة صورة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: _isPicking ? null : _pick,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.initialImages.isEmpty)
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('لم تتم إضافة صور للملعب بعد', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.initialImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final raw = widget.initialImages[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: raw.startsWith('http')
                            ? Image.network(raw, width: 110, height: 100, fit: BoxFit.cover)
                            : Image.memory(base64Decode(raw), width: 110, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: InkWell(
                          onTap: () => _remove(raw),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.delete_outline, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
