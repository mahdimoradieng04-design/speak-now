import '../../core/constants/constants.dart';
import '../../data/models.dart';

class ProgressSummary {
  final int totalMinutes;
  final int todayMinutes;
  final int questions;
  final double average;
  final Map<String, double> byCategory;
  final List<String> weakAreas; // category keys, weakest first
  final Set<int> completedLessons;
  final Map<int, double> lessonAverage;
  final String level;
  const ProgressSummary({
    required this.totalMinutes,
    required this.todayMinutes,
    required this.questions,
    required this.average,
    required this.byCategory,
    required this.weakAreas,
    required this.completedLessons,
    required this.lessonAverage,
    required this.level,
  });
}

String levelFa(double avg, int questions) {
  if (questions == 0) return 'هنوز تعیین نشده';
  if (avg < 3) return 'A1 (مقدماتی)';
  if (avg < 5) return 'A1+ (مقدماتی بالا)';
  if (avg < 7) return 'A2 (ابتدایی)';
  if (avg < 8.5) return 'A2+ / B1 (متوسط)';
  return 'B1 (متوسط)';
}

ProgressSummary computeProgress(List<SessionRecord> sessions, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var totalSec = 0;
  var todaySec = 0;
  final all = <AnswerRecord>[];
  final sums = <String, double>{};
  final counts = <String, int>{};
  final lessonSums = <int, double>{};
  final lessonCounts = <int, int>{};
  final completed = <int>{};

  for (final s in sessions) {
    totalSec += s.durationSec;
    final d = s.completedAt;
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      todaySec += s.durationSec;
    }
    for (final a in s.answers) {
      all.add(a);
      a.evaluation.scores.forEach((k, v) {
        if (v != null) {
          sums[k] = (sums[k] ?? 0) + v;
          counts[k] = (counts[k] ?? 0) + 1;
        }
      });
      final id = a.lessonId;
      if (id != null) {
        lessonSums[id] = (lessonSums[id] ?? 0) + a.evaluation.total;
        lessonCounts[id] = (lessonCounts[id] ?? 0) + 1;
      }
    }
  }

  final byCat = <String, double>{
    for (final k in kCategories)
      if (counts[k] != null) k: sums[k]! / counts[k]!,
  };
  final weak = byCat.keys.toList()..sort((a, b) => byCat[a]!.compareTo(byCat[b]!));
  final lessonAvg = <int, double>{
    for (final e in lessonSums.entries) e.key: e.value / lessonCounts[e.key]!,
  };
  for (final e in lessonAvg.entries) {
    if (e.value >= 6 && (lessonCounts[e.key] ?? 0) >= 3) completed.add(e.key);
  }
  final avg = all.isEmpty ? 0.0 : all.map((a) => a.evaluation.total).reduce((a, b) => a + b) / all.length;

  return ProgressSummary(
    totalMinutes: (totalSec / 60).round(),
    todayMinutes: (todaySec / 60).round(),
    questions: all.length,
    average: avg,
    byCategory: byCat,
    weakAreas: weak.take(2).toList(),
    completedLessons: completed,
    lessonAverage: lessonAvg,
    level: levelFa(avg, all.length),
  );
}
