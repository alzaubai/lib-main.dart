import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? role;
  final String? pitchName;

  AuthResult({required this.success, this.errorMessage, this.role, this.pitchName});
}

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<AuthResult> login(String phone, String password) async {
    try {
      final doc = await _firestore.collection('users').doc(phone).get();
      if (!doc.exists) {
        return AuthResult(success: false, errorMessage: 'الحساب غير موجود، يرجى إنشاء حساب جديد');
      }

      final data = doc.data() as Map<String, dynamic>;
      final storedPassword = data['password']?.toString() ?? '';

      if (storedPassword.isNotEmpty && storedPassword != password) {
        return AuthResult(success: false, errorMessage: 'الرمز السري غير صحيح');
      }

      final role = data['role'] ?? 'player';
      final pName = data['pitchName'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', phone);
      await prefs.setString('role', role);
      if (role == 'owner') await prefs.setString('pitchName', pName);

      return AuthResult(success: true, role: role, pitchName: pName);
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'حدث خطأ: $e');
    }
  }

  static Future<AuthResult> register({
    required bool isOwner,
    required String phone,
    required String password,
    required String name,
    required String gov,
    required String area,
    String? teamName,
    String? pitchName,
    double? hourlyRate,
    String? addressDetails,
    String? pitchType,
    String? surfaceType,
  }) async {
    try {
      final existingDoc = await _firestore.collection('users').doc(phone).get();
      if (existingDoc.exists) {
        return AuthResult(success: false, errorMessage: 'رقم الهاتف مسجل مسبقاً، يرجى تسجيل الدخول');
      }

      if (isOwner && (pitchName == null || pitchName.isEmpty)) {
        return AuthResult(success: false, errorMessage: 'يرجى كتابة اسم الملعب');
      }

      final role = isOwner ? 'owner' : 'player';

      // 1. إنشاء وثيقة المستخدم
      await _firestore.collection('users').doc(phone).set({
        'phone': phone,
        'password': password,
        'name': name.isEmpty ? 'مستخدم' : name,
        'role': role,
        'pitchName': isOwner ? pitchName : null,
        'teamName': !isOwner ? teamName : null,
        'governorate': gov,
        'area': area,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. إنشاء وثيقة الملعب (للمالك فقط)
      if (isOwner && pitchName != null) {
        await _firestore.collection('pitches').doc(pitchName).set({
          'name': pitchName,
          'ownerPhone': phone,
          'phone': phone,
          'hourlyRate': hourlyRate ?? 25000.0,
          'governorate': gov,
          'area': area,
          'addressDetails': addressDetails,
          'pitchType': pitchType,
          'surfaceType': surfaceType,
          'description': 'ملعب معتمد ومجهز بالإنارة والخدمات',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', phone);
      await prefs.setString('role', role);
      if (isOwner && pitchName != null) await prefs.setString('pitchName', pitchName);

      return AuthResult(success: true, role: role, pitchName: pitchName);
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'حدث خطأ: $e');
    }
  }
}
