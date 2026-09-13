import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import '../sheets/player_booking_sheet.dart';

class PlayerExploreTab extends StatefulWidget {
  final String userPhone;
  const PlayerExploreTab({super.key, required this.userPhone});

  @override
  State<PlayerExploreTab> createState() => _PlayerExploreTabState();
}

class _PlayerExploreTabState extends State<PlayerExploreTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedGov = 'الكل';
  String selectedArea = 'الكل';
  String selectedType = 'الكل';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          // شريط البحث والفلاتر
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الملعب أو المنطقة...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true,
                    fillColor: const Color(0xFFF9FBF9),
                  ),
                  onChanged: (v) => setState(() => searchQuery = v.trim()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: selectedGov,
                        underline: const SizedBox(),
                        items: iraqGovernoratesList.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (v) => setState(() {
                          selectedGov = v!;
                          selectedArea = 'الكل';
                        }),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedArea,
                        underline: const SizedBox(),
                        items: getAreasListForGov(selectedGov).map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (v) => setState(() => selectedArea = v!),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedType,
                        underline: const SizedBox(),
                        items: pitchTypesList.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (v) => setState(() => selectedType = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // قائمة الملاعب
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('pitches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];

                docs = docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = (d['name'] ?? doc.id).toString();
                  final gov = (d['governorate'] ?? '').toString();
                  final area = (d['area'] ?? '').toString();
                  final pType = (d['pitchType'] ?? '').toString();

                  if (searchQuery.isNotEmpty && !name.contains(searchQuery) && !area.contains(searchQuery)) {
                    return false;
                  }
                  if (selectedGov != 'الكل' && gov != selectedGov) return false;
                  if (selectedArea != 'الكل' && area != selectedArea) return false;
                  if (selectedType != 'الكل' && pType != selectedType) return false;

                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stadium_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text('لا توجد ملاعب مطابقة للبحث حالياً', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final pName = data['name'] ?? doc.id;
                    final phone = data['phone'] ?? '';
                    final rate = (data['hourlyRate'] as num?)?.toDouble() ?? 25000.0;
                    final type = data['pitchType'] ?? 'سباعي';
                    final surface = data['surfaceType'] ?? 'ثيل';
                    final addressDesc = data['description'] ?? '';
                    final lat = (data['latitude'] as num?)?.toDouble();
                    final lng = (data['longitude'] as num?)?.toDouble();

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(pName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                Text('${NumberFormat('#,###').format(rate)} د.ع / ساعة', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Chip(label: Text(type, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                                const SizedBox(width: 6),
                                Chip(label: Text(surface, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                              ],
                            ),
                            if (addressDesc.toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('📍 $addressDesc', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                            const Divider(height: 18),
                            Row(
                              children: [
                                if (phone.toString().isNotEmpty)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 10)),
                                    icon: const Icon(Icons.phone, size: 16, color: Colors.white),
                                    label: const Text('اتصال', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    onPressed: () => launchCallDirect(phone),
                                  ),
                                if (lat != null && lng != null) ...[
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                    icon: const Icon(Icons.location_on, size: 16, color: Colors.blue),
                                    label: const Text('الموقع', style: TextStyle(fontSize: 12)),
                                    onPressed: () => launchMapDirect(lat, lng),
                                  ),
                                ],
                                const Spacer(),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                                  icon: const Icon(Icons.calendar_month, size: 16, color: Colors.white),
                                  label: const Text('عرض المواعيد 📅', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => PlayerBookingSheet(
                                        pitchName: pName,
                                        hourlyRate: rate,
                                        userPhone: widget.userPhone,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
