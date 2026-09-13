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

    Widget content = StreamBuilder<QuerySnapshot>(
      stream: isOwner && pitchName != null
          ? firestore
              .collection('tournaments')
              .where('pitchName', isEqualTo: pitchName)
              .snapshots()
          : firestore.collection('tournaments').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            ),
          );
        }

        final rawDocs = snapshot.data?.docs ?? [];
        
        // تصفية البطولات السليمة فقط
        final docs = rawDocs.where((d) {
          final data = d.data() as Map<String, dynamic>?;
          if (data == null) return false;
          final title = (data['title'] ?? '').toString().trim();
          final pName = (data['pitchName'] ?? '').toString().trim();
          return title.isNotEmpty && pName.isNotEmpty;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد بطولات معلنة حالياً',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOwner
                        ? 'اضغط على الزر بالأسفل لإطلاق بطولة جديدة بملعبك 🏆'
                        : 'ترقّب إطلاق البطولات والمسابقات الكروية قريباً ⚽',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        // استخدام CustomScrollView لمنع أي انهيار بالتمرير أو مساحات ميتة
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 8),
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
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: Center(
                  child: Text(
                    '🏁 نهاية قائمة البطولات',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        color: const Color(0xFFF4F6F8),
        child: isOwner && pitchName != null
            ? Scaffold(
                backgroundColor: Colors.transparent,
                body: content,
                floatingActionButton: FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'إنشاء بطولة جديدة 🏆',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CreateTournamentSheet(pitchName: pitchName!),
                    );
                  },
                ),
              )
            : content,
      ),
    );
  }
}
