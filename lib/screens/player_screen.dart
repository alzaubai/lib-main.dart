import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'auth_screen.dart';
import 'tournaments/tournament_screen.dart';

class PlayerScreen extends StatefulWidget {
  final String userPhone;
  const PlayerScreen({super.key, required this.userPhone});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedGov = 'الكل';
  String selectedArea = 'الكل';
  String selectedType = 'الكل';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF1B5E20),
          title: const Row(
            children: [
              Icon(Icons.sports_soccer, color: Colors.amberAccent, size: 24),
              SizedBox(width: 8),
              Text('ملعبي - حجز الملاعب ⚽', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white70),
              tooltip: 'تسجيل خروج',
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              color: const Color(0xFF1B5E20),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: Colors.amberAccent,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.explore_rounded, size: 18), text: 'استكشاف الملاعب'),
                  Tab(icon: Icon(Icons.bookmark_added_rounded, size: 18), text: 'حجوزاتي'),
                  Tab(icon: Icon(Icons.emoji_events_rounded, size: 18), text: 'البطولات 🏆'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildExploreTab(),
            _buildMyBookingsTab(),
            TournamentScreen(userPhone: widget.userPhone, isOwner: false),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab() {
    return Column(
      children: [
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
                                onPressed: () => _openBookingScheduleModal(context, pName, rate),
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
    );
  }

  void _openBookingScheduleModal(BuildContext context, String pitchName, double hourlyRate) {
    DateTime selectedDate = DateTime.now();
    final availableSlots = buildPitchSlots(60);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('جدول مواعيد: $pitchName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                          const Text('الأخضر متاح للحجز / الأحمر محجوز أو بطولة', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87, elevation: 0),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final p = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (p != null) setModalState(() => selectedDate = p);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('bookings')
                          .where('pitchName', isEqualTo: pitchName)
                          .where('date', isEqualTo: dateStr)
                          .where('status', whereIn: ['pending', 'upcoming', 'tournament_match', 'completed'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final bookings = snapshot.data?.docs ?? [];

                        return ListView.builder(
                          itemCount: availableSlots.length,
                          itemBuilder: (context, idx) {
                            final slot = availableSlots[idx];
                            final parts = slot.split(' - ');
                            final sTime = parts[0].trim();

                            final matchingBooking = bookings.cast<DocumentSnapshot?>().firstWhere(
                              (b) {
                                final d = b!.data() as Map<String, dynamic>;
                                final bookStartTime = (d['startTime'] ?? '').toString().trim();
                                return bookStartTime == sTime;
                              },
                              orElse: () => null,
                            );

                            final isBooked = matchingBooking != null;
                            Map<String, dynamic>? bData = isBooked ? matchingBooking.data() as Map<String, dynamic> : null;
                            final isTournament = bData?['status'] == 'tournament_match';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isBooked ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isBooked ? Colors.red.shade200 : Colors.green.shade300),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  isTournament ? Icons.emoji_events : (isBooked ? Icons.cancel : Icons.check_circle),
                                  color: isBooked ? Colors.red : Colors.green,
                                ),
                                title: Text(slot, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isBooked ? Colors.red.shade900 : Colors.green.shade900)),
                                subtitle: isTournament
                                    ? Text('🏆 بطولة رسمية: ${bData?['teamOne']} ⚔️ ${bData?['teamTwo']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900))
                                    : (isBooked ? const Text('هذا الموعد محجوز مسبقاً ❌', style: TextStyle(fontSize: 11, color: Colors.red)) : const Text('متاح للحجز المباشر ✔️', style: TextStyle(fontSize: 11, color: Colors.green))),
                                trailing: isBooked
                                    ? const Chip(label: Text('محجوز', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.red)
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(horizontal: 12)),
                                        onPressed: () => _openRequestDialog(context, pitchName, dateStr, slot, hourlyRate),
                                        child: const Text('احجز الآن', style: TextStyle(color: Colors.white, fontSize: 12)),
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
            ),
          );
        },
      ),
    );
  }

  void _openRequestDialog(BuildContext context, String pitchName, String date, String slot, double price) {
    final teamCtrl = TextEditingController();
    final times = slot.split(' - ');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد طلب الحجز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الملعب: $pitchName'),
              Text('الموعد: $date ($slot)'),
              const SizedBox(height: 10),
              TextField(
                controller: teamCtrl,
                decoration: const InputDecoration(labelText: 'اسم فريقك', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                final tName = teamCtrl.text.trim();
                if (tName.isNotEmpty) {
                  await _firestore.collection('bookings').add({
                    'pitchName': pitchName,
                    'teamOne': tName,
                    'teamTwo': 'تحدي',
                    'date': date,
                    'startTime': times[0].trim(),
                    'endTime': times.length > 1 ? times[1].trim() : '',
                    'price': price,
                    'phone': widget.userPhone,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال طلب الحجز للملعب بنجاح!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bookings').where('phone', isEqualTo: widget.userPhone).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('لا توجد لديك حجوزات سابقة أو حالية'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';

            Color statusColor = Colors.amber;
            String statusText = 'قيد المراجعة';
            if (status == 'upcoming') {
              statusColor = Colors.green;
              statusText = 'مؤكد ومثبت ✔️';
            } else if (status == 'rejected') {
              statusColor = Colors.red;
              statusText = 'مرفوض ❌';
            } else if (status == 'completed') {
              statusColor = Colors.blue;
              statusText = 'مكتمل ولُعب ⚽';
            }

            return Card(
              child: ListTile(
                title: Text('${data['pitchName']} (${data['date']})'),
                subtitle: Text('الفترة: ${data['startTime']} إلى ${data['endTime']}'),
                trailing: Chip(label: Text(statusText, style: const TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: statusColor),
              ),
            );
          },
        );
      },
    );
  }
}
