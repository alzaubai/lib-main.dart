import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player_screen.dart';
import 'owner_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isOwner = false;
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final pitchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('phone');
    final savedRole = prefs.getString('role');
    final savedPitch = prefs.getString('pitchName');

    if (savedPhone != null && savedPhone.isNotEmpty && mounted) {
      if (savedRole == 'owner' && savedPitch != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerScreen(userPhone: savedPhone, pitchName: savedPitch)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayerScreen(userPhone: savedPhone)));
      }
    }
  }

  Future<void> _submit() async {
    if (phoneController.text.trim().isEmpty) return;
    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = phoneController.text.trim();

      if (isLogin) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(phone).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'] ?? 'player';
          final pName = data['pitchName'] ?? '';
          
          await prefs.setString('phone', phone);
          await prefs.setString('role', role);
          if (role == 'owner') await prefs.setString('pitchName', pName);

          if (mounted) {
            if (role == 'owner') {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerScreen(userPhone: phone, pitchName: pName)));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayerScreen(userPhone: phone)));
            }
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الحساب غير موجود، أنشئ حساباً أولاً')));
        }
      } else {
        final role = isOwner ? 'owner' : 'player';
        final pName = isOwner ? pitchController.text.trim() : null;
        
        await FirebaseFirestore.instance.collection('users').doc(phone).set({
          'phone': phone,
          'name': nameController.text.trim(),
          'role': role,
          'pitchName': pName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await prefs.setString('phone', phone);
        await prefs.setString('role', role);
        if (isOwner) await prefs.setString('pitchName', pName!);

        if (mounted) {
          if (isOwner) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerScreen(userPhone: phone, pitchName: pName!)));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayerScreen(userPhone: phone)));
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_soccer_rounded, size: 80, color: Color(0xFF1B5E20)),
                const SizedBox(height: 24),
                Text(isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 24),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                if (!isLogin) ...[
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('تسجيل كصاحب ملعب'),
                    value: isOwner,
                    activeColor: const Color(0xFF1B5E20),
                    onChanged: (val) => setState(() => isOwner = val),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: pitchController,
                      decoration: InputDecoration(labelText: 'اسم الملعب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? 'دخول' : 'تسجيل', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? 'لا تملك حساباً؟ أنشئ حساباً الآن' : 'لديك حساب؟ سجل دخولك', style: const TextStyle(color: Color(0xFF1B5E20))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
