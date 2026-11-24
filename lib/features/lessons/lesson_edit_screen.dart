import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class LessonEditScreen extends ConsumerStatefulWidget {
  final int lessonId;
  const LessonEditScreen({super.key, required this.lessonId});
  @override
  ConsumerState<LessonEditScreen> createState() => _LessonEditState();
}

class _LessonEditState extends ConsumerState<LessonEditScreen> {
  late final TextEditingController _title, _topic, _topicFa, _obj, _vocab, _expr, _qs, _fu;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    final l = ref.read(lessonsProvider).firstWhere((x) => x.id == widget.lessonId);
    _title = TextEditingController(text: l.title);
    _topic = TextEditingController(text: l.topic);
    _topicFa = TextEditingController(text: l.topicFa);
    _obj = TextEditingController(text: l.objectives.join('\n'));
    _vocab = TextEditingController(text: l.vocabulary.join('\n'));
    _expr = TextEditingController(text: l.expressions.join('\n'));
    _qs = TextEditingController(text: l.questions.join('\n'));
    _fu = TextEditingController(text: l.followUps.join('\n'));
    _verified = l.verified;
  }

  @override
  void dispose() {
    for (final c in [_title, _topic, _topicFa, _obj, _vocab, _expr, _qs, _fu]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lines(TextEditingController c) =>
      c.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  void _save() {
    final old = ref.read(lessonsProvider).firstWhere((x) => x.id == widget.lessonId);
    ref.read(lessonsProvider.notifier).update(old.copyWith(
          title: _title.text.trim().isEmpty ? old.title : _title.text.trim(),
          topic: _topic.text.trim(),
          topicFa: _topicFa.text.trim(),
          objectives: _lines(_obj),
          vocabulary: _lines(_vocab),
          expressions: _lines(_expr),
          questions: _lines(_qs),
          followUps: _lines(_fu),
          verified: _verified,
        ));
    context.pop();
  }

  Widget _field(String label, TextEditingController c, {int lines = 1, bool ltr = true}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Directionality(
          textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
          child: TextField(
            controller: c,
            minLines: lines,
            maxLines: lines == 1 ? 1 : lines + 4,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('ویرایش درس ${widget.lessonId}'), actions: [
          IconButton(icon: const Icon(Icons.check), tooltip: 'ذخیره', onPressed: _save),
        ]),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          _field('Title', _title),
          _field('Topic (English)', _topic),
          _field('عنوان موضوع (فارسی)', _topicFa, ltr: false),
          _field('اهداف (هر خط یک مورد)', _obj, lines: 3, ltr: false),
          _field('Vocabulary (one per line)', _vocab, lines: 4),
          _field('Expressions (one per line)', _expr, lines: 3),
          _field('Examiner questions (one per line)', _qs, lines: 4),
          _field('Follow-up questions (one per line)', _fu, lines: 3),
          SwitchListTile(
            title: const Text('محتوا با کتاب تطبیق داده شده است'),
            value: _verified,
            onChanged: (v) => setState(() => _verified = v),
          ),
          FilledButton(onPressed: _save, child: const Text('ذخیره')),
        ]),
      );
}
