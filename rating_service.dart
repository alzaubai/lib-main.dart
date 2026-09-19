import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إرسال تقييم جديد لملعب وحساب المعدل الحسابي التراكمي
  static Future<void> submitPitchReview({
    required String pitchName,
    required String userPhone,
    required String reviewerName,
    required double rating,
    required String comment,
  }) async {
    final reviewsRef = _firestore
        .collection('pitches')
        .doc(pitchName)
        .collection('reviews');

    // 1. تسجيل التقييم في سجل مراجعات الملعب
    await reviewsRef.doc(userPhone).set({
      'userPhone': userPhone,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. إعادة حساب المتوسط التراكمي لجميع المراجعات
    final allReviewsSnap = await reviewsRef.get();
    if (allReviewsSnap.docs.isNotEmpty) {
      double total = 0.0;
      for (var doc in allReviewsSnap.docs) {
        final r = (doc.data()['rating'] as num?)?.toDouble() ?? 5.0;
        total += r;
      }
      final double averageRating = total / allReviewsSnap.docs.length;

      // 3. تحديث وثيقة الملعب بالمتوسط وعدد المقيمين
      await _firestore.collection('pitches').doc(pitchName).update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
        'reviewsCount': allReviewsSnap.docs.length,
      });
    }
  }

  /// الاستماع المباشر لبيانات تقييم الملعب
  static Stream<DocumentSnapshot> streamPitchRating(String pitchName) {
    return _firestore.collection('pitches').doc(pitchName).snapshots();
  }
}
