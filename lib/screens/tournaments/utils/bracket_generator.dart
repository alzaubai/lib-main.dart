class BracketGenerator {
  static List<Map<String, dynamic>> generateFullBracket({
    required List<String> registeredTeams,
    required int maxCapacity,
    required String startDate,
    required String defaultSlot,
  }) {
    final List<String> teams = List.from(registeredTeams)..shuffle();

    // ملء الفراغات بـ "باي (تأهل تلقائي)" في حال لم يكتمل العدد
    while (teams.length < maxCapacity) {
      teams.add('باي (تأهل تلقائي)');
    }

    final List<Map<String, dynamic>> matches = [];

    if (maxCapacity == 4) {
      // نصف النهائي
      matches.add({
        'id': 'semi_1',
        'round': 'نصف النهائي',
        'teamA': teams[0],
        'teamB': teams[1],
        'winner': teams[1].contains('تأهل تلقائي') ? teams[0] : null,
        'nextMatchId': 'final_match',
        'nextMatchSlot': 'teamA',
        'date': startDate,
        'time': defaultSlot,
      });

      matches.add({
        'id': 'semi_2',
        'round': 'نصف النهائي',
        'teamA': teams[2],
        'teamB': teams[3],
        'winner': teams[3].contains('تأهل تلقائي') ? teams[2] : null,
        'nextMatchId': 'final_match',
        'nextMatchSlot': 'teamB',
        'date': startDate,
        'time': defaultSlot,
      });

      // النهائي
      matches.add({
        'id': 'final_match',
        'round': 'المباراة النهائية 🏆',
        'teamA': matches[0]['winner'] ?? 'بانتظار الفائز',
        'teamB': matches[1]['winner'] ?? 'بانتظار الفائز',
        'winner': null,
        'nextMatchId': null,
        'date': '',
        'time': '',
      });
    } else if (maxCapacity == 8) {
      // ربع النهائي (4 مباريات)
      for (int i = 0; i < 4; i++) {
        final tA = teams[i * 2];
        final tB = teams[(i * 2) + 1];
        final isAuto = tB.contains('تأهل تلقائي');

        matches.add({
          'id': 'qf_${i + 1}',
          'round': 'ربع النهائي',
          'teamA': tA,
          'teamB': tB,
          'winner': isAuto ? tA : null,
          'nextMatchId': i < 2 ? 'semi_1' : 'semi_2',
          'nextMatchSlot': (i % 2 == 0) ? 'teamA' : 'teamB',
          'date': startDate,
          'time': defaultSlot,
        });
      }

      // نصف النهائي (مباراتان)
      matches.add({
        'id': 'semi_1',
        'round': 'نصف النهائي',
        'teamA': matches[0]['winner'] ?? 'بانتظار الفائز',
        'teamB': matches[1]['winner'] ?? 'بانتظار الفائز',
        'winner': null,
        'nextMatchId': 'final_match',
        'nextMatchSlot': 'teamA',
        'date': '',
        'time': '',
      });

      matches.add({
        'id': 'semi_2',
        'round': 'نصف النهائي',
        'teamA': matches[2]['winner'] ?? 'بانتظار الفائز',
        'teamB': matches[3]['winner'] ?? 'بانتظار الفائز',
        'winner': null,
        'nextMatchId': 'final_match',
        'nextMatchSlot': 'teamB',
        'date': '',
        'time': '',
      });

      // النهائي
      matches.add({
        'id': 'final_match',
        'round': 'المباراة النهائية 🏆',
        'teamA': 'بانتظار الفائز',
        'teamB': 'بانتظار الفائز',
        'winner': null,
        'nextMatchId': null,
        'date': '',
        'time': '',
      });
    }

    return matches;
  }
}
