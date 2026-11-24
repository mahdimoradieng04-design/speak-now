import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../shared/widgets/widgets.dart';

class ResultsScreen extends StatelessWidget {
  final SessionRecord record;
  const ResultsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final a in record.answers) {
      a.evaluation.scores.forEach((k, v) {
        if (v != null) {
          sums[k] = (sums[k] ?? 0) + v;
          counts[k] = (counts[k] ?? 0) + 1;
        }
      });
    }
    final avg = record.average;
    final mins = (record.durationSec / 60).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتیجه و بازخورد'),
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => context.go('/home')),
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Card(
          color: AppColors.navy,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              Text(modeLabelFa(record.mode), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('${avg.toStringAsFixed(1)} / 10',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              Text('${record.answers.length} پاسخ  •  حدود $mins دقیقه',
                  style: const TextStyle(color: Colors.white70)),
            ]),
          ),
        ),
        SectionCard(
          title: 'میانگین هر معیار',
          child: Column(children: [
            for (final k in kCategories)
              ScoreBar(label: kCategoryFa[k]!, value: counts[k] == null ? null : sums[k]! / counts[k]!),
            const SizedBox(height: 6),
            const Text(
              'توجه: نمره‌ی تلفظ تقریبی است و فقط از اطمینان موتور تشخیص گفتار گرفته می‌شود؛ '
              'اگر در دسترس نباشد در میانگین لحاظ نمی‌شود. تحلیل گرامر در حالت دمو مبتنی بر قاعده است و همه‌ی خطاها را پیدا نمی‌کند.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text('بازخورد تک‌تک پاسخ‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        for (var i = 0; i < record.answers.length; i++) _answerTile(i, record.answers[i]),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => context.go('/home'), child: const Text('بازگشت به صفحه‌ی اصلی')),
      ]),
    );
  }

  Widget _answerTile(int i, AnswerRecord a) {
    final e = a.evaluation;
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor(e.total),
          child: Text(e.total.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: EnglishText('${i + 1}. ${a.question}', style: const TextStyle(fontSize: 14)),
        childrenPadding: const EdgeInsets.all(12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('پاسخ شما (متن تشخیص‌داده‌شده):', style: TextStyle(fontWeight: FontWeight.bold)),
          EnglishText(a.recognizedText),
          const SizedBox(height: 8),
          const Text('نسخه‌ی اصلاح‌شده:', style: TextStyle(fontWeight: FontWeight.bold)),
          EnglishText(e.corrected, style: const TextStyle(color: AppColors.green)),
          const SizedBox(height: 8),
          for (final k in kCategories) ScoreBar(label: kCategoryFa[k]!, value: e.scores[k]),
          const SizedBox(height: 8),
          const Text('توضیح اشتباهات و پیشنهادها:', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final f in e.feedbackFa) Padding(padding: const EdgeInsets.only(top: 3), child: Text('• $f')),
          if (e.betterExpressions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('عبارت‌های طبیعی‌تر:', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final b in e.betterExpressions) EnglishText('• $b'),
          ],
          if (e.suggestedVocab.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('واژگان پیشنهادی برای استفاده:', style: TextStyle(fontWeight: FontWeight.bold)),
            EnglishText(e.suggestedVocab.join(', ')),
          ],
          if (e.improvedExample.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('نمونه‌ی پاسخ بهتر:', style: TextStyle(fontWeight: FontWeight.bold)),
            EnglishText(e.improvedExample),
          ],
        ],
      ),
    );
  }
}
