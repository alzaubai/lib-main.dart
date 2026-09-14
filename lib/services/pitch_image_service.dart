import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class PitchImageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ImagePicker _picker = ImagePicker();

  /// اختيار وضغط الصورة محلياً لضمان عدم تجاوز حد وثيقة Firestore
  static Future<bool> pickImageDirectly(String pitchName) async {
    try {
      final docSnap = await _firestore.collection('pitches').doc(pitchName).get();
      if (docSnap.exists) {
        final currentImages = List<String>.from(docSnap.data()?['images'] ?? []);
        if (currentImages.length >= 4) {
          return false;
        }
      }

      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 400,
        imageQuality: 45,
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

  /// حذف صورة من الملعب
  static Future<void> removeImage(String pitchName, String imageBase64) async {
    try {
      await _firestore.collection('pitches').doc(pitchName).update({
        'images': FieldValue.arrayRemove([imageBase64]),
      });
    } catch (_) {}
  }
}
