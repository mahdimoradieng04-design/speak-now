import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(settingsProvider).name;
    final p = ref.watch(progressProvider);

    void start(SessionConfig c) => context.push('/session', extra: c);

    Widget mode(IconData icon, String title, String sub, VoidCallback onTap, {Color? color}) => Card(
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: color ?? AppColors.lightBlue,
                child: Icon(icon, color: AppColors.navy)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(sub),
            onTap: onTap,
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Speak Now Exam Coach'), actions: [
        IconButton(icon: const Icon(Icons.settings), tooltip: 'تنظیمات', onPressed: () => context.push('/settings')),
      ]),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Card(
          color: AppColors.navy,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('سلام ${name.isEmpty ? '' : name} 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('سطح تقریبی: ${p.level}', style: const TextStyle(color: Colors.white70)),
              Text('تمرین امروز: ${p.todayMinutes} دقیقه  •  کل سؤال‌ها: ${p.questions}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                    onPressed: () => context.push('/plan'),
                    child: const Text('برنامه ۱۰ روزه'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                    onPressed: () => context.push('/progress'),
                    child: const Text('پیشرفت'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        mode(Icons.menu_book, 'تمرین درس', 'یکی از درس‌های ۱ تا ۱۷ را انتخاب کنید', () => context.push('/lessons')),
        mode(Icons.wb_sunny, 'گفتار روزانه', 'جلسه‌ی ۱۵ تا ۳۰ دقیقه‌ای، سؤال‌ها به‌تدریج سخت‌تر می‌شوند',
            () => start(const SessionConfig(mode: SessionMode.daily, questionCount: 12))),
        mode(Icons.school, 'آزمون شفاهی شبیه‌سازی‌شده', 'فقط انگلیسی، بدون راهنمایی، با گزارش نهایی',
            () => start(const SessionConfig(mode: SessionMode.mock, questionCount: 10)),
            color: const Color(0xFFFFE9D2)),
        mode(Icons.build_circle, 'تمرین نقاط ضعف', 'بر اساس جلسه‌های قبلی شما', () {
          final lessonAvg = p.lessonAverage;
          final ids = lessonAvg.isEmpty
              ? <int>[1, 2, 3, 4]
              : (lessonAvg.keys.toList()..sort((a, b) => lessonAvg[a]!.compareTo(lessonAvg[b]!))).take(4).toList();
          start(SessionConfig(
            mode: SessionMode.weakness,
            lessonIds: ids,
            questionCount: 8,
            focus: p.weakAreas.isEmpty ? null : p.weakAreas.first,
          ));
        }),
        mode(Icons.forum, 'گفتگوی آزاد', 'گفتگوی طبیعی با ممتحن',
            () => start(const SessionConfig(mode: SessionMode.free, questionCount: 10))),
        mode(Icons.translate, 'مرور واژگان', 'واژگان درس‌ها با تلفظ', () => context.push('/vocab')),
      ]),
    );
  }
}
