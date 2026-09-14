import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchEvaluationDialog {
  static void show(
    BuildContext context, {
    required String bookingDocId,
    required String pitchName,
    required String teamName,
    required bool isOwner,
  }) {
    double stars = 5.0;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Icon(
                    isOwner ? Icons.sports_score_rounded : Icons.star_rate_rounded,
                    color: const Color(0xFF1B5E20),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOwner ? 'تقييم انضباط الفريق' : 'تقييم تجربة الملعب',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwner
                        ? 'يرجى تقييم حضور وانضباط كابتن ($teamName):'
                        : 'يرجى تقييم أرضية وخدمات ($pitchName):',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final val = index + 1;
                        return IconButton(
                          icon: Icon(
                            val <= stars ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () => setDialogState(() => stars = val.toDouble()),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: isOwner ? 'ملاحظات حول الالتزام بالوقت والروح الرياضية...' : 'ملاحظات حول الإضاءة والأرضية...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('تخطي', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await FirebaseFirestore.instance.collection('match_evaluations').add({
                      'bookingId': bookingDocId,
                      'pitchName': pitchName,
                      'teamName': teamName,
                      'evaluatedBy': isOwner ? 'owner' : 'player',
                      'rating': stars,
                      'notes': noteCtrl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    // وسم الحجز بأنه تم تقييمه
                    await FirebaseFirestore.instance.collection('bookings').doc(bookingDocId).update({
                      isOwner ? 'ownerEvaluated' : 'playerEvaluated': true,
                    });
                  },
                  child: const Text('إرسال التقييم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
