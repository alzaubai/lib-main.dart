import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_screen.dart';
import '../../services/pitch_image_service.dart';
import '../common/widgets/pitch_image_gallery.dart';

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
  final _phoneController = TextEditingController();
  final _rateController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  String? _pitchDocId;
  List<String> _pitchImages = [];

  @override
  void initState() {
    super.initState();
    _loadPitchData();
  }

  Future<void> _loadPitchData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pitches')
          .where('name', isEqualTo: widget.pitchName)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = doc.data();
        _pitchDocId = doc.id;
        _phoneController.text = (data['phone'] ?? data['ownerPhone'] ?? widget.userPhone).toString();
        _rateController.text = (data['hourlyRate'] ?? 25000).toString();
        _descController.text = (data['description'] ?? '').toString();
        _pitchImages = List<String>.from(data['images'] ?? []);
      } else {
        _phoneController.text = widget.userPhone;
        _rateController.text = '25000';
      }
    } catch (_) {
      _phoneController.text = widget.userPhone;
      _rateController.text = '25000';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    final success = await PitchImageService.pickImageDirectly(widget.pitchName);
    if (success) {
      await _loadPitchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة الصورة بنجاح'),
            backgroundColor: Color(0xFF1B5E20),
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
        const SnackBar(
          content: Text('تم حذف الصورة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final newPhone = _phoneController.text.trim();
    final newRate = double.tryParse(_rateController.text.trim()) ?? 25000.0;
    final newDesc = _descController.text.trim();

    try {
      final payload = {
        'phone': newPhone,
        'ownerPhone': newPhone,
        'hourlyRate': newRate,
        'description': newDesc,
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
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'إعدادات الملعب والحساب',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // قسم صور ومرافق الملعب
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
                          PitchImageGallery(
                            images: _pitchImages,
                            height: 160,
                            isEditable: true,
                            onRemoveImage: _removeImage,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'يمكنك التقاط أو اختيار صور للأرضية والإنارة وغرف التبديل لعرضها للفرق.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // قسم البيانات الأساسية
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
                            'بيانات الحجز المباشر',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
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
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),
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
