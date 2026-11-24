import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../shared/widgets/widgets.dart';

class LessonDetailScreen extends ConsumerWidget {
  final int lessonId;
  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lessonsProvider).firstWhere((x) => x.id == lessonId);
    final tts = ref.read(ttsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.title), actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'ویرایش درس',
          onPressed: () => context.push('/lesson-edit/${l.id}'),
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        if (!l.verified)
          Card(
            color: const Color(0xFFFFE9D2),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('این محتوا نمونه‌ی اولیه است و هنوز با کتاب Speak Now 1 شما تطبیق داده نشده. '
                  'با دکمه‌ی ویرایش، عنوان، واژگان و سؤال‌ها را با کتاب خود جایگزین کنید.'),
            ),
          ),
        SectionCard(title: 'موضوع اصلی گفتار', child: EnglishText('${l.topic}  (${l.topicFa})')),
        SectionCard(
          title: 'اهداف یادگیری',
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final o in l.objectives) Text('• $o')]),
        ),
        SectionCard(
          title: 'واژگان مهم (برای شنیدن تلفظ بزنید)',
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (final v in l.vocabulary)
              ActionChip(label: EnglishText(v), avatar: const Icon(Icons.volume_up, size: 16), onPressed: () => tts.speak(v)),
          ]),
        ),
        SectionCard(
          title: 'عبارت‌های کاربردی',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final e in l.expressions) EnglishText('• $e'),
          ]),
        ),
        SectionCard(
          title: 'سؤال‌های ممتحن',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final q in l.questions) EnglishText('• $q'),
          ]),
        ),
        SectionCard(
          title: 'سؤال‌های پیگیری',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final q in l.followUps) EnglishText('• $q'),
          ]),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => context.push('/session',
              extra: SessionConfig(mode: SessionMode.lesson, lessonIds: [l.id], questionCount: 6)),
          icon: const Icon(Icons.mic),
          label: const Text('شروع تمرین این درس'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.navy),
          onPressed: () => context.push('/session',
              extra: SessionConfig(mode: SessionMode.mock, lessonIds: [l.id], questionCount: 5)),
          icon: const Icon(Icons.school),
          label: const Text('آزمون کوتاه این درس (بدون راهنمایی)'),
        ),
      ]),
    );
  }
}
