import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/dialogs/logout_dialog.dart';
import 'widgets/pitch_location_card.dart';
import 'widgets/pitch_media_card.dart';
import 'widgets/pitch_info_form.dart';

class OwnerSettingsScreen extends StatefulWidget {
  final String userPhone;
  final String pitchName;

  const OwnerSettingsScreen({super.key, required this.userPhone, required this.pitchName});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  final _phoneCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '25000');
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _gov = 'بغداد';
  String _area = 'الكرخ';
  String _type = 'سباعي (7 ضد 7)';
  String _surface = 'ثيل 🌿';
  String _openTime = '04:00 م';
  String _closeTime = '03:00 ص';
  double? _lat, _lng;
  List<String> _images = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.userPhone;
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance.collection('pitches').doc(widget.pitchName).get();
    if (doc.exists && mounted) {
      final d = doc.data()!;
      setState(() {
        _phoneCtrl.text = (d['phone'] ?? widget.userPhone).toString();
        _rateCtrl.text = (d['hourlyRate'] ?? 25000).toInt().toString();
        _descCtrl.text = (d['description'] ?? '').toString();
        _addressCtrl.text = (d['addressDetails'] ?? '').toString();
        _gov = d['governorate'] ?? 'بغداد';
        _area = d['area'] ?? 'الكرخ';
        _type = d['pitchType'] ?? 'سباعي (7 ضد 7)';
        _surface = d['surfaceType'] ?? 'ثيل 🌿';
        _openTime = d['openTime'] ?? '04:00 م';
        _closeTime = d['closeTime'] ?? '03:00 ص';
        _lat = (d['latitude'] as num?)?.toDouble();
        _lng = (d['longitude'] as num?)?.toDouble();
        _images = List<String>.from(d['images'] ?? []);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance.collection('pitches').doc(widget.pitchName).set({
      'name': widget.pitchName,
      'phone': _phoneCtrl.text.trim(),
      'hourlyRate': double.tryParse(_rateCtrl.text.trim()) ?? 25000.0,
      'governorate': _gov,
      'area': _area,
      'pitchType': _type,
      'surfaceType': _surface,
      'addressDetails': _addressCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'openTime': _openTime,
      'closeTime': _closeTime,
      if (_lat != null) 'latitude': _lat,
      if (_lng != null) 'longitude': _lng,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: const Text('إعدادات الملعب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () => LogoutDialog.show(context, userTypeMessage: 'هل أنت متأكد من تسجيل الخروج من إدارة الملعب؟'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PitchMediaCard(pitchName: widget.pitchName, initialImages: _images, onImagesChanged: _loadData),
              const SizedBox(height: 14),
              PitchLocationCard(initialLat: _lat, initialLng: _lng, onLocationCaptured: (la, ln) { _lat = la; _lng = ln; }),
              const SizedBox(height: 14),
              PitchInfoForm(
                rateCtrl: _rateCtrl,
                phoneCtrl: _phoneCtrl,
                addressCtrl: _addressCtrl,
                descCtrl: _descCtrl,
                selectedGov: _gov,
                selectedArea: _area,
                selectedType: _type,
                selectedSurface: _surface,
                openTime: _openTime,
                closeTime: _closeTime,
                onGovChanged: (v) => setState(() => _gov = v),
                onAreaChanged: (v) => setState(() => _area = v),
                onTypeChanged: (v) => setState(() => _type = v),
                onSurfaceChanged: (v) => setState(() => _surface = v),
                onOpenTimeChanged: (v) => setState(() => _openTime = v),
                onCloseTimeChanged: (v) => setState(() => _closeTime = v),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
