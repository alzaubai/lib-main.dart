import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const PitchBookingApp());
}

class PitchBookingApp extends StatelessWidget {
  const PitchBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة حجوزات الملعب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Tajawal',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // لون أخضر عشبي رياضي
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFF57F17),
          surface: const Color(0xFFF8FBF8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F4),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
      ),
      // ضبط اتجاه التطبيق كاملاً ليكون من اليمين لليسار
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: PitchHomeScreen(),
      ),
    );
  }
}

enum MatchStatus { upcoming, completed, cancelled }

class MatchBooking {
  final String id;
  final String teamOne;
  final String teamTwo;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? phone;
  final double? price;
  final String? notes;
  MatchStatus status;

  MatchBooking({
    required this.id,
    required this.teamOne,
    required this.teamTwo,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.phone,
    this.price,
    this.notes,
    this.status = MatchStatus.upcoming,
  });
}

class PitchHomeScreen extends StatefulWidget {
  const PitchHomeScreen({super.key});

  @override
  State<PitchHomeScreen> createState() => _PitchHomeScreenState();
}

class _PitchHomeScreenState extends State<PitchHomeScreen> {
  // قائمة الحجوزات فارغة للبدء من جديد بدون مباريات وهمية
  final List<MatchBooking> _bookings = [];

  String _filter = 'الكل'; // 'الكل' | 'اليوم' | 'القادمة' | 'المكتملة'

  List<MatchBooking> get _filteredBookings {
    return _bookings.where((booking) {
      final now = DateTime.now();
      final isToday = booking.date.year == now.year &&
          booking.date.month == now.month &&
          booking.date.day == now.day;

      if (_filter == 'اليوم') return isToday;
      if (_filter == 'القادمة') return booking.status == MatchStatus.upcoming;
      if (_filter == 'المكتملة') return booking.status == MatchStatus.completed;
      return true;
    }).toList()
      ..sort((a, b) {
        final aDateTime = DateTime(a.date.year, a.date.month, a.date.day, a.startTime.hour, a.startTime.minute);
        final bDateTime = DateTime(b.date.year, b.date.month, b.date.day, b.startTime.hour, b.startTime.minute);
        return aDateTime.compareTo(bDateTime);
      });
  }

  int get _todayBookingsCount {
    final now = DateTime.now();
    return _bookings.where((b) =>
        b.date.year == now.year &&
        b.date.month == now.month &&
        b.date.day == now.day).length;
  }

