import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth_screen.dart';
import '../../../constants.dart';
import '../../../services/location_service.dart';
import '../../../services/pitch_image_service.dart';

class OwnerSettingsScreen extends StatefulWidget {
  final String userPhone;
  final String pitchName;

  const OwnerSettingsScreen({
    super.key,
    required this.userPhone,
    required this.pitchName,
  });

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  // الحقول النصية
  late final TextEditingController _phoneController;
  late final TextEditingController _rateController;
  late final TextEditingController _descController;
  late final TextEditingController _addressDetailsController;

  // القوائم المنسدلة
  String _selectedGov = 'بغداد';
  String _selectedArea = 'الكرخ';
  String _selectedPitchType = 'سباعي (7 ضد 7)';
  String _selectedSurface = 'ثيل 🌿';

  // ساعات نشاط وعمل الملعب
  String _openTime = '04:00 م';
  String _closeTime = '03:00 ص';

  // الموقع الجغرافي
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  // الصور والحالة
  bool _isSaving = false;
  bool _isPickingImage = false;
  String? _pitchDocId;
  List<String> _pitchImages = [];

  final List<String> _timeHoursList = [
    '12:00 م', '01:00 م', '02:00 م', '03:00 م', '04:00 م', '05:00 م',
    '06:00 م', '07:00 م', '08:00 م', '09:00 م', '10:00 م', '11:00 م',
    '12:00 ص', '01:00 ص', '02:00 ص', '03:00 ص', '04:00 ص', '05:00 ص',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.userPhone);
    _rateController = TextEditingController(text: '25000');
    _descController = TextEditingController();
    _addressDetailsController = TextEditingController();
    _loadPitchData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _rateController.dispose();
    _descController.dispose();
    _addressDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadPitchData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pitches')
          .where('name', isEqualTo: widget.pitchName)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty && mounted) {
        final doc = snap.docs.first;
        final data = doc.data();
        setState(() {
          _pitchDocId = doc.id;
          _phoneController.text = (data['phone'] ?? data['ownerPhone'] ?? widget.userPhone).toString();
          _rateController.text = (data['hourlyRate'] ?? 25000).toInt().toString();
          _descController.text = (data['description'] ?? '').toString();
          _addressDetailsController.text = (data['addressDetails'] ?? '').toString();

          final gov = (data['governorate'] ?? '').toString();
          if (iraqGovernoratesList.contains(gov)) _selectedGov = gov;

          final area = (data['area'] ?? '').toString();
          final availableAreas = getAreasListForGov(_selectedGov);
          if (availableAreas.contains(area)) _selectedArea = area;

          final pType = (data['pitchType'] ?? '').toString();
          if (pitchTypesList.contains(pType)) _selectedPitchType = pType;

          final surface = (data['surfaceType'] ?? '').toString();
          if (pitchSurfaceTypesList.contains(surface)) _selectedSurface = surface;

          _openTime = data['openTime'] ?? '04:00 م';
          _closeTime = data['closeTime'] ?? '03:00 ص';
          _latitude = (data['latitude'] as num?)?.toDouble();
          _longitude = (data['longitude'] as num?)?.toDouble();
          _pitchImages = List<String>.from(data['images'] ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('تم التقاط إحداثيات الملعب الجغرافية بدقة ✔️', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).size.height - 120,
          ),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تعذر جلب الموقع، يرجى تفعيل الـ GPS ومنح الصلاحية'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).size.height - 120,
          ),
        ),
      );
    }
    if (mounted) setState(() => _isLocating = false);
  }

  void _testWazeLocation() async {
    if (_latitude == null || _longitude == null) return;
    final uri = Uri.parse('waze://?ll=$_latitude,$_longitude&navigate=yes');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    final success = await PitchImageService.pickImageDirectly(widget.pitchName);
    if (success) {
      await _loadPitchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت إضافة الصورة بنجاح'),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).size.height - 120,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    if (mounted) setState(() => _isPickingImage = false);
  }

  Future<void> _removeImage(String img) async {
    await PitchImageService.removeImage(widget.pitchName, img);
    await _loadPitchData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حذف الصورة'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).size.height - 120,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final newPhone = _phoneController.text.trim();
    final newRate = double.tryParse(_rateController.text.trim()) ?? 25000.0;
    final newDesc = _descController.text.trim();
    final newAddress = _addressDetailsController.text.trim();

    try {
      final payload = {
        'phone': newPhone,
        'ownerPhone': newPhone,
        'hourlyRate': newRate,
        'governorate': _selectedGov,
        'area': _selectedArea,
        'pitchType': _selectedPitchType,
        'surfaceType': _selectedSurface,
        'addressDetails': newAddress,
        'description': newDesc,
        'openTime': _openTime,
        'closeTime': _closeTime,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_pitchDocId != null) {
        await FirebaseFirestore.instance.collection('pitches').doc(_pitchDocId).update(payload);
      } else {
        await FirebaseFirestore.instance.collection('pitches').doc(widget.pitchName).set({
          'name': widget.pitchName,
          ...payload,
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('تم حفظ وتحديث إعدادات الملعب بنجاح ✔️', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).size.height - 120,
            ),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).size.height - 120,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildInternalImagesGallery() {
    if (_pitchImages.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 38, color: Colors.grey),
            SizedBox(height: 6),
            Text(
              'لم تتم إضافة أي صور للملعب بعد',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pitchImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final rawImage = _pitchImages[index];
          Widget imgWidget;

          if (!rawImage.startsWith('http')) {
            try {
              final bytes = base64Decode(rawImage);
              imgWidget = Image.memory(bytes, fit: BoxFit.cover, width: 140, height: 130);
            } catch (_) {
              imgWidget = Container(
                width: 140,
                height: 130,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            }
          } else {
            imgWidget = Image.network(
              rawImage,
              fit: BoxFit.cover,
              width: 140,
              height: 130,
              errorBuilder: (_, __, ___) => Container(
                width: 140,
                height: 130,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          }

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imgWidget,
              ),
              Positioned(
                top: 4,
                left: 4,
                child: InkWell(
                  onTap: () => _removeImage(rawImage),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          elevation: 1,
          title: const Text(
            'إعدادات الملعب والحساب',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. صور ومرافق الملعب
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library_rounded, color: Color(0xFF1B5E20), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'صور الملعب والمرافق',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: _isPickingImage
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.add_a_photo_rounded, size: 16),
                          label: const Text('إضافة صورة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: _isPickingImage ? null : _pickImage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInternalImagesGallery(),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. الموقع الجغرافي والـ GPS المباشر
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: Color(0xFF1B5E20), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'الموقع الجغرافي الدقيق (Waze و Maps)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _latitude != null && _longitude != null
                          ? 'الإحداثيات المثبتة حالياً: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                          : 'لم يتم تثبيت إحداثيات الملعب بدقة بعد. اضغط على الزر وأنت في موقع الملعب.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _latitude != null ? const Color(0xFF1B5E20) : const Color(0xFF64748B),
                        fontWeight: _latitude != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: _isLocating
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.my_location_rounded, size: 18),
                            label: const Text('تثبيت موقع الملعب من الـ GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _isLocating ? null : _getCurrentLocation,
                          ),
                        ),
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                              side: const BorderSide(color: Colors.blueAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            ),
                            icon: const Icon(Icons.near_me_rounded, size: 16),
                            label: const Text('تجربة Waze', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _testWazeLocation,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. ساعات نشاط وعمل الملعب
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: Color(0xFF1B5E20), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ساعات النشاط اليومي للملعب',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _openTime,
                            decoration: InputDecoration(
                              labelText: 'بداية النشاط',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _timeHoursList.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setState(() => _openTime = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _closeTime,
                            decoration: InputDecoration(
                              labelText: 'نهاية النشاط',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _timeHoursList.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setState(() => _closeTime = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. البيانات والمواصفات الكاملة
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات ومواصفات الملعب',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGov,
                            decoration: InputDecoration(
                              labelText: 'المحافظة',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
                            decoration: InputDecoration(
                              labelText: 'المنطقة',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: availableAreas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedArea = val);
                            },
                          ),
                        ),
                      ],
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
                            ),
                            items: validPitchTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPitchType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSurface,
                            decoration: InputDecoration(
                              labelText: 'نوع الأرضية',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: validSurfaces.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSurface = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر الساعة الافتراضي (د.ع)',
                        prefixIcon: const Icon(Icons.payments_rounded, color: Colors.teal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم هاتف التواصل للفرق',
                        prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF1B5E20)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressDetailsController,
                      decoration: InputDecoration(
                        labelText: 'أقرب نقطة دالة للملعب',
                        prefixIcon: const Icon(Icons.place_outlined, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'وصف إضافي أو خدمات (موقف، إضاءة، ماء)',
                        prefixIcon: const Icon(Icons.description_rounded, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // زر الحفظ
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveSettings,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 20),

              // تسجيل الخروج
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                tileColor: Colors.red.shade50,
                leading: Icon(Icons.logout_rounded, color: Colors.red.shade700),
                title: Text(
                  'تسجيل الخروج من الحساب',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل أنت متأكد من تسجيل الخروج من لوحة إدارة الملعب؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _logout();
                          },
                          child: const Text('تأكيد الخروج', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
