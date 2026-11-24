enum SessionMode { lesson, daily, mock, weakness, free }

String modeLabelFa(SessionMode m) {
  switch (m) {
    case SessionMode.lesson:
      return 'تمرین درس';
    case SessionMode.daily:
      return 'گفتار روزانه';
    case SessionMode.mock:
      return 'آزمون شفاهی شبیه‌سازی‌شده';
    case SessionMode.weakness:
      return 'تمرین نقاط ضعف';
    case SessionMode.free:
      return 'گفتگوی آزاد';
  }
}

List<String> _strList(dynamic v) =>
    v == null ? <String>[] : List<String>.from(v as List);

class UserProfile {
  final String id;
  final String name;
  final String preferredLanguage;
  final DateTime createdAt;
  const UserProfile({
    required this.id,
    required this.name,
    this.preferredLanguage = 'fa',
    required this.createdAt,
  });
}

/// Editable lesson. `verified` is false until you check the content against
/// your exact textbook edition.
class Lesson {
  final int id;
  final String title;
  final String topic;
  final String topicFa;
  final List<String> objectives;
  final List<String> vocabulary;
  final List<String> expressions;
  final List<String> questions;
  final List<String> followUps;
  final bool verified;

  const Lesson({
    required this.id,
    required this.title,
    required this.topic,
    required this.topicFa,
    this.objectives = const [],
    this.vocabulary = const [],
    this.expressions = const [],
    this.questions = const [],
    this.followUps = const [],
    this.verified = false,
  });

  Lesson copyWith({
    String? title,
    String? topic,
    String? topicFa,
    List<String>? objectives,
    List<String>? vocabulary,
    List<String>? expressions,
    List<String>? questions,
    List<String>? followUps,
    bool? verified,
  }) =>
      Lesson(
        id: id,
        title: title ?? this.title,
        topic: topic ?? this.topic,
        topicFa: topicFa ?? this.topicFa,
        objectives: objectives ?? this.objectives,
        vocabulary: vocabulary ?? this.vocabulary,
        expressions: expressions ?? this.expressions,
        questions: questions ?? this.questions,
        followUps: followUps ?? this.followUps,
        verified: verified ?? this.verified,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'topicFa': topicFa,
        'objectives': objectives,
        'vocabulary': vocabulary,
        'expressions': expressions,
        'questions': questions,
        'followUps': followUps,
        'verified': verified,
      };

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as int,
        title: j['title'] as String,
        topic: j['topic'] as String,
        topicFa: (j['topicFa'] ?? '') as String,
        objectives: _strList(j['objectives']),
        vocabulary: _strList(j['vocabulary']),
        expressions: _strList(j['expressions']),
        questions: _strList(j['questions']),
        followUps: _strList(j['followUps']),
        verified: j['verified'] == true,
      );
}

class Evaluation {
  /// Category -> 0..10, or null when it could not be measured.
  final Map<String, double?> scores;
  final double total;
  final String corrected;
  final List<String> feedbackFa;
  final List<String> betterExpressions;
  final List<String> suggestedVocab;
  final String improvedExample;
  final bool pronunciationApprox;
  final bool recognitionUncertain;

  const Evaluation({
    required this.scores,
    required this.total,
    required this.corrected,
    this.feedbackFa = const [],
    this.betterExpressions = const [],
    this.suggestedVocab = const [],
    this.improvedExample = '',
    this.pronunciationApprox = true,
    this.recognitionUncertain = false,
  });

  Map<String, dynamic> toJson() => {
        'scores': scores,
        'total': total,
        'corrected': corrected,
        'feedbackFa': feedbackFa,
        'betterExpressions': betterExpressions,
        'suggestedVocab': suggestedVocab,
        'improvedExample': improvedExample,
        'pronunciationApprox': pronunciationApprox,
        'recognitionUncertain': recognitionUncertain,
      };

  factory Evaluation.fromJson(Map<String, dynamic> j) => Evaluation(
        scores: (j['scores'] as Map).map(
            (k, v) => MapEntry(k as String, (v as num?)?.toDouble())),
        total: (j['total'] as num).toDouble(),
        corrected: (j['corrected'] ?? '') as String,
        feedbackFa: _strList(j['feedbackFa']),
        betterExpressions: _strList(j['betterExpressions']),
        suggestedVocab: _strList(j['suggestedVocab']),
        improvedExample: (j['improvedExample'] ?? '') as String,
        pronunciationApprox: j['pronunciationApprox'] != false,
        recognitionUncertain: j['recognitionUncertain'] == true,
      );
}

class AnswerRecord {
  final String question;
  final int? lessonId;
  final String recognizedText;
  final int durationSec;
  final double confidence;
  final Evaluation evaluation;

