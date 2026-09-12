import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player_screen.dart';
import '../screens/owner/owner_screen.dart'; // أو مسار شاشة صاحب الملعب حسب مشروعك

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true; // true لتسجيل الدخول، false لإنشاء حساب جديد
  String _userRole = 'player'; // 'player' أو 'owner'

  @override
  void initState() {
    super.initState();
    _checkSavedUser();
  }

  // التحقق هل المستخدم مسجل دخوله مسبقاً على الجهاز
  Future<void> _checkSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('saved_phone');
    final savedRole = prefs.getString('saved_role');

    if (savedPhone != null && savedRole != null && mounted) {
      if (savedRole == 'player') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: ui.TextDirection.rtl,
              child: PlayerMainScreen(userPhone: savedPhone), // تم التعديل إلى userPhone
            ),
          ),
        );
      } else if (savedRole == 'owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: ui.TextDirection.rtl,
              child: OwnerScreen(ownerPhone: savedPhone),
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitAuth() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الهاتف ورمز المرور')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final userDocRef = firestore.collection('users').doc(phone);
      final docSnap = await userDocRef.get();

      final prefs = await SharedPreferences.getInstance();

      if (_isLoginMode) {
        // وضع تسجيل الدخول
        if (!docSnap.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رقم الهاتف غير مسجل، يرجى إنشاء حساب جديد')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        final data = docSnap.data() as Map<String, dynamic>;
        final savedPin = data['pin'] ?? '';
        final role = data['role'] ?? 'player';

        if (savedPin != pin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رمز المرور غير صحيح')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // حفظ الجلسة محلياً
        await prefs.setString('saved_phone', phone);
        await prefs.setString('saved_role', role);

        if (mounted) {
          if (role == 'owner') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: OwnerScreen(ownerPhone: phone),
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: PlayerMainScreen(userPhone: phone), // تم التعديل إلى userPhone
                ),
              ),
            );
          }
        }
      } else {
        // وضع إنشاء حساب جديد
        if (docSnap.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رقم الهاتف مسجل مسبقاً، قم بتسجيل الدخول')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // حفظ مستخدم جديد في الفايربيز
        await userDocRef.set({
          'phone': phone,
          'pin': pin,
          'role': _userRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await prefs.setString('saved_phone', phone);
        await prefs.setString('saved_role', _userRole);

        if (mounted) {
          if (_userRole == 'owner') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: OwnerScreen(ownerPhone: phone),
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: PlayerMainScreen(userPhone: phone), // تم التعديل إلى userPhone
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في الاتصال: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.sports_soccer, size: 60, color: Color(0xFF1B5E20)),
                    const SizedBox(height: 16),
                    Text(
                      _isLoginMode ? 'تسجيل الدخول إلى ملعبِي' : 'إنشاء حساب جديد',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'رمز المرور (PIN)',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _userRole,
                        decoration: InputDecoration(
                          labelText: 'نوع الحساب',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'player', child: Text('كابتن فريق / لاعب')),
                          DropdownMenuItem(value: 'owner', child: Text('صاحب ملعب رياضي')),
                        ],
                        onChanged: (val) => setState(() => _userRole = val ?? 'player'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _submitAuth,
                            child: Text(
                              _isLoginMode ? 'دخول' : 'تسجيل وحساب جديد',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                      child: Text(
                        _isLoginMode ? 'ليس لديك حساب؟ انشئ حساباً جديداً' : 'لديك حساب بالفعل؟ سجل دخولك',
                        style: const TextStyle(color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
