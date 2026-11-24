import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);
    final done = ref.watch(progressProvider).completedLessons;
    return Scaffold(
      appBar: AppBar(title: const Text('درس‌ها (۱ تا ۱۷)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: lessons.length,
        itemBuilder: (c, i) {
          final l = lessons[i];
          final isDone = done.contains(l.id);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isDone ? AppColors.green : AppColors.lightBlue,
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white)
                    : Text('${l.id}', style: const TextStyle(color: AppColors.navy)),
              ),
              title: Text(l.title),
              subtitle: Text(l.topicFa + (l.verified ? '' : '  •  محتوا هنوز تأیید نشده')),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/lesson/${l.id}'),
            ),
          );
        },
      ),
    );
  }
}
