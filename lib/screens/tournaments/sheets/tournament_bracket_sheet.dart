import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentBracketSheet extends StatefulWidget {
  final String tournamentId;
  final String tournamentTitle;
  final String pitchName;
  final bool isOwner;

  const TournamentBracketSheet({
    super.key,
    required this.tournamentId,
    required this.tournamentTitle,
    required this.pitchName,
    required this.isOwner,
  });

  @override
  State<TournamentBracketSheet> createState() => _TournamentBracketSheetState();
}

class _TournamentBracketSheetState extends State<TournamentBracketSheet> {
  bool _isProcessing = false;

  void _generateRandomDraw(List<String> teams) async {
    if (teams.length < 2) {
      _showToast('يجب تسجيل فريقين على الأقل لإجراء القرعة');
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
            'nextMatchId': 'R2_M${(i ~/ 4) + 1}',
            'nextMatchSlot': (i % 4 == 0) ? 'teamA' : 'teamB',
          });
        } else {
          // تأهل مباشر
          roundMatches.add({
            'matchId': 'R1_M${(i ~/ 2) + 1}',
            'round': 1,
            'teamA': shuffled[i],
            'teamB': 'تأهل مباشر',
            'scoreA': 0,
            'scoreB': 0,
            'winner': shuffled[i],
            'isFinished': true,
            'nextMatchId': 'R2_M${(i ~/ 4) + 1}',
            'nextMatchSlot': (i % 4 == 0) ? 'teamA' : 'teamB',
          });
        }
      }

      int numMatchesInCurrentRound = roundMatches.length;
      int currentRound = 2;
      while (numMatchesInCurrentRound > 1) {
        int nextRoundMatchesCount = (numMatchesInCurrentRound / 2).ceil();
        for (int i = 0; i < nextRoundMatchesCount; i++) {
          roundMatches.add({
            'matchId': 'R${currentRound}_M${i + 1}',
            'round': currentRound,
            'teamA': 'بانتظار الفائز',
            'teamB': 'بانتظار الفائز',
            'scoreA': 0,
            'scoreB': 0,
            'winner': '',
            'isFinished': false,
            'nextMatchId': nextRoundMatchesCount > 1 ? 'R${currentRound + 1}_M${(i ~/ 2) + 1}' : null,
            'nextMatchSlot': (i % 2 == 0) ? 'teamA' : 'teamB',
          });
        }
        numMatchesInCurrentRound = nextRoundMatchesCount;
        currentRound++;
      }

      await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update({
        'matches': roundMatches,
        'status': 'active',
        'drawCount': FieldValue.increment(1), // زيادة عداد القرعة لتقييده لمرة واحدة
      });

      _showToast('تم إجراء القرعة بنجاح وتوزيع المباريات');
    } catch (_) {
      _showToast('حدث خطأ أثناء إجراء القرعة');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          // الكود راح يحدث فوري إذا انمسحت البطولة
          stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
            }

            // إذا انمسحت البطولة من قاعدة البيانات، نقفل النافذة تلقائياً
            if (!snapshot.hasData || !snapshot.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.pop(context);
              });
              return const SizedBox();
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final teams = List<String>.from(data['teams'] ?? []);
            final matches = List<dynamic>.from(data['matches'] ?? []);
            final int drawCount = (data['drawCount'] as num?)?.toInt() ?? 0;
            final String? champion = data['champion'];

            // زر القرعة يختفي إذا انضغط مرتين (أساسي + طوارئ)
            final bool canDraw = drawCount < 2;

            return Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.account_tree_rounded, color: Color(0xFF1B5E20), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tournamentTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('الفرق المشاركة: ${teams.length}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      if (widget.isOwner && canDraw) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: drawCount == 0 ? const Color(0xFF1B5E20) : Colors.orange.shade800,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: _isProcessing
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.shuffle_rounded, size: 14, color: Colors.white),
                          label: Text(
                            drawCount == 0 ? 'إجراء القرعة' : 'إعادة للطوارئ',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isProcessing ? null : () {
                            if (drawCount > 0) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('تحذير: إعادة القرعة!', style: TextStyle(color: Colors.red)),
                                  content: const Text('هذه آخر فرصة لإعادة القرعة. سيتم تصفير الجدول الحالي وتوزيع الفرق من جديد.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _generateRandomDraw(teams);
                                      },
                                      child: const Text('إعادة التوزيع', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              _generateRandomDraw(teams);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),

                // بانر تتويج البطل يظهر عند انتهاء البطولة
                if (champion != null && champion.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.amber.shade300, Colors.amber.shade500]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('بطل البطولة 🏆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(champion, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // قائمة المباريات المباشرة
                Expanded(
                  child: matches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_tree_outlined, size: 50, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('لم يتم إجراء القرعة بعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Text(
                                widget.isOwner ? 'اضغط على زر إجراء القرعة لتوزيع الفرق' : 'بانتظار قيام المنظم بإجراء القرعة',
                                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: matches.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _InlineMatchCard(
                              match: Map<String, dynamic>.from(matches[index]),
                              matchIndex: index,
                              allMatches: matches,
                              tournamentId: widget.tournamentId,
                              isOwner: widget.isOwner,
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

// كارت المباراة مع نظام التسجيل المباشر السريع (بدون ديالوك مزعج)
class _InlineMatchCard extends StatefulWidget {
  final Map<String, dynamic> match;
  final int matchIndex;
  final List<dynamic> allMatches;
  final String tournamentId;
  final bool isOwner;

  const _InlineMatchCard({
    required this.match,
    required this.matchIndex,
    required this.allMatches,
    required this.tournamentId,
    required this.isOwner,
  });

  @override
  State<_InlineMatchCard> createState() => _InlineMatchCardState();
}

class _InlineMatchCardState extends State<_InlineMatchCard> {
  late int scoreA;
  late int scoreB;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    scoreA = widget.match['scoreA'] ?? 0;
    scoreB = widget.match['scoreB'] ?? 0;
  }

  void _saveScore() async {
    if (scoreA == scoreB) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مباريات البطولة لا تقبل التعادل، يجب حسم الفائز!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isSaving = true);
    final teamA = widget.match['teamA'];
    final teamB = widget.match['teamB'];
    final winner = scoreA > scoreB ? teamA : teamB;

    final updatedMatches = List<Map<String, dynamic>>.from(widget.allMatches);
    
    updatedMatches[widget.matchIndex] = {
      ...widget.match,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'winner': winner,
      'isFinished': true,
    };

    final String? nextMatchId = widget.match['nextMatchId'];
    final String? nextMatchSlot = widget.match['nextMatchSlot'];

    if (nextMatchId != null && nextMatchSlot != null) {
      final nextMatchIndex = updatedMatches.indexWhere((m) => m['matchId'] == nextMatchId);
      if (nextMatchIndex != -1) {
        updatedMatches[nextMatchIndex] = {
          ...updatedMatches[nextMatchIndex],
          nextMatchSlot: winner,
        };
      }
    }

    final batch = FirebaseFirestore.instance.batch();
    final tournamentRef = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);

    batch.update(tournamentRef, {'matches': updatedMatches});

    if (nextMatchId == null) {
      batch.update(tournamentRef, {'status': 'completed', 'champion': winner});
    }

    await batch.commit();

    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final teamA = widget.match['teamA'] ?? '';
    final teamB = widget.match['teamB'] ?? '';
    final winner = widget.match['winner'] ?? '';
    final isFinished = widget.match['isFinished'] == true;
    final isFinalMatch = widget.match['nextMatchId'] == null;
    final roundName = isFinalMatch ? 'المباراة النهائية 🏆' : 'الدور ${widget.match['round']}';

    final bool canEdit = widget.isOwner && !isFinished && teamB != 'تأهل مباشر' && !teamA.contains('بانتظار') && !teamB.contains('بانتظار');

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isFinished ? const Color(0xFFE8F5E9) : Colors.transparent, width: isFinished ? 1.5 : 0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(roundName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: isFinished ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    isFinished ? 'انتهت' : 'بانتظار اللعب',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isFinished ? const Color(0xFF1B5E20) : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    teamA,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: winner == teamA ? FontWeight.bold : FontWeight.normal, color: winner == teamA ? const Color(0xFF1B5E20) : const Color(0xFF0F172A)),
                  ),
                ),
                
                // التحكم المباشر بالنتائج
                Expanded(
                  flex: 4,
                  child: canEdit
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildScoreAdjuster(scoreA, (v) => setState(() => scoreA = v)),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                            _buildScoreAdjuster(scoreB, (v) => setState(() => scoreB = v)),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Center(
                            child: Text(
                              '${widget.match['scoreA'] ?? 0} - ${widget.match['scoreB'] ?? 0}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                ),
                
                Expanded(
                  flex: 3,
                  child: Text(
                    teamB,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: winner == teamB ? FontWeight.bold : FontWeight.normal, color: winner == teamB ? const Color(0xFF1B5E20) : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            
            if (canEdit) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, visualDensity: VisualDensity.compact),
                  onPressed: isSaving ? null : _saveScore,
                  child: isSaving 
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('حفظ وصعود الفائز', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreAdjuster(int currentVal, Function(int) onChanged) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () { if (currentVal > 0) onChanged(currentVal - 1); },
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Icon(Icons.remove, size: 14, color: Colors.red)),
          ),
          Text('$currentVal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          InkWell(
            onTap: () => onChanged(currentVal + 1),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Icon(Icons.add, size: 14, color: Color(0xFF1B5E20))),
          ),
        ],
      ),
    );
  }
}
