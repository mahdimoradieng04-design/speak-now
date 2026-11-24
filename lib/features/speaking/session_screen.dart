import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../shared/widgets/widgets.dart';
import '../ai_examiner/examiner_service.dart';

enum _Phase { intro, asking, waiting, listening, confirm, evaluating }

/// One screen drives all five modes (lesson, daily, mock, weakness, free).
class SessionScreen extends ConsumerStatefulWidget {
  final SessionConfig config;
  const SessionScreen({super.key, required this.config});
  @override
  ConsumerState<SessionScreen> createState() => _SessionState();
}

class _SessionState extends ConsumerState<SessionScreen> {
  _Phase _phase = _Phase.intro;
  ExamQuestion? _current;
  ExamQuestion? _prev;
  String _transcript = '';
  double _confidence = 0;
  String? _error;
  bool _manual = false;
  bool _finishing = false;
  final _manualCtrl = TextEditingController();
  final List<AnswerRecord> _answers = [];
  final List<String> _asked = [];
  String? _lastAnswer;
  double _runningAvg = 0;
  int _mainAsked = 0;
  DateTime _started = DateTime.now();
  int _recSecs = 0;
  Timer? _ticker;
  late final SpeechInput _speech;
  late final TtsService _tts;

  bool get _isMock => widget.config.mode == SessionMode.mock;

  @override
  void initState() {
    super.initState();
    _speech = ref.read(speechInputProvider);
    _tts = ref.read(ttsProvider);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _speech.cancel();
    _tts.stop();
    _manualCtrl.dispose();
    super.dispose();
  }

  String _errFa(String c) {
    if (c == 'mic_denied') {
      return 'دسترسی به میکروفون داده نشد. از تنظیمات گوشی اجازه را فعال کنید یا پاسخ را تایپ کنید.';
    }
    if (c == 'stt_unavailable') {
      return 'تشخیص گفتار روی این دستگاه در دسترس نیست. می‌توانید پاسخ را تایپ کنید.';
    }
    if (c.contains('network')) return 'خطای اینترنت: تشخیص گفتار به شبکه نیاز دارد.';
    if (c.contains('no_match') || c.contains('speech_timeout')) {
      return 'صدایی تشخیص داده نشد. دوباره تلاش کنید.';
    }
    return 'خطای تشخیص گفتار ($c).';
  }

  void _onSpeechError(String code) {
    if (!mounted) return;
    setState(() {
      _error = _errFa(code);
      if (code == 'mic_denied' || code == 'stt_unavailable') _manual = true;
    });
    if (_phase == _Phase.listening) _stopListening();
  }

  Future<void> _begin() async {
    _started = DateTime.now();
    final s = ref.read(settingsProvider);
    await _tts.configure(s.voiceName, s.voiceLocale, s.speechRate);
    final ok = await _speech.init(onError: _onSpeechError);
    if (!ok && mounted) setState(() => _manual = true);
    await _askNext();
  }

