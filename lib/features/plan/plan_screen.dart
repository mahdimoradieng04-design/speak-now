import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, PlanDay d) async {
    final lessons = TextEditingController(text: d.lessonIds.join(','));
    final minutes = TextEditingController(text: '${d.minutes}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('ویرایش روز ${d.day}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: lessons,
            decoration: const InputDecoration(labelText: 'شماره درس‌ها (با کاما، مثلاً 1,2)'),
          ),
          TextField(
            controller: minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'دقیقه'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لغو')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('ذخیره')),
        ],
      ),
    );
    if (ok == true) {
      final ids = lessons.text
          .split(RegExp(r'[,\s،]+'))
          .map(int.tryParse)
          .whereType<int>()
          .where((n) => n >= 1 && n <= 17)
          .toList();
      ref.read(planProvider.notifier).update(PlanDay(
            day: d.day,
            lessonIds: ids.isEmpty ? d.lessonIds : ids,
            minutes: int.tryParse(minutes.text) ?? d.minutes,
            mock: d.mock,
            review: d.review,
          ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider);
    final sessions = ref.watch(sessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('برنامه‌ی ۱۰ روزه'), actions: [
        IconButton(
          icon: const Icon(Icons.restart_alt),
          tooltip: 'بازگشت به برنامه‌ی پیش‌فرض',
          onPressed: () => ref.read(planProvider.notifier).reset(),
        ),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: plan.length,
        itemBuilder: (c, i) {
          final d = plan[i];
          final daySessions = sessions.where((s) => s.planDay == d.day).toList();
          final doneMin = (daySessions.fold<int>(0, (a, s) => a + s.durationSec) / 60).round();
          final done = daySessions.isNotEmpty;
          final title = d.mock
              ? 'آزمون شفاهی کامل'
              : d.review
                  ? 'درس ${d.lessonIds.join('، ')} + مرور همه‌ی درس‌ها'
                  : 'درس ${d.lessonIds.join(' و ')}';
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: done ? AppColors.green : AppColors.lightBlue,
                child: done ? const Icon(Icons.check, color: Colors.white) : Text('${d.day}'),
              ),
              title: Text('روز ${d.day}: $title'),
              subtitle: Text('هدف: ${d.minutes} دقیقه  •  انجام‌شده: $doneMin دقیقه'),
              trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(context, ref, d)),
              onTap: () {
                final ids = d.review ? <int>[] : d.lessonIds;
                final count = d.mock ? 12 : (d.minutes ~/ 6).clamp(6, 14);
                context.push('/session',
                    extra: SessionConfig(
                      mode: d.mock ? SessionMode.mock : SessionMode.lesson,
                      lessonIds: d.mock ? const [] : ids,
                      questionCount: count,
                      planDay: d.day,
                    ));
              },
            ),
          );
        },
      ),
    );
  }
}
