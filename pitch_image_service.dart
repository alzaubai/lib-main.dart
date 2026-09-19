import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class PitchImageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ImagePicker _picker = ImagePicker();

  /// اختيار الصورة وضغطها بشكل كبير جداً لتفادي مشكلة الـ 1 ميجابايت في Firestore
  static Future<bool> pickImageDirectly(String pitchName) async {
    try {
      // 1. فحص الحد الأقصى للصور
      final docSnap = await _firestore.collection('pitches').doc(pitchName).get();
      if (docSnap.exists) {
        final currentImages = List<String>.from(docSnap.data()?['images'] ?? []);
        if (currentImages.length >= 4) {
          return false; 
        }
      }

      // 2. ضغط الصورة بقوة (أبعاد 600x600 وجودة 40%) حتى تصير كلش خفيفة
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,  
        maxHeight: 600, 
        imageQuality: 40, 
      );

      if (picked == null) return false;

      // 3. تحويل الصورة الخفيفة إلى نص
      final bytes = await File(picked.path).readAsBytes();
      final base64String = base64Encode(bytes);

      // 4. حفظ النص بقاعدة البيانات المجانية
      await _firestore.collection('pitches').doc(pitchName).update({
        'images': FieldValue.arrayUnion([base64String]),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// حذف الصورة
  static Future<void> removeImage(String pitchName, String imageBase64) async {
    try {
      await _firestore.collection('pitches').doc(pitchName).update({
        'images': FieldValue.arrayRemove([imageBase64]),
      });
    } catch (_) {}
  }
}
