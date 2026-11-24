import 'dart:math';
import 'package:dio/dio.dart';
import '../../data/models.dart';
import '../evaluation/evaluator.dart';

class ExamState {
  final SessionConfig config;
  final List<Lesson> lessons;
  final List<String> asked;
  final ExamQuestion? previous;
  final String? lastAnswer;
  final double runningAvg;
  final int mainAsked;
  const ExamState({
    required this.config,
    required this.lessons,
    required this.asked,
    required this.previous,
    required this.lastAnswer,
    required this.runningAvg,
    required this.mainAsked,
  });
}

class EvalRequest {
  final String question;
  final String answer;
  final double confidence;
  final int durationSec;
  final List<String> lessonVocab;
  const EvalRequest({
    required this.question,
    required this.answer,
    required this.confidence,
    required this.durationSec,
    this.lessonVocab = const [],
  });
}

/// Swap this interface to connect any AI provider (via your backend).
abstract class ExaminerService {
  Future<ExamQuestion> nextQuestion(ExamState state);
  Future<Evaluation> evaluate(EvalRequest request);
}

const _daily = <(String, int)>[
  ('What is your name, and where are you from?', 1),
  ('How old are you?', 1),
  ('What time do you get up in the morning?', 1),
  ('Do you have any brothers or sisters?', 1),
  ('What is your favorite food?', 1),
  ('What is the weather like today?', 1),
  ('What do you do in your free time?', 1),
  ('What is your favorite color?', 1),
  ('Can you describe your daily routine?', 2),
  ('Tell me about your best friend.', 2),
  ('What kind of movies do you like, and why?', 2),
  ('Where do you usually go shopping, and what do you buy?', 2),
  ('What do you study, or what is your job?', 2),
  ('What did you do last weekend?', 2),
  ('Which season do you like best?', 2),
  ('What is your favorite place in your city?', 2),
  ('What are you going to do next weekend?', 3),
  ('Would you prefer to live in a big city or a small town? Why?', 3),
  ('How has your life changed in the last few years?', 3),
  ('What is a good way to learn English, in your opinion?', 3),
  ('If you could travel anywhere, where would you go and why?', 3),
  ('Tell me about a meal you enjoyed with your family.', 3),
  ('What do you think is the best job, and why?', 3),
  ('Describe a film you saw recently.', 3),
];

const _unexpected = [
  'If you could have any superpower, what would it be?',
  'What would you do if you won a lot of money?',
  'What is the most interesting thing you learned this week?',
  'Do you prefer mornings or evenings? Why?',
  'What is something you want to learn next year?',
];

const _genericFollowUps = [
  'Why is that important to you?',
  'Can you give me an example?',
  'Is it the same for your friends or family?',
];

const _focusHint = {
  'grammar': 'Please answer in full sentences.',
  'vocabulary': 'Try to use new words from the lesson.',
  'fluency': 'Try to speak for at least twenty seconds.',
  'completeness': 'Please answer with at least three sentences.',
  'relevance': 'Answer exactly what I ask.',
  'pronunciation': 'Speak slowly and clearly.',
};

/// Offline examiner with predefined questions and rule-based feedback.
class DemoExaminer implements ExaminerService {
  final Random _rng;
  DemoExaminer([Random? rng]) : _rng = rng ?? Random();

  @override
  Future<Evaluation> evaluate(EvalRequest r) async =>
      RuleBasedEvaluator.evaluate(
        question: r.question,
        answer: r.answer,
        confidence: r.confidence,
        durationSec: r.durationSec,
        lessonVocab: r.lessonVocab,
      );

  @override
  Future<ExamQuestion> nextQuestion(ExamState s) async {
    final prev = s.previous;
    final mode = s.config.mode;
    final followProb = mode == SessionMode.free ? 0.7 : mode == SessionMode.mock ? 0.5 : 0.4;
    if (prev != null && !prev.isFollowUp && s.lastAnswer != null && _rng.nextDouble() < followProb) {
      return ExamQuestion(
        text: _followUp(s, prev),
        lessonId: prev.lessonId,
        isFollowUp: true,
      );
    }
    return _mainQuestion(s);
  }

  String _followUp(ExamState s, ExamQuestion prev) {
    final lesson = s.lessons.where((l) => l.id == prev.lessonId).toList();
    if (lesson.isNotEmpty) {
      final fresh = lesson.first.followUps.where((f) => !s.asked.contains(f)).toList();
      if (fresh.isNotEmpty && _rng.nextDouble() < 0.6) return fresh[_rng.nextInt(fresh.length)];
    }
    final a = s.lastAnswer!.toLowerCase();
    final n = RegExp(r"[a-z']+").allMatches(a).length;
    if (n < 6) return 'Can you tell me a little more about that?';
    if (a.contains('because')) return 'Can you give me an example?';
    return _genericFollowUps[_rng.nextInt(_genericFollowUps.length)];
  }

