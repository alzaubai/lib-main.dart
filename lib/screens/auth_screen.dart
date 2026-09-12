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
  
  // حقول خاصة بصاحب الملعب عند التسجيل
  final _pitchNameController = TextEditingController();
  final _hourlyRateController = TextEditingController(text: '25000');
  String _selectedGov = 'بغداد';
  String _selectedArea = 'الكرخ الأولى';
  String _selectedSubArea = 'المنصور';
  String _selectedPitchType = 'سباعي (7 ضد 7)';
  String _selectedSurfaceType = 'ثيل 🌿';

  bool _isLoading = false;
  bool _isLoginMode = true;
  String _userRole = 'player';

  @override
  void initState() {
    super.initState();
    _checkSavedUser();
  }

  Future<void> _checkSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('saved_phone');
    final savedRole = prefs.getString('saved_role');
    final savedPitchName = prefs.getString('current_pitch_name');

    if (savedPhone != null && savedRole != null && mounted) {
      if (savedRole == 'player') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: ui.TextDirection.rtl,
              child: PlayerMainScreen(userPhone: savedPhone),
            ),
          ),
        );
      } else if (savedRole == 'owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: ui.TextDirection.rtl,
              child: OwnerDashboardScreen(pitchName: savedPitchName ?? savedPhone),
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

    if (!_isLoginMode && _userRole == 'owner' && _pitchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الملعب')),
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
        final associatedPitch = data['pitchName'] ?? phone;

        if (savedPin != pin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رمز المرور غير صحيح')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        await prefs.setString('saved_phone', phone);
        await prefs.setString('saved_role', role);
        if (role == 'owner') {
          await prefs.setString('current_pitch_name', associatedPitch);
        }

        if (mounted) {
          if (role == 'owner') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: OwnerDashboardScreen(pitchName: associatedPitch),
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: PlayerMainScreen(userPhone: phone),
                ),
              ),
            );
          }
        }
      } else {
        if (docSnap.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رقم الهاتف مسجل مسبقاً، قم بتسجيل الدخول')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        final pitchName = _userRole == 'owner' ? _pitchNameController.text.trim() : '';

        await userDocRef.set({
          'phone': phone,
          'pin': pin,
          'role': _userRole,
          'pitchName': pitchName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (_userRole == 'owner') {
          final rate = double.tryParse(_hourlyRateController.text.trim()) ?? 25000.0;
          await firestore.collection('pitches').doc(pitchName).set({
            'name': pitchName,
            'phone': phone,
            'ownerPhone': phone,
            'hourlyRate': rate,
            'pitchType': _selectedPitchType,
            'surfaceType': _selectedSurfaceType,
            'governorate': _selectedGov,
            'area': _selectedArea,
            'subArea': _selectedSubArea,
            'pin': pin,
            'rating': 5.0,
            'ratingCount': 1,
            'createdAt': FieldValue.serverTimestamp(),
          });
          await prefs.setString('current_pitch_name', pitchName);
        }

        await prefs.setString('saved_phone', phone);
        await prefs.setString('saved_role', _userRole);

        if (mounted) {
          if (_userRole == 'owner') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: OwnerDashboardScreen(pitchName: pitchName),
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: PlayerMainScreen(userPhone: phone),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = (iraqLocations[_selectedGov] ?? ['الكل']).where((a) => a != 'الكل').toList();
    final subAreas = subLocationsMap[_selectedArea] ?? [];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
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
                    const SizedBox(height: 12),
                    Text(
                      _isLoginMode ? 'تسجيل الدخول إلى ملعبِي' : 'إنشاء حساب جديد',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
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
                      if (_userRole == 'owner') ...[
                        const SizedBox(height: 14),
                        const Divider(),
                        const Text('معلومات الملعب الأساسية', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _pitchNameController,
                          decoration: InputDecoration(
                            labelText: 'اسم الملعب',
                            prefixIcon: const Icon(Icons.stadium),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _hourlyRateController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'سعر الحجز للمباراة (د.ع)',
                            prefixIcon: const Icon(Icons.payments),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedPitchType,
                                decoration: InputDecoration(labelText: 'الحجم', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                items: pitchTypesList.where((t) => t != 'الكل').map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11)))).toList(),
                                onChanged: (val) => setState(() => _selectedPitchType = val!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSurfaceType,
                                decoration: InputDecoration(labelText: 'الأرضية', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                items: pitchSurfaceTypesList.where((s) => s != 'الكل').map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                                onChanged: (val) => setState(() => _selectedSurfaceType = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedGov,
                          decoration: InputDecoration(labelText: 'المحافظة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: iraqLocations.keys.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedGov = val;
                                final aList = iraqLocations[val]?.where((a) => a != 'الكل').toList() ?? [];
                                _selectedArea = aList.isNotEmpty ? aList.first : '';
                                final sList = subLocationsMap[_selectedArea] ?? [];
                                _selectedSubArea = sList.isNotEmpty ? sList.first : '';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: areas.contains(_selectedArea) ? _selectedArea : (areas.isNotEmpty ? areas.first : null),
                          decoration: InputDecoration(labelText: 'المنطقة / القضاء', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedArea = val;
                                final sList = subLocationsMap[_selectedArea] ?? [];
                                _selectedSubArea = sList.isNotEmpty ? sList.first : '';
                              });
                            }
                          },
                        ),
                        if (subAreas.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: subAreas.contains(_selectedSubArea) ? _selectedSubArea : (subAreas.isNotEmpty ? subAreas.first : null),
                            decoration: InputDecoration(labelText: 'الحي الدقيق', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: subAreas.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _selectedSubArea = val ?? ''),
                          ),
                        ],
                      ],
                    ],
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                      child: Text(
                        _isLoginMode ? 'ليس لديك حساب؟ انشئ حساباً جديداً' : 'لديك حساب بالفعل؟ سجل دخولك',
                        style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
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
