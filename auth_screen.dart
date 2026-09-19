import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/auth_service.dart';
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
  bool _obscurePassword = true;
  bool isLoading = false;

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final teamNameController = TextEditingController();
  final pitchNameController = TextEditingController();
  final hourlyRateController = TextEditingController(text: '25000');
  final addressDetailsController = TextEditingController();

  String _selectedGov = 'بغداد';
  String _selectedArea = 'الكرخ';
  String _selectedPitchType = 'سباعي (7 ضد 7)';
  String _selectedSurface = 'ثيل 🌿';

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

  void _navigateBasedOnRole(String phone, String role, String? pName) {
    if (role == 'owner' && pName != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerScreen(userPhone: phone, pitchName: pName)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayerScreen(userPhone: phone)));
    }
  }

  Future<void> _submit() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء رقم الهاتف والرمز السري')));
      return;
    }

    setState(() => isLoading = true);

    AuthResult result;
    if (isLogin) {
      result = await AuthService.login(phone, password);
    } else {
      result = await AuthService.register(
        isOwner: isOwner,
        phone: phone,
        password: password,
        name: nameController.text.trim(),
        gov: _selectedGov,
        area: _selectedArea,
        teamName: teamNameController.text.trim(),
        pitchName: pitchNameController.text.trim(),
        hourlyRate: double.tryParse(hourlyRateController.text.trim()),
        addressDetails: addressDetailsController.text.trim(),
        pitchType: _selectedPitchType,
        surfaceType: _selectedSurface,
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
      if (result.success) {
        _navigateBasedOnRole(phone, result.role!, result.pitchName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage ?? 'حدث خطأ غير معروف')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableAreas = getAreasListForGov(_selectedGov).where((a) => a != 'الكل').toList();
    if (!availableAreas.contains(_selectedArea)) {
      _selectedArea = availableAreas.isNotEmpty ? availableAreas.first : 'المركز';
    }
    final validGovs = iraqGovernoratesList.where((g) => g != 'الكل').toList();
    final validSurfaces = pitchSurfaceTypesList.where((s) => s != 'الكل').toList();
    final validPitchTypes = pitchTypesList.where((t) => t != 'الكل').toList();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.sports_soccer_rounded, size: 56, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 16),
                Text(
                  isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  isLogin ? 'مرحباً بك مجدداً في تطبيق ملعبي' : 'اختر هويتك وسجل بياناتك للبدء',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),

                if (!isLogin) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isOwner = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isOwner ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isOwner ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                              ),
                              child: Center(child: Text('لاعب / كابتن فريق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: !isOwner ? const Color(0xFF1B5E20) : const Color(0xFF64748B)))),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isOwner = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isOwner ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isOwner ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                              ),
                              child: Center(child: Text('صاحب ملعب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isOwner ? const Color(0xFF1B5E20) : const Color(0xFF64748B)))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: 'رقم الهاتف', prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF1B5E20)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'الرمز السري (Password)',
                    prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF1B5E20)),
                    suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                if (!isLogin) ...[
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: isOwner ? 'اسم صاحب الملعب' : 'اسم اللاعب أو الكابتن', prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF1B5E20)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGov,
                          decoration: InputDecoration(labelText: 'المحافظة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: validGovs.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedGov = val;
                                final areas = getAreasListForGov(val).where((a) => a != 'الكل').toList();
                                _selectedArea = areas.isNotEmpty ? areas.first : 'المركز';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedArea,
                          decoration: InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: availableAreas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) { if (val != null) setState(() => _selectedArea = val); },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (isOwner) ...[
                    TextField(
                      controller: pitchNameController,
                      decoration: InputDecoration(labelText: 'اسم الملعب التجاري', prefixIcon: const Icon(Icons.stadium_rounded, color: Color(0xFF1B5E20)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPitchType,
                            decoration: InputDecoration(labelText: 'حجم الملعب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: validPitchTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (val) { if (val != null) setState(() => _selectedPitchType = val); },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSurface,
                            decoration: InputDecoration(labelText: 'نوع الأرضية', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: validSurfaces.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (val) { if (val != null) setState(() => _selectedSurface = val); },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: hourlyRateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'سعر تأجير الساعة (د.ع)', prefixIcon: const Icon(Icons.payments_rounded, color: Colors.teal), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: addressDetailsController,
                      decoration: InputDecoration(labelText: 'أقرب نقطة دالة للملعب', prefixIcon: const Icon(Icons.place_outlined, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ] else ...[
                    TextField(
                      controller: teamNameController,
                      decoration: InputDecoration(labelText: 'اسم الفريق الأساسي (اختياري)', prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isLogin ? 'تسجيل الدخول' : 'تأكيد التسجيل', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ سجل دخولك', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
