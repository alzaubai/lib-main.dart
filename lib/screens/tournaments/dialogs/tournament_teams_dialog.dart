import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'remove_team_dialog.dart';

class TournamentTeamsDialog {
  static void show(
    BuildContext context, {
    required String tournamentId,
    required String tournamentTitle,
    required List<String> teams,
    required Map<String, dynamic> registeredPlayers,
  }) {
    final Map<String, String> teamToPhone = {};
    registeredPlayers.forEach((phone, tName) {
      teamToPhone[tName.toString()] = phone;
    });

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.groups_rounded, color: Color(0xFF1B5E20), size: 22),
              const SizedBox(width: 8),
              Text('الفرق المشاركة (${teams.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: teams.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('لا توجد فرق مسجلة بعد', style: TextStyle(color: Colors.grey))),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tName = teams[index];
                      final captainPhone = teamToPhone[tName] ?? '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F5E9),
                          child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        title: Text(tName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          captainPhone.startsWith('manual_') ? 'تسجيل يدوي' : (captainPhone.isNotEmpty ? captainPhone : 'بدون هاتف مسجل'),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_remove_rounded, color: Colors.red),
                          tooltip: 'استبعاد الفريق',
                          onPressed: () {
                            Navigator.pop(ctx);
                            RemoveTeamDialog.show(
                              context,
                              tournamentId: tournamentId,
                              tournamentName: tournamentTitle,
                              teamName: tName,
                              captainPhone: captainPhone,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
