import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speak_now_exam_coach/data/lesson_seed.dart';
import 'package:speak_now_exam_coach/data/local_store.dart';
import 'package:speak_now_exam_coach/data/models.dart';
import 'package:speak_now_exam_coach/features/ai_examiner/examiner_service.dart';
import 'package:speak_now_exam_coach/features/progress/progress_calc.dart';

class _Failing implements ExaminerService {
  @override
  Future<ExamQuestion> nextQuestion(ExamState s) => throw Exception('offline');
  @override
  Future<Evaluation> evaluate(EvalRequest r) => throw Exception('offline');
}

ExamState _state(SessionMode m, {int asked = 0}) => ExamState(
      config: SessionConfig(mode: m, lessonIds: const [1], questionCount: 5),
      lessons: seedLessons(),
      asked: const [],
      previous: null,
      lastAnswer: null,
      runningAvg: 0,
      mainAsked: asked,
    );

void main() {
  test('demo examiner returns an English question from the selected lesson', () async {
    final q = await DemoExaminer(Random(1)).nextQuestion(_state(SessionMode.lesson));
    expect(q.text, isNotEmpty);
    expect(q.lessonId, 1);
  });

  test('mock exam opening is spoken by the examiner in English only', () async {
    final q = await DemoExaminer(Random(2)).nextQuestion(_state(SessionMode.mock));
    expect(q.text, startsWith('Good morning'));
  });

  test('fallback examiner uses demo when the backend fails', () async {
    final ex = FallbackExaminer(_Failing(), DemoExaminer(Random(3)));
    final q = await ex.nextQuestion(_state(SessionMode.daily));
    expect(q.text, isNotEmpty);
    final e = await ex.evaluate(const EvalRequest(
        question: 'Where do you live?', answer: 'I live in Tehran.', confidence: 0.8, durationSec: 4));
    expect(e.total, greaterThan(0));
  });

  test('local store round-trips sessions and clearAll removes them', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final ev = const Evaluation(scores: {'grammar': 7, 'pronunciation': null}, total: 7, corrected: 'Hi.');
    final rec = SessionRecord(
      id: 'a',
      mode: SessionMode.mock,
      lessonIds: const [1],
      startedAt: DateTime(2026, 1, 1),
      completedAt: DateTime(2026, 1, 1, 0, 5),
      durationSec: 300,
      answers: [
        AnswerRecord(question: 'Q?', recognizedText: 'Hi', durationSec: 3, confidence: 0.8, evaluation: ev)
      ],
    );
    await store.saveSessions([rec]);
    final back = store.loadSessions();
    expect(back.single.answers.single.evaluation.scores['pronunciation'], isNull);
    expect(computeProgress(back, now: DateTime(2026, 1, 1)).totalMinutes, 5);
    await store.clearAll();
    expect(store.loadSessions(), isEmpty);
  });
}
