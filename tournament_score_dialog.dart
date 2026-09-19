import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentScoreDialog {
  static void show(
    BuildContext context, {
    required Map<String, dynamic> match,
    required int matchIndex,
    required List<dynamic> allMatches,
    required String tournamentId,
  }) {
    final scoreACtrl = TextEditingController(text: '${match['scoreA'] ?? 0}');
    final scoreBCtrl = TextEditingController(text: '${match['scoreB'] ?? 0}');
    final teamA = match['teamA'] ?? 'فريق أول';
    final teamB = match['teamB'] ?? 'فريق ثانٍ';

    // لا يمكن تسجيل نتيجة لمباراة بها (تأهل مباشر)
    if (teamB == 'تأهل مباشر') return;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B5E20), size: 22),
              SizedBox(width: 8),
              Text('تسجيل أهداف المباراة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamA,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: scoreACtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('ضد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamB,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: scoreBCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final sA = int.tryParse(scoreACtrl.text.trim()) ?? 0;
                final sB = int.tryParse(scoreBCtrl.text.trim()) ?? 0;

                if (sA == sB) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يجب حسم النتيجة بفائز (لا يمكن التعادل في مباريات خروج المغلوب)'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final updatedMatches = List<Map<String, dynamic>>.from(allMatches);
                final winner = sA > sB ? teamA : teamB;

                // تحديث المباراة الحالية بالنتيجة واسم الفائز
                updatedMatches[matchIndex] = {
                  ...match,
                  'scoreA': sA,
                  'scoreB': sB,
                  'winner': winner,
                  'isFinished': true,
                };

                // محرك البطولة الذكي (Tournament Engine)
                // البحث عن المباراة القادمة (إن وجدت) وتصعيد الفائز إليها
                final String? nextMatchId = match['nextMatchId'];
                final String? nextMatchSlot = match['nextMatchSlot']; // 'teamA' أو 'teamB'

                if (nextMatchId != null && nextMatchSlot != null) {
                  final nextMatchIndex = updatedMatches.indexWhere((m) => m['matchId'] == nextMatchId);
                  if (nextMatchIndex != -1) {
                    updatedMatches[nextMatchIndex] = {
                      ...updatedMatches[nextMatchIndex],
                      nextMatchSlot: winner, // تحديث اسم الفريق في المباراة القادمة
                    };
                  }
                }

                final batch = FirebaseFirestore.instance.batch();
                final tournamentRef = FirebaseFirestore.instance.collection('tournaments').doc(tournamentId);

                // حفظ الجدول المحدث
                batch.update(tournamentRef, {'matches': updatedMatches});

                // إذا كانت المباراة هي النهائية (لا توجد مباراة بعدها)، يتم إعلان بطل البطولة
                if (nextMatchId == null) {
                  batch.update(tournamentRef, {
                    'status': 'completed',
                    'champion': winner,
                  });
                }

                await batch.commit();

                if (context.mounted) {
                  if (nextMatchId == null) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 مبروك! انتهت البطولة وتتويج ($winner) باللقب'),
                        backgroundColor: Colors.amber.shade900,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم اعتماد النتيجة وصعود ($winner) للدور القادم'),
                        backgroundColor: Colors.black87,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ النتيجة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
