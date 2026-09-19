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
    Query query = FirebaseFirestore.instance.collection('tournaments');
    if (isOwner && pitchName != null && pitchName!.isNotEmpty) {
      query = query.where('pitchName', isEqualTo: pitchName);
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        size: 60,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isOwner
                          ? 'لم تقم بإنشاء أي بطولة حتى الآن'
                          : 'لا توجد بطولات متاحة حالياً',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOwner
                          ? 'اضغط على زر الإجراء السريع بالأسفل لإطلاق بطولتك'
                          : 'انتظر إعلان الملاعب الرياضية عن البطولات القادمة',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
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
                        tournamentTitle: data['title'] ?? data['name'] ?? 'البطولة',
                        pitchName: data['pitchName'] ?? pitchName ?? '',
                        isOwner: isOwner,
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
