import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PitchImageGallery extends StatefulWidget {
  final List<String> images;
  final double height;
  final bool isEditable;
  final Function(String)? onRemoveImage;

  const PitchImageGallery({
    super.key,
    required this.images,
    this.height = 160,
    this.isEditable = false,
    this.onRemoveImage,
  });

  @override
  State<PitchImageGallery> createState() => _PitchImageGalleryState();
}

class _PitchImageGalleryState extends State<PitchImageGallery> {
  int _currentIdx = 0;

  Widget _buildImageWidget(String imgData) {
    // إذا كانت بيانات Base64 مخزنة محلياً من الجهاز
    if (!imgData.startsWith('http')) {
      try {
        final decodedBytes = base64Decode(imgData);
        return Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackContainer(),
        );
      } catch (_) {
        return _fallbackContainer();
      }
    }

    // إذا كانت رابط صورة خارجي
    return Image.network(
      imgData,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackContainer(),
    );
  }

  Widget _fallbackContainer() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.sports_soccer_rounded, color: Colors.grey, size: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stadium_rounded, size: 48, color: Color(0xFF1B5E20)),
            SizedBox(height: 6),
            Text(
              'أرضية ومرافق رياضية مجهزة',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (idx) => setState(() => _currentIdx = idx),
              itemBuilder: (ctx, index) {
                final img = widget.images[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageWidget(img),
                    if (widget.isEditable && widget.onRemoveImage != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                            onPressed: () => widget.onRemoveImage!(img),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _currentIdx;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
