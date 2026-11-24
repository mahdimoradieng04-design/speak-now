import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../shared/widgets/widgets.dart';

class VocabScreen extends ConsumerWidget {
  const VocabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);
    final tts = ref.read(ttsProvider);
    final s = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('مرور واژگان')),
      body: ListView(padding: const EdgeInsets.all(10), children: [
        for (final l in lessons)
          Card(
            child: ExpansionTile(
              title: Text('${l.title} — ${l.topicFa}'),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final v in l.vocabulary)
                    ActionChip(
                      label: EnglishText(v),
                      avatar: const Icon(Icons.volume_up, size: 16),
                      onPressed: () async {
                        await tts.configure(s.voiceName, s.voiceLocale, s.speechRate);
                        await tts.speak(v);
                      },
                    ),
                ]),
              ],
            ),
          ),
      ]),
    );
  }
}
