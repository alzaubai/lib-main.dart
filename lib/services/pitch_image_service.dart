import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class PitchImageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ImagePicker _picker = ImagePicker();

  /// اختيار وضغط الصورة بجودة عالية وواضحة (Full HD) مع البقاء في الحد الآمن
  static Future<bool> pickImageDirectly(String pitchName) async {
    try {
      final docSnap = await _firestore.collection('pitches').doc(pitchName).get();
      if (docSnap.exists) {
        final currentImages = List<String>.from(docSnap.data()?['images'] ?? []);
        if (currentImages.length >= 4) {
          return false;
        }
      }

      // أبعاد عالية ونسبة جودة 82% تضمن حدة تفاصيل الأرضية والإنارة
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 82,
      );

      if (picked == null) return false;

      final bytes = await File(picked.path).readAsBytes();
      final base64String = base64Encode(bytes);

      await _firestore.collection('pitches').doc(pitchName).update({
        'images': FieldValue.arrayUnion([base64String]),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// حذف صورة من صور الملعب
  static Future<void> removeImage(String pitchName, String imageBase64) async {
    try {
      await _firestore.collection('pitches').doc(pitchName).update({
        'images': FieldValue.arrayRemove([imageBase64]),
      });
    } catch (_) {}
  }
}