  void _addNewBooking(MatchBooking booking) {
    setState(() {
      _bookings.add(booking);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تثبيت حجز مباراة (${booking.teamOne} ⚔️ ${booking.teamTwo}) بنجاح!'),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteBooking(String id) {
    setState(() {
      _bookings.removeWhere((item) => item.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف الحجز بنجاح'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleStatus(MatchBooking booking) {
    setState(() {
      if (booking.status == MatchStatus.upcoming) {
        booking.status = MatchStatus.completed;
      } else {
        booking.status = MatchStatus.upcoming;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حجوزات الملعب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'إدارة مباريات الخصوم والأوقات',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTopSummaryBar(),
          _buildFilterChips(),
          Expanded(
            child: _filteredBookings.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredBookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(_filteredBookings[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('حجز مباراة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openAddBookingSheet(context),
      ),
    );
  }

  Widget _buildTopSummaryBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'حجوزات اليوم',
              value: '$_todayBookingsCount',
              icon: Icons.today,
              color: Colors.amber.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              title: 'إجمالي الحجوزات',
              value: '${_bookings.length}',
              icon: Icons.calendar_month,
              color: Colors.lightGreenAccent.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Icon(icon, color: color, size: 28),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['الكل', 'اليوم', 'القادمة', 'المكتملة'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((item) {
          final isSelected = _filter == item;
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FilterChip(
              label: Text(item),
              selected: isSelected,
              selectedColor: const Color(0xFF2E7D32).withOpacity(0.15),
              checkmarkColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (val) {
                setState(() {
                  _filter = item;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingCard(MatchBooking match) {
    final isCompleted = match.status == MatchStatus.completed;
    final formattedDate = DateFormat('yyyy/MM/dd').format(match.date);
    final startTimeStr = match.startTime.format(context);
    final endTimeStr = match.endTime.format(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggleStatus(match),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.grey.shade200 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCompleted ? 'مكتملة' : 'مؤكدة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.grey.shade700 : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // بطاقة الخصمين
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4E7D7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        match.teamOne,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ضد',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        match.teamTwo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // التوقيت والسعر
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(
                    'من $startTimeStr إلى $endTimeStr',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const Spacer(),
                  if (match.price != null)
                    Text(
                      '${match.price!.toStringAsFixed(0)} د.ع',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),

              if (match.phone != null && match.phone!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      match.phone!,
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ],
                ),
              ],

              if (match.notes != null && match.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.notes, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        match.notes!,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const Divider(height: 20),

              // الإجراءات (تغيير الحالة وحذف)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _toggleStatus(match),
                    icon: Icon(
                      isCompleted ? Icons.undo : Icons.check_circle_outline,
                      size: 18,
                      color: isCompleted ? Colors.orange : Colors.green,
                    ),
                    label: Text(
                      isCompleted ? 'إعادة كمؤكدة' : 'تحديد كمكتملة',
                      style: TextStyle(color: isCompleted ? Colors.orange : Colors.green),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirmDialog(match),
                    tooltip: 'حذف الحجز',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'لا توجد حجوزات مسجلة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          const Text(
            'اضغط على زر (حجز مباراة جديدة) بالأسفل لتسجيل أول موعد',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(MatchBooking match) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الحجز'),
          content: Text('هل أنت متأكد من حذف مباراة (${match.teamOne} ضد ${match.teamTwo})؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                _deleteBooking(match.id);
                Navigator.pop(ctx);
              },
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AddBookingBottomSheet(onAdd: _addNewBooking),
        );
      },
    );
  }
}

class AddBookingBottomSheet extends StatefulWidget {
  final Function(MatchBooking) onAdd;

  const AddBookingBottomSheet({super.key, required this.onAdd});

  @override
  State<AddBookingBottomSheet> createState() => _AddBookingBottomSheetState();
}

class _AddBookingBottomSheetState extends State<AddBookingBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _teamOneController = TextEditingController();
  final _teamTwoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 30);

  @override
  void dispose() {
    _teamOneController.dispose();
    _teamTwoController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          final autoHour = (picked.hour + 1) % 24;
          final autoMin = (picked.minute + 30) % 60;
          _endTime = TimeOfDay(hour: autoHour, minute: autoMin);
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newBooking = MatchBooking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        teamOne: _teamOneController.text.trim(),
        teamTwo: _teamTwoController.text.trim(),
        date: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        price: _priceController.text.trim().isEmpty ? null : double.tryParse(_priceController.text.trim()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      widget.onAdd(newBooking);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'حجز موعد مباراة جديد',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 16),

              // أسماء الفريقين
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _teamOneController,
                      decoration: InputDecoration(
                        labelText: 'الفريق الأول (الخصم 1)',
                        prefixIcon: const Icon(Icons.shield_outlined, color: Colors.green),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة الاسم' : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('⚔️', style: TextStyle(fontSize: 18)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _teamTwoController,
                      decoration: InputDecoration(
                        labelText: 'الفريق الثاني (الخصم 2)',
                        prefixIcon: const Icon(Icons.shield, color: Colors.green),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة الاسم' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // التاريخ
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 10),
                      Text(
                        'التاريخ: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Text('تغيير', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // التوقيت
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isStart: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('وقت البدء', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(_startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isStart: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('وقت الانتهاء', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(_endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // الهاتف والمبلغ
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم هاتف الحجز (اختياري)',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'السعر (د.ع)',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // الملاحظات
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ملاحظات (عربون، كرات، إلخ)',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    'تأكيد وحفظ الحجز',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
