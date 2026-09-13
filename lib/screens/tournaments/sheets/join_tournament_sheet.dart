import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JoinTournamentSheet extends StatefulWidget {
  final DocumentReference tournamentRef;
  final String userPhone;
  final String tournamentTitle;

  const JoinTournamentSheet({
    super.key,
    required this.tournamentRef,
    required this.userPhone,
    required this.tournamentTitle,
  });

  @override
  State<JoinTournamentSheet> createState() => _JoinTournamentSheetState();
}

class _JoinTournamentSheetState extends State<JoinTournamentSheet> {
  final _teamNameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 16),
            Text('تسجيل فريق في: ${widget.tournamentTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            Text('رقم هاتف الكابتن المعتمد: ${widget.userPhone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            TextField(
              controller: _teamNameController,
              decoration: InputDecoration(
                labelText: 'اسم فريقك الرسمي',
                hintText: 'مثال: نجوم بغداد',
                prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final tName = _teamNameController.text.trim();
                        if (tName.isEmpty) return;

                        setState(() => _isSubmitting = true);

                        // حفظ اسم الفريق وإقرانه برقم هاتف الكابتن لمنع التسجيل المكرر
                        await widget.tournamentRef.update({
                          'teams': FieldValue.arrayUnion([tName]),
                          'registeredPlayers.${widget.userPhone}': tName,
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم تسجيل فريق ($tName) بنجاح ⚽'), backgroundColor: const Color(0xFF1B5E20)),
                          );
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('تأكيد تسجيل الفريق ⚽', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
