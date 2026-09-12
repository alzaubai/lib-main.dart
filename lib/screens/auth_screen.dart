import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'player_screen.dart';
import 'owner_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  final _pitchNameController = TextEditingController();
  final _rateController = TextEditingController(text: '25000');
  final _descController = TextEditingController();

  String _userRole = 'player';
  String _selectedGov = 'بغداد';
  String _selectedArea = 'الكرخ';
  String _selectedPitchType = 'سباعي (7 ضد 7)';
  String _selectedSurface = 'ثيل 🌿';
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('user_phone');
    final savedRole = prefs.getString('user_role');
    final savedPitch = prefs.getString('pitch_name');

    if (savedPhone != null && mounted) {
      if (savedRole == 'owner' && savedPitch != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OwnerDashboardScreen(pitchName: savedPitch)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PlayerScreen(userPhone: savedPhone)),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.length < 10 || pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة رقم هاتف صحيح ورمز PIN من 4 أرقام على الأقل')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final firestore = FirebaseFirestore.instance;
    final prefs = await SharedPreferences.getInstance();

    try {
      if (_isLogin) {
        final doc = await firestore.collection('users').doc(phone).get();
        if (!doc.exists) {
          throw 'الحساب غير مسجل، يرجى إنشاء حساب جديد أولاً';
        }

        final data = doc.data()!;
        if (data['pin'] != pin) {
          throw 'رمز الـ PIN غير صحيح';
        }

        final role = data['role'] ?? 'player';
        final pitchName = data['pitchName'] ?? '';

        await prefs.setString('user_phone', phone);
        await prefs.setString('user_role', role);
        if (pitchName.isNotEmpty) {
          await prefs.setString('pitch_name', pitchName);
        }

        if (mounted) {
          if (role == 'owner' && pitchName.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OwnerDashboardScreen(pitchName: pitchName)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => PlayerScreen(userPhone: phone)),
            );
          }
        }
      } else {
        final existingDoc = await firestore.collection('users').doc(phone).get();
        if (existingDoc.exists) {
          throw 'هذا الرقم مسجل مسبقاً، يرجى تسجيل الدخول';
        }

        final name = _nameController.text.trim();
        final pitchName = _pitchNameController.text.trim();

        if (name.isEmpty) throw 'يرجى كتابة الاسم';
        if (_userRole == 'owner' && pitchName.isEmpty) throw 'يرجى كتابة اسم الملعب';

        await firestore.collection('users').doc(phone).set({
          'name': name,
          'phone': phone,
          'pin': pin,
          'role': _userRole,
          'pitchName': _userRole == 'owner' ? pitchName : '',
          'governorate': _selectedGov,
          'area': _selectedArea,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (_userRole == 'owner') {
          await firestore.collection('pitches').doc(pitchName).set({
            'name': pitchName,
            'ownerPhone': phone,
            'phone': phone,
            'governorate': _selectedGov,
            'area': _selectedArea,
            'pitchType': _selectedPitchType,
            'surfaceType': _selectedSurface,
            'hourlyRate': double.tryParse(_rateController.text.trim()) ?? 25000.0,
            'description': _descController.text.trim(),
            'matchDurationMinutes': 60,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        await prefs.setString('user_phone', phone);
        await prefs.setString('user_role', _userRole);
        if (_userRole == 'owner') {
          await prefs.setString('pitch_name', pitchName);
        }

        if (mounted) {
          if (_userRole == 'owner') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OwnerDashboardScreen(pitchName: pitchName)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => PlayerScreen(userPhone: phone)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade800),
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
        backgroundColor: const Color(0xFFF4F7F4),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))
                      ],
                    ),
                    child: const Icon(Icons.sports_soccer, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'تطبيق ملعبِي ⚽',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLogin ? 'تسجيل الدخول إلى حسابك' : 'إنشاء حساب جديد',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isLogin) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('كابتن / لاعب', style: TextStyle(fontWeight: FontWeight.bold)),
                                    selected: _userRole == 'player',
                                    selectedColor: const Color(0xFF1B5E20),
                                    labelStyle: TextStyle(color: _userRole == 'player' ? Colors.white : Colors.black87),
                                    onSelected: (val) {
                                      if (val) setState(() => _userRole = 'player');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('صاحب ملعب', style: TextStyle(fontWeight: FontWeight.bold)),
                                    selected: _userRole == 'owner',
                                    selectedColor: const Color(0xFF1B5E20),
                                    labelStyle: TextStyle(color: _userRole == 'owner' ? Colors.white : Colors.black87),
                                    onSelected: (val) {
                                      if (val) setState(() => _userRole = 'owner');
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'الاسم الثلاثي أو اسم الفريق',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_userRole == 'owner') ...[
                              TextField(
                                controller: _pitchNameController,
                                decoration: InputDecoration(
                                  labelText: 'اسم الملعب الرسمي',
                                  prefixIcon: const Icon(Icons.stadium),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _rateController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'سعر الساعة (د.ع)',
                                  prefixIcon: const Icon(Icons.payments),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedPitchType,
                                      decoration: InputDecoration(
                                        labelText: 'حجم الملعب',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: pitchTypesList
                                          .where((t) => t != 'الكل')
                                          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11))))
                                          .toList(),
                                      onChanged: (v) => setState(() => _selectedPitchType = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedSurface,
                                      decoration: InputDecoration(
                                        labelText: 'الأرضية',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: pitchSurfaceTypesList
                                          .where((s) => s != 'الكل')
                                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11))))
                                          .toList(),
                                      onChanged: (v) => setState(() => _selectedSurface = v!),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _descController,
                                decoration: InputDecoration(
                                  labelText: 'العنوان التفصيلي / نقطة دالة',
                                  prefixIcon: const Icon(Icons.place),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGov,
                                    decoration: InputDecoration(
                                      labelText: 'المحافظة',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    items: iraqGovernoratesList
                                        .where((g) => g != 'الكل')
                                        .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12))))
                                        .toList(),
                                    onChanged: (v) => setState(() {
                                      _selectedGov = v!;
                                      _selectedArea = getAreasListForGov(_selectedGov).first;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: getAreasListForGov(_selectedGov).contains(_selectedArea)
                                        ? _selectedArea
                                        : getAreasListForGov(_selectedGov).first,
                                    decoration: InputDecoration(
                                      labelText: 'المنطقة',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    items: getAreasListForGov(_selectedGov)
                                        .where((a) => a != 'الكل')
                                        .map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12))))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedArea = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'رقم الهاتف (07XXXXXXXXX)',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pinController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'رمز الدخول السري (PIN)',
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isLoading ? null : _handleSubmit,
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      _isLogin ? 'تسجيل الدخول' : 'تأكيد وإنشاء الحساب',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? 'ليس لديك حساب؟ أنشئ حساباً جديداً' : 'لديك حساب بالفعل؟ سجل دخولك',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
