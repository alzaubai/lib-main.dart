import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'add_manual_booking_sheet.dart';
import 'add_recurring_booking_sheet.dart';
import '../../tournaments/sheets/create_tournament_sheet.dart';

class OwnerQuickActionsSheet extends StatelessWidget {
  final String pitchName;
  final int durationMinutes;
  final double defaultRate;

  const OwnerQuickActionsSheet({
    super.key,
    required this.pitchName,
    required this.durationMinutes,
    required this.defaultRate,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('إجراءات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF1B5E20))),
              title: const Text('إضافة حجز يدوي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('تثبيت وقت محدد لفريق معين', style: TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => ModernAddBookingSheet(pitchName: pitchName, durationMinutes: durationMinutes, defaultRate: defaultRate));
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.repeat_rounded, color: Colors.purple.shade800)),
              title: const Text('إضافة اشتراك دائم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('تكرار الحجز أسبوعياً تلقائياً', style: TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => ModernAddRecurringSheet(pitchName: pitchName, durationMinutes: durationMinutes, defaultRate: defaultRate));
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.emoji_events_rounded, color: Colors.orange.shade900)),
              title: const Text('إنشاء بطولة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('تنظيم بطولة تنافسية في ملعبك', style: TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => CreateTournamentSheet(pitchName: pitchName));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
