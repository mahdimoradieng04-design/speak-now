import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/widgets.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final sessions = ref.watch(sessionsProvider);
    final recent = sessions.length > 15 ? sessions.sublist(sessions.length - 15) : sessions;

    Widget stat(String label, String value) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
              ]),
            ),
          ),
        );

    String improvement() {
      if (sessions.length < 2) return 'برای دیدن روند پیشرفت حداقل دو جلسه تمرین کنید.';
      final d = sessions.last.average - sessions[sessions.length - 2].average;
      if (d.abs() < 0.2) return 'نمره‌ی آخرین جلسه تقریباً ثابت بوده است.';
      return d > 0
          ? 'آخرین جلسه ${d.toStringAsFixed(1)} نمره بهتر از جلسه‌ی قبل بود.'
          : 'آخرین جلسه ${(-d).toStringAsFixed(1)} نمره پایین‌تر از جلسه‌ی قبل بود.';
    }

    const noTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return Scaffold(
      appBar: AppBar(title: const Text('پیشرفت')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        SectionCard(title: 'سطح تقریبی گفتار', child: Text(p.level, style: const TextStyle(fontSize: 18))),
        Row(children: [
          stat('درس‌های تکمیل‌شده', '${p.completedLessons.length}/$kTotalLessons'),
          stat('دقیقه‌ی تمرین', '${p.totalMinutes}'),
          stat('سؤال‌ها', '${p.questions}'),
          stat('میانگین نمره', p.questions == 0 ? '-' : p.average.toStringAsFixed(1)),
        ]),
        SectionCard(title: 'روند نمره‌ی جلسه‌ها', child: SizedBox(
          height: 180,
          child: recent.length < 2
              ? const Center(child: Text('هنوز داده‌ی کافی نیست'))
              : LineChart(LineChartData(
                  minY: 0,
                  maxY: 10,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(topTitles: noTitles, rightTitles: noTitles),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (var i = 0; i < recent.length; i++) FlSpot(i.toDouble(), recent[i].average)],
                      isCurved: true,
                      color: AppColors.navy,
                      barWidth: 3,
                    ),
                  ],
                )),
        )),
        SectionCard(title: 'عملکرد در هر معیار', child: SizedBox(
          height: 200,
          child: p.byCategory.isEmpty
              ? const Center(child: Text('هنوز داده‌ی کافی نیست'))
              : BarChart(BarChartData(
                  maxY: 10,
                  titlesData: FlTitlesData(
                    topTitles: noTitles,
                    rightTitles: noTitles,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, meta) {
                          final k = kCategories[v.toInt().clamp(0, kCategories.length - 1)];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(kCategoryFa[k]!.split(' ').first, style: const TextStyle(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < kCategories.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: p.byCategory[kCategories[i]] ?? 0,
                          width: 16,
                          color: scoreColor(p.byCategory[kCategories[i]] ?? 0),
                        ),
                      ]),
                  ],
                )),
        )),
        SectionCard(
          title: 'نقاط ضعف',
          child: Text(p.weakAreas.isEmpty
              ? 'هنوز مشخص نیست.'
              : p.weakAreas.map((k) => kCategoryFa[k]).join(' و ')),
        ),
        SectionCard(title: 'بهبود اخیر', child: Text(improvement())),
        const Text(
          'پیشرفت روی همین دستگاه ذخیره می‌شود. همگام‌سازی با سرور فقط با ورود به حساب و در نسخه‌ی دارای بک‌اند فعال می‌شود (هنوز پیاده‌سازی نشده).',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ]),
    );
  }
}