  ExamQuestion _mainQuestion(ExamState s) {
    final mode = s.config.mode;
    final first = s.mainAsked == 0;
    final opening = first
        ? (mode == SessionMode.mock
            ? "Good morning. I'm your examiner today. Let's begin. "
            : "Hello! Let's begin. ")
        : '';
    final suffix = (mode == SessionMode.weakness && s.config.focus != null && _focusHint[s.config.focus] != null)
        ? ' ${_focusHint[s.config.focus]}'
        : '';

    if (mode == SessionMode.mock && s.mainAsked >= 2 && _rng.nextDouble() < 0.2) {
      final fresh = _unexpected.where((q) => !s.asked.contains(q)).toList();
      if (fresh.isNotEmpty) {
        return ExamQuestion(text: fresh[_rng.nextInt(fresh.length)]);
      }
    }

    if (mode == SessionMode.daily || mode == SessionMode.free) {
      var tier = min(3, 1 + (s.mainAsked * 3) ~/ max(1, s.config.questionCount));
      if (s.runningAvg >= 8) tier = min(3, tier + 1);
      if (s.runningAvg > 0 && s.runningAvg < 4) tier = max(1, tier - 1);
      var cands = _daily.where((q) => q.$2 == tier && !s.asked.contains(q.$1)).toList();
      if (cands.isEmpty) cands = _daily.where((q) => !s.asked.contains(q.$1)).toList();
      if (cands.isEmpty) cands = _daily.toList();
      final pick = cands[_rng.nextInt(cands.length)];
      return ExamQuestion(text: '$opening${pick.$1}$suffix');
    }

    final ids = s.config.lessonIds;
    final pool = <ExamQuestion>[
      for (final l in s.lessons)
        if (ids.isEmpty || ids.contains(l.id))
          for (final q in l.questions) ExamQuestion(text: q, lessonId: l.id),
    ];
    if (pool.isEmpty) return ExamQuestion(text: '$opening${_daily.first.$1}');
    var fresh = pool.where((q) => !s.asked.contains(q.text)).toList();
    if (fresh.isEmpty) fresh = pool;
    final pick = fresh[_rng.nextInt(fresh.length)];
    return ExamQuestion(text: '$opening${pick.text}$suffix', lessonId: pick.lessonId);
  }
}

/// Talks to YOUR backend (see /backend). Never holds a provider API key.
class RemoteExaminer implements ExaminerService {
  final Dio _dio;
  final Future<String?> Function() _token;
  RemoteExaminer(String baseUrl, this._token)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 25),
        ));

  Future<Options> _opts() async {
    final t = await _token();
    return Options(headers: {if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t'});
  }

  @override
  Future<ExamQuestion> nextQuestion(ExamState s) async {
    final r = await _dio.post('/examiner/next',
        data: {
          'mode': s.config.mode.name,
          'lessonIds': s.config.lessonIds,
          'asked': s.asked,
          'lastQuestion': s.previous?.text,
          'lastAnswer': s.lastAnswer,
          'runningAvg': s.runningAvg,
          'mainAsked': s.mainAsked,
          'focus': s.config.focus,
          'lessons': [
            for (final l in s.lessons)
              if (s.config.lessonIds.isEmpty || s.config.lessonIds.contains(l.id))
                {'id': l.id, 'topic': l.topic, 'vocabulary': l.vocabulary, 'questions': l.questions}
          ],
        },
        options: await _opts());
    final d = Map<String, dynamic>.from(r.data as Map);
    return ExamQuestion(
      text: d['text'] as String,
      lessonId: d['lessonId'] as int?,
      isFollowUp: d['isFollowUp'] == true,
    );
  }

  @override
  Future<Evaluation> evaluate(EvalRequest q) async {
    final r = await _dio.post('/evaluate',
        data: {
          'question': q.question,
          'answer': q.answer,
          'confidence': q.confidence,
          'durationSec': q.durationSec,
          'lessonVocab': q.lessonVocab,
        },
        options: await _opts());
    return Evaluation.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}

/// Uses [primary]; on any failure (offline, 5xx, bad JSON) falls back to [fallback].
class FallbackExaminer implements ExaminerService {
  final ExaminerService primary;
  final ExaminerService fallback;
  FallbackExaminer(this.primary, this.fallback);

  @override
  Future<ExamQuestion> nextQuestion(ExamState s) async {
    try {
      return await primary.nextQuestion(s);
    } catch (_) {
      return fallback.nextQuestion(s);
    }
  }

  @override
  Future<Evaluation> evaluate(EvalRequest r) async {
    try {
      return await primary.evaluate(r);
    } catch (_) {
      return fallback.evaluate(r);
    }
  }
}
