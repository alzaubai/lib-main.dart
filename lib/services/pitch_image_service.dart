import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class PitchImageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ImagePicker _picker = ImagePicker();

  /// اختيار صورة مباشرة من جهاز المستخدم وضغطها لحفظها بالملعب
  static Future<bool> pickImageDirectly(String pitchName) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 65, // ضغط عالي للحفاظ على سرعة التطبيق
      );

      if (picked == null) return false;

      // قراءة بايتات الصورة وتحويلها إلى Base64 String للحفظ المباشر
      final bytes = await File(picked.path).readAsBytes();
      final base64String = base64Encode(bytes);

      // حفظها مباشرة داخل وثيقة الملعب
      await _firestore.collection('pitches').doc(pitchName).update({
        'images': FieldValue.arrayUnion([base64String]),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// حذف صورة من الملعب
  static Future<void> removeImage(String pitchName, String imageBase64) async {
    try {
      await _firestore.collection('pitches').doc(pitchName).update({
        'images': FieldValue.arrayRemove([imageBase64]),
      });
    } catch (_) {}
  }
}
