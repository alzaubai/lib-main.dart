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

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: StreamBuilder<QuerySnapshot>(
          stream: isOwner && pitchName != null
              ? firestore.collection('tournaments').where('pitchName', isEqualTo: pitchName).snapshots()
              : firestore.collection('tournaments').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
            }

            final docs = (snapshot.data?.docs ?? []).where((d) {
              final data = d.data() as Map<String, dynamic>?;
              return data != null && data.containsKey('title') && data.containsKey('pitchName');
            }).toList();

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.emoji_events_outlined, size: 60, color: Colors.amber.shade700),
                    ),
                    const SizedBox(height: 14),
                    const Text('لا توجد بطولات نشطة حالياً', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (isOwner) ...[
                      const SizedBox(height: 8),
                      const Text('اضغط على الزر بالأسفل لإنشاء بطولة جديدة 🏆', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: docs.length,
              itemBuilder: (context, index) {
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
            );
          },
        ),
        floatingActionButton: isOwner && pitchName != null
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إنشاء بطولة جديدة 🏆', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CreateTournamentSheet(pitchName: pitchName!),
                  );
                },
              )
            : null,
      ),
    );
  }
}
