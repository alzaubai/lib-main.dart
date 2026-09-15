import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FullImageViewerDialog {
  static void show(BuildContext context, {required String title, required List<String> images}) {
    if (images.isEmpty) return;

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
                                  title,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
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
}
