import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/tournament_service.dart';
import 'dialogs/remove_team_dialog.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final String tournamentId;
  final bool isOwner;

  const TournamentDetailsScreen({
    super.key,
    required this.tournamentId,
    required this.isOwner,
  });

  @override
  State<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  bool _isStarting = false;

  Future<void> _startTournamentAndGenerateDraw(
    String tournamentName,
    List<dynamic> rawTeams,
  ) async {
    if (rawTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن يكون هناك فريقان على الأقل لبدء القرعة')),
      );
      return;
    }

    setState(() => _isStarting = true);

    try {
      final List<Map<String, dynamic>> teams =
          rawTeams.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      teams.shuffle(); // خلط الفرق عشوائياً للقرعة

      final List<Map<String, dynamic>> fixtures = [];
      final now = DateTime.now();

      for (int i = 0; i < teams.length; i += 2) {
        if (i + 1 < teams.length) {
          final t1 = teams[i];
          final t2 = teams[i + 1];
          final matchDate = now.add(Duration(days: (i ~/ 2) + 1));
          final dateStr = '${matchDate.year}-${matchDate.month.toString().padLeft(2, '0')}-${matchDate.day.toString().padLeft(2, '0')}';
          final timeStr = '${8 + (i % 3)}:00 م';

          fixtures.add({
            'team1Name': t1['teamName'] ?? t1['name'] ?? 'فريق 1',
            'team1Phone': t1['phone'] ?? '',
            'team2Name': t2['teamName'] ?? t2['name'] ?? 'فريق 2',
            'team2Phone': t2['phone'] ?? '',
            'date': dateStr,
            'time': timeStr,
            'round': 'الدور الأول',
          });
        }
      }

      await TournamentService.confirmDrawAndNotifyTeams(
        tournamentId: widget.tournamentId,
        tournamentName: tournamentName,
        fixtures: fixtures,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تثبيت القرعة بنجاح وإرسال مواعيد المباريات لجميع الفرق المشتركة'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تثبيت القرعة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF0F172A),
          title: const Text('تفاصيل البطولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) {
              return const Center(child: Text('البطولة غير موجودة'));
            }

            final name = data['name'] ?? 'بطولة كروية';
            final status = data['status'] ?? 'registration_open';
            final teams = (data['teams'] as List<dynamic>?) ?? [];
            final fixtures = (data['fixtures'] as List<dynamic>?) ?? [];
            final capacity = data['capacity'] ?? 8;
            final isDrawConfirmed = status == 'draw_confirmed';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة معلومات البطولة
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF1B5E20), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDrawConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isDrawConfirmed ? 'القرعة مثبتة' : 'التسجيل مفتوح',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDrawConfirmed ? const Color(0xFF1B5E20) : const Color(0xFFC2410C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('الفرق المسجلة: ${teams.length} من أصل $capacity', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // قائمة الفرق المسجلة مع زر الاستبعاد وكتابة السبب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الفرق المشتركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      Text('${teams.length} فرق', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (teams.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Text('لم يشترك أي فريق حتى الآن', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: teams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final team = Map<String, dynamic>.from(teams[i] as Map);
                        final tName = team['teamName'] ?? team['name'] ?? 'فريق';
                        final tPhone = team['phone'] ?? '';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFF1F5F9),
                                child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                    if (tPhone.toString().isNotEmpty)
                                      Text(tPhone.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              if (widget.isOwner && !isDrawConfirmed)
                                IconButton(
                                  icon: const Icon(Icons.person_remove_rounded, color: Color(0xFFDC2626), size: 20),
                                  tooltip: 'استبعاد وتحديد السبب',
                                  onPressed: () {
                                    RemoveTeamDialog.show(
                                      context,
                                      tournamentId: widget.tournamentId,
                                      tournamentName: name,
                                      teamData: team,
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // جدول مباريات القرعة إن كانت مثبتة
                  if (isDrawConfirmed) ...[
                    const Text('جدول مباريات الدور الأول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: fixtures.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final fix = fixtures[idx];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(fix['team1Name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Text('ضد', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  Text(fix['team2Name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const Divider(height: 14, color: Color(0xFFF1F5F9)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF1B5E20)),
                                  const SizedBox(width: 6),
                                  Text('${fix['date']} | الساعة ${fix['time']}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // زر تثبيت القرعة لصاحب الملعب
                  if (widget.isOwner && !isDrawConfirmed) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isStarting
                            ? null
                            : () => _startTournamentAndGenerateDraw(name, teams),
                        child: _isStarting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('تثبيت القرعة وبدء البطولة وإشعار الفرق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
