import 'package:flutter/material.dart';
import '../../../constants.dart';

class PitchInfoForm extends StatelessWidget {
  final TextEditingController rateCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController descCtrl;
  final String selectedGov;
  final String selectedArea;
  final String selectedType;
  final String selectedSurface;
  final String openTime;
  final String closeTime;
  final Function(String) onGovChanged;
  final Function(String) onAreaChanged;
  final Function(String) onTypeChanged;
  final Function(String) onSurfaceChanged;
  final Function(String) onOpenTimeChanged;
  final Function(String) onCloseTimeChanged;

  const PitchInfoForm({
    super.key,
    required this.rateCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.descCtrl,
    required this.selectedGov,
    required this.selectedArea,
    required this.selectedType,
    required this.selectedSurface,
    required this.openTime,
    required this.closeTime,
    required this.onGovChanged,
    required this.onAreaChanged,
    required this.onTypeChanged,
    required this.onSurfaceChanged,
    required this.onOpenTimeChanged,
    required this.onCloseTimeChanged,
  });

  static const _hours = [
    '12:00 م', '01:00 م', '02:00 م', '03:00 م', '04:00 م', '05:00 م',
    '06:00 م', '07:00 م', '08:00 م', '09:00 م', '10:00 م', '11:00 م',
    '12:00 ص', '01:00 ص', '02:00 ص', '03:00 ص', '04:00 ص', '05:00 ص',
  ];

  @override
  Widget build(BuildContext context) {
    final areas = getAreasListForGov(selectedGov).where((a) => a != 'الكل').toList();
    final govs = iraqGovernoratesList.where((g) => g != 'الكل').toList();

    return Column(
      children: [
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
              const Text('ساعات النشاط اليومي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: openTime,
                      decoration: InputDecoration(labelText: 'بداية النشاط', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _hours.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => onOpenTimeChanged(v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: closeTime,
                      decoration: InputDecoration(labelText: 'نهاية النشاط', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _hours.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => onCloseTimeChanged(v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
              const Text('بيانات ومواصفات الملعب', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedGov,
                      decoration: InputDecoration(labelText: 'المحافظة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: govs.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => onGovChanged(v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: areas.contains(selectedArea) ? selectedArea : (areas.isNotEmpty ? areas.first : 'المركز'),
                      decoration: InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: areas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => onAreaChanged(v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(labelText: 'حجم الملعب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: pitchTypesList.where((t) => t != 'الكل').map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => onTypeChanged(v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedSurface,
                      decoration: InputDecoration(labelText: 'الأرضية', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: pitchSurfaceTypesList.where((s) => s != 'الكل').map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => onSurfaceChanged(v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'سعر الساعة (د.ع)',
                  prefixIcon: const Icon(Icons.payments_rounded, color: Colors.teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'هاتف التواصل',
                  prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF1B5E20)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: 'أقرب نقطة دالة',
                  prefixIcon: const Icon(Icons.place_outlined, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'وصف إضافي',
                  prefixIcon: const Icon(Icons.description_rounded, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
