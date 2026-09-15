import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchEvaluationDialog {
  static void show(
    BuildContext context, {
    required String bookingDocId,
    required String pitchName,
    required String teamName,
    required bool isOwner,
  }) {
    double stars = 5.0;
    String selectedTag = '';
    final noteCtrl = TextEditingController();

    // خيارات التقييم السريع للمالك
    final positiveOwnerTags = [
      'التزام تام بالوقت',
      'أخلاق وروح رياضية عالية',
      'محافظة على مرافق الملعب',
      'فريق منظم وممتاز',
    ];

    final negativeOwnerTags = [
      'تأخير عن موعد البدء',
      'عدم الالتزام بوقت الانتهاء',
      'اعتراضات وسلوك غير رياضي',
      'ترك مخلفات في الملعب',
    ];

    // خيارات التقييم السريع للاعب (في حال كان المقيم كابتن الفريق)
    final positivePlayerTags = [
      'أرضية ممتازة ونظيفة',
      'إضاءة قوية ورائعة',
      'تعامل راقٍ من الإدارة',
      'خدمات ومرافق متكاملة',
    ];

    final negativePlayerTags = [
      'أرضية بحاجة لصيانة',
      'إنارة ضعيفة',
      'تأخر في تسليم الملعب',
      'نقص في الخدمات',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final activeTags = isOwner
                ? (stars >= 4 ? positiveOwnerTags : negativeOwnerTags)
                : (stars >= 4 ? positivePlayerTags : negativePlayerTags);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isOwner ? Icons.sports_score_rounded : Icons.star_rate_rounded,
                      color: const Color(0xFF1B5E20),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isOwner ? 'إكمال الحجز وتقييم الفريق' : 'تقييم تجربة الملعب',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      isOwner
                          ? 'يرجى تقييم انضباط وحضور كابتن فريق ($teamName):'
                          : 'يرجى تقييم جودة وخدمات ملعب ($pitchName):',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 14),

                    // شريط النجوم
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final val = index + 1;
                            return IconButton(
                              splashRadius: 20,
                              icon: Icon(
                                val <= stars ? Icons.star_rounded : Icons.star_border_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 30,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  stars = val.toDouble();
                                  selectedTag = '';
                                });
                              },
                            );
                          }),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      'عبارات تقييم سريعة (اختياري):',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),

                    // شرائح الاختيار السريع
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: activeTags.map((tag) {
                        final isSelected = selectedTag == tag;
                        return ChoiceChip(
                          label: Text(tag),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1B5E20),
                          backgroundColor: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedTag = selected ? tag : '';
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: isOwner
                            ? 'ملاحظات إضافية عن سلوك الفريق (اختياري)...'
                            : 'ملاحظات إضافية عن الملعب...',
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              actions: [
                // زر إكمال الحجز فقط دون فرض التقييم
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await FirebaseFirestore.instance.collection('bookings').doc(bookingDocId).update({
                      'status': 'completed',
                    });
                  },
                  child: Text(
                    isOwner ? 'تأكيد الإكمال فقط' : 'تخطي',
                    style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                // زر الإرسال والتقييم
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await FirebaseFirestore.instance.collection('match_evaluations').add({
                      'bookingId': bookingDocId,
                      'pitchName': pitchName,
                      'teamName': teamName,
                      'evaluatedBy': isOwner ? 'owner' : 'player',
                      'rating': stars,
                      'quickTag': selectedTag,
                      'notes': noteCtrl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    await FirebaseFirestore.instance.collection('bookings').doc(bookingDocId).update({
                      'status': 'completed',
                      isOwner ? 'ownerEvaluated' : 'playerEvaluated': true,
                    });
                  },
                  child: const Text(
                    'إرسال التقييم والإكمال',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
