import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/rating_service.dart';

class PitchEvaluationDialog {
  static void show(
    BuildContext context, {
    required String bookingId,
    required String pitchName,
    required String userPhone,
  }) {
    final List<String> quickTags = [
      'أرضية ممتازة ونظيفة',
      'إضاءة قوية ورائعة',
      'تعامل راقٍ من الإدارة',
      'مرافق وخدمات متكاملة',
      'التزام تام بالمواعيد'
    ];
    String selectedTag = quickTags.first;
    int rating = 5;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'تقييم تجربة اللعب: $pitchName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('التقييم العام بالنجوم:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: starVal <= rating ? const Color(0xFFF59E0B) : Colors.grey,
                          size: 30,
                        ),
                        onPressed: () => setDialogState(() => rating = starVal),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  const Text('اختر انطباعك الأساسي:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTag,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: quickTags.map((tag) => DropdownMenuItem(value: tag, child: Text(tag, style: const TextStyle(fontSize: 12.5)))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedTag = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('ملاحظات إضافية (اختياري):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'اكتب ملاحظتك الموضوعية عن الملعب...',
                      hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'isArchived': true});
                },
                child: const Text('تخطي', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  
                  // دمج التاك مع الملاحظة ليتوافق مع خدمة التقييم المركزية (بدون تكرار قواعد البيانات)
                  final finalComment = noteCtrl.text.trim().isNotEmpty 
                       ? '$selectedTag - ${noteCtrl.text.trim()}'
                       : selectedTag;

                  await RatingService.submitPitchReview(
                    pitchName: pitchName,
                    userPhone: userPhone,
                    reviewerName: 'كابتن فريق',
                    rating: rating.toDouble(),
                    comment: finalComment,
                  );

                  await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
                    'isArchived': true,
                    'pitchRating': rating,
                  });

                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال تقييمك للملعب بنجاح'), backgroundColor: Color(0xFF1B5E20)),
                    );
                  }
                },
                child: const Text('تأكيد التقييم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
