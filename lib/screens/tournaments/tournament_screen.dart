import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/tournament_card.dart';
import 'sheets/create_tournament_sheet.dart';
import 'sheets/tournament_bracket_sheet.dart';

class TournamentScreen extends StatelessWidget {
  final String userPhone;
  final bool isOwner;
  final String? pitchName;

  const TournamentScreen({
    super.key,
    required this.userPhone,
    required this.isOwner,
    this.pitchName,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    final query = isOwner && pitchName != null
        ? firestore.collection('tournaments').where('pitchName', isEqualTo: pitchName)
        : firestore.collection('tournaments');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
              ),
            );
          }

          final docs = (snapshot.data?.docs ?? []).where((d) {
            final data = d.data() as Map<String, dynamic>?;
            return data != null &&
                data.containsKey('title') &&
                data['title'].toString().trim().isNotEmpty;
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events_outlined, size: 56, color: Colors.amber.shade700),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'لا توجد بطولات حالياً',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return TournamentCard(
                        doc: doc,
                        userPhone: userPhone,
                        isOwner: isOwner,
                        onOpenBracket: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => TournamentBracketSheet(
                              tournamentId: doc.id,
                              tournamentTitle: data['title'] ?? 'البطولة',
                              pitchName: data['pitchName'] ?? '',
                              isOwner: isOwner,
                            ),
                          );
                        },
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_soccer, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text(
                        'نهاية قائمة البطولات',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.sports_soccer, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
