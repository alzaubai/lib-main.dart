import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PitchImageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// اختيار الصورة ورفعها لـ Firebase Storage
  static Future<bool> pickImageDirectly(String pitchName) async {
    try {
      // 1. فحص عدد الصور (الحد الأقصى 4 صور)
      final docSnap = await _firestore.collection('pitches').doc(pitchName).get();
      if (docSnap.exists) {
        final currentImages = List<String>.from(docSnap.data()?['images'] ?? []);
        if (currentImages.length >= 4) {
          return false; // تم الوصول للحد الأقصى
        }
      }

      // 2. فتح المعرض لاختيار الصورة مع ضغط حجمها
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 82,
      );

      if (picked == null) return false;

      // 3. تجهيز ملف الصورة ومسار الرفع
      File imageFile = File(picked.path);
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('pitches/$pitchName/$fileName.jpg');
      
      // 4. رفع الصورة لـ Firebase Storage
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      // 5. الحصول على الرابط الآمن للصورة
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 6. تحديث الرابط في Firestore
      await _firestore.collection('pitches').doc(pitchName).update({
        'images': FieldValue.arrayUnion([downloadUrl]),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// حذف صورة من Storage و Firestore
  static Future<void> removeImage(String pitchName, String imageUrl) async {
    try {
      // 1. حذف الرابط من وثيقة الملعب في Firestore
      await _firestore.collection('pitches').doc(pitchName).update({
        'images': FieldValue.arrayRemove([imageUrl]),
      });

      // 2. إذا كانت الصورة مرفوعة فعلياً على Storage، نحذفها من السيرفر لتوفير المساحة
      if (imageUrl.startsWith('https://firebasestorage')) {
        Reference ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      // تجاهل الخطأ في حال كانت الصورة غير موجودة بالسيرفر
    }
  }
}
