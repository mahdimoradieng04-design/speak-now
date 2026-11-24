import 'package:flutter_test/flutter_test.dart';
import 'package:speak_now_exam_coach/data/lesson_seed.dart';
import 'package:speak_now_exam_coach/features/evaluation/evaluator.dart';

void main() {
  group('RuleBasedEvaluator', () {
    test('corrects third-person verb errors', () {
      final e = RuleBasedEvaluator.evaluate(
        question: 'What does your father do?',
        answer: 'my father work in a bank and he like his job',
        confidence: 0.9,
        durationSec: 10,
      );
      expect(e.corrected.toLowerCase(), contains('he likes'));
      expect(e.scores['grammar']!, lessThan(9));
      expect(e.total, lessThanOrEqualTo(9));
    });

    test('very short answers never score high', () {
      final e = RuleBasedEvaluator.evaluate(
        question: 'Tell me about your family.',
        answer: 'Good',
        confidence: 0.9,
        durationSec: 2,
      );
      expect(e.total, lessThanOrEqualTo(3));
    });

    test('pronunciation is unavailable (null) when confidence is missing', () {
      final e = RuleBasedEvaluator.evaluate(
        question: 'Where do you live?',
        answer: 'I live in Tehran with my family and I like my neighborhood.',
        confidence: 0,
        durationSec: 8,
      );
      expect(e.scores['pronunciation'], isNull);
      expect(e.pronunciationApprox, isTrue);
    });

    test('low recognition confidence is flagged', () {
      final e = RuleBasedEvaluator.evaluate(
        question: 'Where do you live?',
        answer: 'I live in Tehran.',
        confidence: 0.3,
        durationSec: 5,
      );
      expect(e.recognitionUncertain, isTrue);
    });
  });

  group('seed data', () {
    test('has 17 unverified lessons', () {
      final l = seedLessons();
      expect(l.length, 17);
      expect(l.every((x) => !x.verified && x.questions.isNotEmpty), isTrue);
    });

    test('default plan covers lessons 1-17 across 10 days', () {
      final plan = defaultPlan();
      expect(plan.length, 10);
      final covered = plan.expand((d) => d.lessonIds).toSet();
      expect(covered.containsAll(List.generate(17, (i) => i + 1)), isTrue);
      expect(plan.last.mock, isTrue);
    });
  });
}
