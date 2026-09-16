import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'add_manual_booking_sheet.dart';
import 'add_recurring_booking_sheet.dart';
import '../../tournaments/sheets/create_tournament_sheet.dart';

class OwnerQuickActionsSheet extends StatelessWidget {
  final String pitchName;

  const OwnerQuickActionsSheet({super.key, required this.pitchName});

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              'إجراء سريع',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20)),
              ),
              title: const Text('تثبيت حجز عادي يدوي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('حجز ساعة مباشرة لكابتن بدون تطبيق', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ModernAddBookingSheet(
                    pitchName: pitchName,
                    durationMinutes: 60,
                    defaultRate: 25000,
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.repeat_rounded, color: Colors.purple.shade800),
              ),
              title: const Text('تثبيت حجز دائم (أسبوعي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('حجز يوم وساعة ثابتة أسبوعياً لفريق', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddRecurringBookingSheet(
                    pitchName: pitchName,
                    defaultRate: 25000,
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
              ),
              title: const Text('إنشاء وإقامة بطولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('بدء دورة كروية وفتح التسجيل للفرق', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CreateTournamentSheet(pitchName: pitchName),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
