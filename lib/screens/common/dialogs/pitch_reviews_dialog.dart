import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/rating_service.dart';

class PitchReviewsDialog {
  static void show(
    BuildContext context, {
    required String pitchName,
    required String currentUserPhone,
    required bool canAddReview,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewsSheet(
        pitchName: pitchName,
        currentUserPhone: currentUserPhone,
        canAddReview: canAddReview,
      ),
    );
  }
}

class _ReviewsSheet extends StatefulWidget {
  final String pitchName;
  final String currentUserPhone;
  final bool canAddReview;

  const _ReviewsSheet({
    required this.pitchName,
    required this.currentUserPhone,
    required this.canAddReview,
  });

  @override
  State<_ReviewsSheet> createState() => _ReviewsSheetState();
}

class _ReviewsSheetState extends State<_ReviewsSheet> {
  final _commentCtrl = TextEditingController();
  double _userRating = 5.0;
  bool _isSubmitting = false;

  void _openAddReviewSheet() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('تقييم الملعب والخدمات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        icon: Icon(
                          starIndex <= _userRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setDialogState(() => _userRating = starIndex.toDouble()),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'اكتب رأيك بأرضية الملعب، الإنارة، والخدمات...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => _isSubmitting = true);
                          await RatingService.submitPitchReview(
                            pitchName: widget.pitchName,
                            userPhone: widget.currentUserPhone,
                            reviewerName: 'كابتن فريق',
                            rating: _userRating,
                            comment: _commentCtrl.text.trim().isEmpty ? 'تجربة ممتازة وتنسيق رائع' : _commentCtrl.text.trim(),
                          );
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.star_rounded, color: Colors.amber.shade800, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تقييمات ${widget.pitchName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('آراء وانطباعات الكباتن والفرق', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  if (widget.canAddReview)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.add_comment_rounded, size: 16, color: Colors.white),
                      label: const Text('تقييم', style: TextStyle(color: Colors.white, fontSize: 12)),
                      onPressed: _openAddReviewSheet,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pitches')
                    .doc(widget.pitchName)
                    .collection('reviews')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('لا توجد مراجعات مسجلة حتى الآن', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final r = docs[index].data() as Map<String, dynamic>;
                      final score = (r['rating'] as num?)?.toDouble() ?? 5.0;
                      final name = r['reviewerName'] ?? 'كابتن فريق';
                      final comment = r['comment'] ?? '';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF1B5E20)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < score.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 14,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (comment.toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(comment, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