  const AnswerRecord({
    required this.question,
    this.lessonId,
    required this.recognizedText,
    required this.durationSec,
    required this.confidence,
    required this.evaluation,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'lessonId': lessonId,
        'recognizedText': recognizedText,
        'durationSec': durationSec,
        'confidence': confidence,
        'evaluation': evaluation.toJson(),
      };

  factory AnswerRecord.fromJson(Map<String, dynamic> j) => AnswerRecord(
        question: j['question'] as String,
        lessonId: j['lessonId'] as int?,
        recognizedText: j['recognizedText'] as String,
        durationSec: j['durationSec'] as int,
        confidence: (j['confidence'] as num).toDouble(),
        evaluation:
            Evaluation.fromJson(Map<String, dynamic>.from(j['evaluation'] as Map)),
      );
}

class SessionRecord {
  final String id;
  final SessionMode mode;
  final List<int> lessonIds;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSec;
  final List<AnswerRecord> answers;
  final int? planDay;

  const SessionRecord({
    required this.id,
    required this.mode,
    required this.lessonIds,
    required this.startedAt,
    required this.completedAt,
    required this.durationSec,
    required this.answers,
    this.planDay,
  });

  double get average => answers.isEmpty
      ? 0
      : answers.map((a) => a.evaluation.total).reduce((a, b) => a + b) /
          answers.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.name,
        'lessonIds': lessonIds,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'durationSec': durationSec,
        'answers': answers.map((a) => a.toJson()).toList(),
        'planDay': planDay,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        id: j['id'] as String,
        mode: SessionMode.values.byName(j['mode'] as String),
        lessonIds: List<int>.from(j['lessonIds'] as List),
        startedAt: DateTime.parse(j['startedAt'] as String),
        completedAt: DateTime.parse(j['completedAt'] as String),
        durationSec: j['durationSec'] as int,
        answers: (j['answers'] as List)
            .map((e) => AnswerRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        planDay: j['planDay'] as int?,
      );
}

class SessionConfig {
  final SessionMode mode;
  final List<int> lessonIds; // empty = all lessons
  final int questionCount;
  final String? focus; // weakness category key
  final int? planDay;
  const SessionConfig({
    required this.mode,
    this.lessonIds = const [],
    this.questionCount = 8,
    this.focus,
    this.planDay,
  });
}

class ExamQuestion {
  final String text;
  final int? lessonId;
  final bool isFollowUp;
  const ExamQuestion({required this.text, this.lessonId, this.isFollowUp = false});
}

class PlanDay {
  final int day;
  final List<int> lessonIds;
  final int minutes;
  final bool mock;
  final bool review;
  const PlanDay({
    required this.day,
    required this.lessonIds,
    this.minutes = 50,
    this.mock = false,
    this.review = false,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'lessonIds': lessonIds,
        'minutes': minutes,
        'mock': mock,
        'review': review,
      };

  factory PlanDay.fromJson(Map<String, dynamic> j) => PlanDay(
        day: j['day'] as int,
        lessonIds: List<int>.from(j['lessonIds'] as List),
        minutes: j['minutes'] as int,
        mock: j['mock'] == true,
        review: j['review'] == true,
      );
}

class AppSettings {
  final String name;
  final String backendUrl; // empty = local demo mode
  final bool backendConsent; // send answer TEXT (never audio) to backend
  final String? voiceName;
  final String? voiceLocale;
  final double speechRate;

  const AppSettings({
    this.name = '',
    this.backendUrl = '',
    this.backendConsent = false,
    this.voiceName,
    this.voiceLocale,
    this.speechRate = 0.45,
  });

  bool get useBackend => backendUrl.trim().isNotEmpty && backendConsent;

  AppSettings copyWith({
    String? name,
    String? backendUrl,
    bool? backendConsent,
    String? voiceName,
    String? voiceLocale,
    double? speechRate,
  }) =>
      AppSettings(
        name: name ?? this.name,
        backendUrl: backendUrl ?? this.backendUrl,
        backendConsent: backendConsent ?? this.backendConsent,
        voiceName: voiceName ?? this.voiceName,
        voiceLocale: voiceLocale ?? this.voiceLocale,
        speechRate: speechRate ?? this.speechRate,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'backendUrl': backendUrl,
        'backendConsent': backendConsent,
        'voiceName': voiceName,
        'voiceLocale': voiceLocale,
        'speechRate': speechRate,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        name: (j['name'] ?? '') as String,
        backendUrl: (j['backendUrl'] ?? '') as String,
        backendConsent: j['backendConsent'] == true,
        voiceName: j['voiceName'] as String?,
        voiceLocale: j['voiceLocale'] as String?,
        speechRate: ((j['speechRate'] ?? 0.45) as num).toDouble(),
      );
}
