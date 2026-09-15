import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentBracketScreen extends StatefulWidget {
  final String tournamentId;
  final bool isOwner;

  const TournamentBracketScreen({
    super.key,
    required this.tournamentId,
    required this.isOwner,
  });

  @override
  State<TournamentBracketScreen> createState() => _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen> {
  bool _isProcessing = false;

  void _generateRandomDraw(List<String> teams) async {
    if (teams.length < 2) {
      _showToast('يجب أن تحتوي البطولة على فريقين على الأقل لإجراء القرعة');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final shuffled = List<String>.from(teams)..shuffle(Random());
      final List<Map<String, dynamic>> roundMatches = [];

      for (int i = 0; i < shuffled.length; i += 2) {
        if (i + 1 < shuffled.length) {
          roundMatches.add({
            'matchId': 'R1_M${(i ~/ 2) + 1}',
            'round': 1,
            'teamA': shuffled[i],
            'teamB': shuffled[i + 1],
            'scoreA': 0,
            'scoreB': 0,
            'winner': '',
            'isFinished': false,
          });
        } else {
          roundMatches.add({
            'matchId': 'R1_M${(i ~/ 2) + 1}',
            'round': 1,
            'teamA': shuffled[i],
            'teamB': 'تأهل مباشر',
            'scoreA': 0,
            'scoreB': 0,
            'winner': shuffled[i],
            'isFinished': true,
          });
        }
      }

      await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update({
        'matches': roundMatches,
        'status': 'active',
      });

      _showToast('تمت إجراء القرعة وتوزيع المباريات');
    } catch (_) {
      _showToast('حدث خطأ أثناء إجراء القرعة');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showScoreDialog(Map<String, dynamic> match, int matchIndex, List<dynamic> allMatches) {
    if (!widget.isOwner) return;

    final scoreACtrl = TextEditingController(text: '${match['scoreA'] ?? 0}');
    final scoreBCtrl = TextEditingController(text: '${match['scoreB'] ?? 0}');
    final teamA = match['teamA'] ?? 'فريق أ';
    final teamB = match['teamB'] ?? 'فريق ب';

    if (teamB == 'تأهل مباشر') return;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تسجيل أهداف المباراة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teamA, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
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
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ضد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teamB, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
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
                    const SnackBar(content: Text('يجب حسم النتيجة بفائز (لا يمكن التعادل في خروج المغلوب)'), behavior: SnackBarBehavior.floating),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final updatedMatches = List<Map<String, dynamic>>.from(allMatches);
                final winner = sA > sB ? teamA : teamB;

                updatedMatches[matchIndex] = {
                  ...match,
                  'scoreA': sA,
                  'scoreB': sB,
                  'winner': winner,
                  'isFinished': true,
                };

                await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update({
                  'matches': updatedMatches,
                });

                _showToast('تم اعتماد نتيجة المباراة وتأهل ($winner)');
              },
              child: const Text('حفظ النتيجة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          title: const Text('مخطط ونتائج البطولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
            }

            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final title = data['title'] ?? 'البطولة';
            final teams = List<String>.from(data['teams'] ?? []);
            final matches = List<dynamic>.from(data['matches'] ?? []);

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('الفرق المشاركة: ${teams.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (widget.isOwner)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: _isProcessing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.shuffle_rounded, size: 16, color: Colors.white),
                          label: Text(
                            matches.isEmpty ? 'إجراء القرعة' : 'إعادة القرعة',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isProcessing ? null : () => _generateRandomDraw(teams),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: matches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_tree_outlined, size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('لم يتم إجراء القرعة بعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Text(
                                widget.isOwner ? 'اضغط على زر إجراء القرعة لتوليد المواجهات' : 'بانتظار قيام منظم البطولة بإجراء القرعة',
                                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: matches.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final m = Map<String, dynamic>.from(matches[index]);
                            final teamA = m['teamA'] ?? '';
                            final teamB = m['teamB'] ?? '';
                            final scoreA = m['scoreA'] ?? 0;
                            final scoreB = m['scoreB'] ?? 0;
                            final winner = m['winner'] ?? '';
                            final isFinished = m['isFinished'] == true;

                            return Card(
                              elevation: 1.5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text('مباراة ${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isFinished ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isFinished ? 'انتهت' : 'بانتظار اللعب',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isFinished ? const Color(0xFF1B5E20) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            teamA,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: winner == teamA ? FontWeight.bold : FontWeight.normal,
                                              color: winner == teamA ? const Color(0xFF1B5E20) : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Text(
                                            '$scoreA - $scoreB',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            teamB,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: winner == teamB ? FontWeight.bold : FontWeight.normal,
                                              color: winner == teamB ? const Color(0xFF1B5E20) : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (widget.isOwner && teamB != 'تأهل مباشر') ...[
                                      const Divider(height: 16),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            foregroundColor: const Color(0xFF1B5E20),
                                          ),
                                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                                          label: const Text('تسجيل / تعديل الأهداف', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                          onPressed: () => _showScoreDialog(m, index, matches),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