  Future<void> _askNext() async {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.asking;
      _transcript = '';
      _confidence = 0;
    });
    final q = await ref.read(examinerProvider).nextQuestion(ExamState(
          config: widget.config,
          lessons: ref.read(lessonsProvider),
          asked: List.of(_asked),
          previous: _prev,
          lastAnswer: _lastAnswer,
          runningAvg: _runningAvg,
          mainAsked: _mainAsked,
        ));
    if (!mounted) return;
    if (!q.isFollowUp && _mainAsked >= widget.config.questionCount) {
      await _finish();
      return;
    }
    if (!q.isFollowUp) _mainAsked++;
    setState(() => _current = q);
    await _speakQuestion();
  }

  Future<void> _speakQuestion() async {
    final q = _current;
    if (q == null) return;
    setState(() => _phase = _Phase.asking);
    try {
      await _tts.speak(q.text);
    } catch (_) {
      if (mounted) setState(() => _error = 'پخش صدای ممتحن ممکن نشد؛ متن سؤال را بخوانید.');
    }
    if (mounted && _phase == _Phase.asking) setState(() => _phase = _Phase.waiting);
  }

  Future<void> _startListening() async {
    await _tts.stop();
    setState(() {
      _phase = _Phase.listening;
      _transcript = '';
      _confidence = 0;
      _recSecs = 0;
      _error = null;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recSecs++);
    });
    try {
      await _speech.start(
        onResult: (t, f, c) {
          if (!mounted) return;
          setState(() {
            _transcript = t;
            if (c > 0) _confidence = c;
          });
        },
        onDone: () {
          if (mounted && _phase == _Phase.listening) _stopListening();
        },
        onError: _onSpeechError,
      );
    } catch (_) {
      _onSpeechError('stt_unavailable');
    }
  }

  Future<void> _stopListening() async {
    _ticker?.cancel();
    if (mounted) setState(() => _phase = _Phase.confirm);
    await _speech.stop();
  }

  Future<void> _submit() async {
    final text = (_manual ? _manualCtrl.text : _transcript).trim();
    if (text.isEmpty) {
      setState(() => _error = 'پاسخی ثبت نشده است. دوباره صحبت کنید.');
      return;
    }
    final q = _current!;
    setState(() {
      _phase = _Phase.evaluating;
      _error = null;
    });
    final dur = _manual ? 0 : _recSecs;
    final conf = _manual ? 0.0 : _confidence;
    final vocab = ref
        .read(lessonsProvider)
        .where((l) => l.id == q.lessonId)
        .expand((l) => l.vocabulary)
        .toList();
    final ev = await ref.read(examinerProvider).evaluate(EvalRequest(
          question: q.text,
          answer: text,
          confidence: conf,
          durationSec: dur,
          lessonVocab: vocab,
        ));
    _answers.add(AnswerRecord(
      question: q.text,
      lessonId: q.lessonId,
      recognizedText: text,
      durationSec: dur,
      confidence: conf,
      evaluation: ev,
    ));
    _asked.add(q.text);
    _prev = q;
    _lastAnswer = text;
    _runningAvg = _answers.map((a) => a.evaluation.total).reduce((a, b) => a + b) / _answers.length;
    _manualCtrl.clear();
    await _askNext();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await _tts.stop();
    if (_answers.isEmpty) {
      if (mounted) context.pop();
      return;
    }
    final now = DateTime.now();
    final rec = SessionRecord(
      id: const Uuid().v4(),
      mode: widget.config.mode,
      lessonIds: widget.config.lessonIds,
      startedAt: _started,
      completedAt: now,
      durationSec: now.difference(_started).inSeconds,
      answers: List.of(_answers),
      planDay: widget.config.planDay,
    );
    await ref.read(sessionsProvider.notifier).add(rec);
    if (mounted) context.pushReplacement('/results', extra: rec);
  }

  Future<void> _confirmExit() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('خروج از جلسه؟'),
        content: Text(_answers.isEmpty
            ? 'هنوز به سؤالی پاسخ نداده‌اید.'
            : 'می‌توانید جلسه را همین‌جا تمام کنید و نتیجه‌ی ${_answers.length} پاسخ را ببینید.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'stay'), child: const Text('ادامه')),
          if (_answers.isNotEmpty)
            TextButton(onPressed: () => Navigator.pop(c, 'finish'), child: const Text('پایان و نتیجه')),
          TextButton(onPressed: () => Navigator.pop(c, 'quit'), child: const Text('خروج بدون ذخیره')),
        ],
      ),
    );
    if (choice == 'finish') {
      await _finish();
    } else if (choice == 'quit' && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(modeLabelFa(widget.config.mode)),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
        ),
        body: SafeArea(
          child: _phase == _Phase.intro ? _intro() : _active(),
        ),
      ),
    );
  }

  Widget _intro() {
    final lessons = ref.read(lessonsProvider);
    final ids = widget.config.lessonIds;
    final sel = lessons.where((l) => ids.contains(l.id)).toList();
    final showVocab = widget.config.mode == SessionMode.lesson && sel.isNotEmpty;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_isMock)
        const SectionCard(
          title: 'قوانین آزمون',
          child: Text('ممتحن فقط انگلیسی صحبت می‌کند. هر بار یک سؤال می‌پرسد، شما با صدا پاسخ می‌دهید. '
              'در طول آزمون راهنمایی یا ترجمه نمایش داده نمی‌شود و بازخورد در پایان می‌آید.'),
        ),
      if (widget.config.focus != null)
        SectionCard(
          title: 'تمرکز این جلسه',
          child: Text('ضعیف‌ترین بخش شما: ${_focusFa(widget.config.focus!)}'),
        ),
      if (showVocab)
        for (final l in sel)
          SectionCard(
            title: 'موضوع: ${l.topicFa}',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('واژگان مهم:'),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final v in l.vocabulary) Chip(label: EnglishText(v)),
              ]),
              const SizedBox(height: 8),
              const Text('عبارت‌های کاربردی:'),
              for (final e in l.expressions) EnglishText('• $e'),
            ]),
          ),
      const SectionCard(
        title: 'میکروفون',
        child: Text('برای تشخیص پاسخ گفتاری شما به میکروفون نیاز است. فقط هنگام ضبط (وقتی دکمه‌ی میکروفون را می‌زنید) '
            'فعال می‌شود و در پس‌زمینه ضبط نمی‌شود. صدای شما ذخیره یا ارسال نمی‌شود؛ فقط متن تشخیص‌داده‌شده نگهداری می‌شود.'),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: _begin,
        icon: const Icon(Icons.play_arrow),
        label: const Text('شروع و اجازه‌ی میکروفون'),
      ),
    ]);
  }

  String _focusFa(String k) {
    const m = {
      'grammar': 'گرامر',
      'vocabulary': 'واژگان',
      'pronunciation': 'تلفظ',
      'fluency': 'روانی',
      'relevance': 'ارتباط با سؤال',
      'completeness': 'کامل بودن پاسخ',
    };
    return m[k] ?? k;
  }

  Widget _active() {
    final q = _current;
    final listening = _phase == _Phase.listening;
    final mm = (_recSecs ~/ 60).toString().padLeft(2, '0');
    final ss = (_recSecs % 60).toString().padLeft(2, '0');

    String status;
    Color statusColor = AppColors.navy;
    switch (_phase) {
      case _Phase.asking:
        status = 'ممتحن در حال پرسیدن است...';
        break;
      case _Phase.waiting:
        status = _manual ? 'پاسخ خود را بنویسید' : 'آماده‌اید؟ میکروفون را بزنید';
        break;
      case _Phase.listening:
        status = 'در حال گوش دادن... $mm:$ss';
        statusColor = AppColors.orange;
        break;
      case _Phase.confirm:
        status = 'پاسخ تشخیص داده‌شده را بررسی کنید';
        break;
      case _Phase.evaluating:
        status = 'در حال ثبت پاسخ...';
        break;
      case _Phase.intro:
        status = '';
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('سؤال ${_mainAsked} از ${widget.config.questionCount}'
          '${q != null && q.isFollowUp ? '  (سؤال پیگیری)' : ''}'),
      const SizedBox(height: 6),
      LinearProgressIndicator(
        value: (_mainAsked / widget.config.questionCount).clamp(0.0, 1.0),
        color: AppColors.green,
        backgroundColor: AppColors.lightBlue,
      ),
      const SizedBox(height: 12),
      Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.person, color: AppColors.navy),
              SizedBox(width: 6),
              Text('Examiner', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            EnglishText(q?.text ?? '...', style: const TextStyle(fontSize: 20, height: 1.35)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Chip(
          avatar: Icon(listening ? Icons.mic : Icons.info_outline, size: 18, color: statusColor),
          label: Text(status, style: TextStyle(color: statusColor)),
          backgroundColor: listening ? const Color(0xFFFFE9D2) : AppColors.lightBlue,
        ),
      ),
      const SizedBox(height: 12),
      if (_error != null)
        Card(
          color: const Color(0xFFFFE9D2),
          child: Padding(padding: const EdgeInsets.all(10), child: Text(_error!)),
        ),
      if (_manual && (_phase == _Phase.waiting || _phase == _Phase.confirm))
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _manualCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              hintText: 'Type your answer in English...',
            ),
          ),
        )
      else if (_phase == _Phase.listening || _phase == _Phase.confirm)
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: EnglishText(
                _transcript.isEmpty ? '(no speech recognized yet)' : _transcript,
                style: TextStyle(fontSize: 17, color: _transcript.isEmpty ? Colors.grey : Colors.black87),
              ),
            ),
          ),
        ),
      const SizedBox(height: 16),
      if (!_manual && (_phase == _Phase.waiting || listening))
        Center(
          child: GestureDetector(
            onTap: listening ? _stopListening : _startListening,
            child: CircleAvatar(
              radius: 44,
              backgroundColor: listening ? AppColors.orange : AppColors.navy,
              child: Icon(listening ? Icons.stop : Icons.mic, color: Colors.white, size: 40),
            ),
          ),
        ),
      const SizedBox(height: 16),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
          onPressed: (_phase == _Phase.waiting || _phase == _Phase.confirm) ? _speakQuestion : null,
          icon: const Icon(Icons.replay),
          label: const Text('تکرار سؤال'),
        ),
        if (_phase == _Phase.confirm && !_manual)
          OutlinedButton.icon(
            onPressed: _startListening,
            icon: const Icon(Icons.mic),
            label: const Text('تکرار پاسخ'),
          ),
        if (_manual && _phase == _Phase.waiting)
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: const Text('ثبت و ادامه'),
          ),
        if (_phase == _Phase.confirm && !_manual)
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('ثبت و سؤال بعدی'),
          ),
      ]),
    ]);
  }
}
