import 'dart:math';
import '../../data/models.dart';

class _Fix {
  final RegExp re;
  final String Function(Match) fix;
  final String noteFa;
  _Fix(this.re, this.fix, this.noteFa);
}

String _third(String v) {
  switch (v) {
    case 'go':
      return 'goes';
    case 'do':
      return 'does';
    case 'have':
      return 'has';
    case 'study':
      return 'studies';
    case 'watch':
      return 'watches';
    default:
      return '${v}s';
  }
}

final List<_Fix> _fixes = [
  _Fix(
    RegExp(r'\b(he|she|it)\s+(go|do|have|like|want|live|play|work|eat|watch|study|need|love|read|drink)\b',
        caseSensitive: false),
    (m) => '${m[1]} ${_third(m[2]!.toLowerCase())}',
    'بعد از he/she/it فعل زمان حال ساده «s» می‌گیرد.',
  ),
  _Fix(RegExp(r"\b(?:I am|I'm) agree\b", caseSensitive: false), (m) => 'I agree',
      'درست: «I agree» (بدون am).'),
  _Fix(RegExp(r'\bI has\b', caseSensitive: false), (m) => 'I have',
      'با I از «have» استفاده می‌شود.'),
  _Fix(RegExp(r"\b(he|she|it) don't\b", caseSensitive: false),
      (m) => "${m[1]} doesn't", 'برای he/she/it از «doesn\'t» استفاده کنید.'),
  _Fix(RegExp(r'\bmore better\b', caseSensitive: false), (m) => 'better',
      '«better» خودش صفت تفضیلی است؛ «more» لازم نیست.'),
  _Fix(RegExp(r'\bpeoples\b', caseSensitive: false), (m) => 'people',
      '«people» جمع است و «s» نمی‌گیرد.'),
  _Fix(RegExp(r'\b(we|they|you) was\b', caseSensitive: false),
      (m) => '${m[1]} were', 'با we/they/you از «were» استفاده کنید.'),
  _Fix(RegExp(r'\b(he|she|it) are\b', caseSensitive: false),
      (m) => '${m[1]} is', 'با he/she/it از «is» استفاده کنید.'),
  _Fix(RegExp(r'\bvery much (people|friends|books)\b', caseSensitive: false),
      (m) => 'many ${m[1]}', 'برای اسم‌های شمارش‌پذیر از «many» استفاده کنید.'),
];

const _stop = {
  'the','a','an','do','does','did','you','your','what','how','where','when','who','why',
  'is','are','was','were','to','of','in','on','at','and','or','me','about','tell','can',
  'have','has','any','it','for','with','like','would','will','i','my','that','this','there'
};

const _fillers = {'um', 'uh', 'er', 'erm', 'hmm'};

const _betterMap = <String, String>{
  'very good': 'excellent / really good',
  'i like': "I really enjoy ... / I'm into ...",
  'i think': 'In my opinion, ...',
  'very big': 'huge / enormous',
  'very happy': 'delighted / thrilled',
  'i want': "I'd like to ...",
};

List<String> _words(String t) => RegExp(r"[A-Za-z']+")
    .allMatches(t.toLowerCase())
    .map((m) => m[0]!)
    .toList();

String _stem(String w) => w.endsWith('s') && w.length > 3 ? w.substring(0, w.length - 1) : w;

/// Rule-based demo evaluator. It is deliberately conservative and is NOT a
/// substitute for a real language model or a pronunciation-assessment engine.
class RuleBasedEvaluator {
  static Evaluation evaluate({
    required String question,
    required String answer,
    required double confidence,
    required int durationSec,
    List<String> lessonVocab = const [],
  }) {
    final words = _words(answer);
    final n = words.length;

    // --- Grammar (pattern based) ---
    var corrected = answer.trim();
    final notes = <String>[];
    var issues = 0;
    for (final f in _fixes) {
      final matches = f.re.allMatches(corrected).toList();
      if (matches.isEmpty) continue;
      issues += matches.length;
      final first = matches.first;
      final before = first[0]!;
      final after = f.fix(first);
      notes.add('«$before» ← «$after»: ${f.noteFa}');
      corrected = corrected.replaceAllMapped(f.re, f.fix);
    }
    if (corrected.isNotEmpty) {
      corrected = corrected[0].toUpperCase() + corrected.substring(1);
      if (!RegExp(r'[.!?]$').hasMatch(corrected)) corrected += '.';
    }
    var grammar = (9.5 - 1.8 * issues).clamp(1.0, 10.0).toDouble();
    if (n < 3) grammar = min(grammar, 6.0);

    // --- Completeness ---
    double completeness;
    if (n < 3) {
      completeness = 2;
    } else if (n < 8) {
      completeness = 4;
    } else if (n < 15) {
      completeness = 6.5;
    } else if (n < 30) {
      completeness = 8.5;
    } else {
      completeness = 9.5;
    }

    // --- Relevance (keyword overlap with the question) ---
    final qWords = _words(question)
        .where((w) => w.length > 2 && !_stop.contains(w))
        .map(_stem)
        .toSet();
    final aStems = words.map(_stem).toSet();
    final overlap = qWords.intersection(aStems).length;
    final need = max(1, min(2, qWords.length));
    var relevance = 4 + 6 * min(1.0, overlap / need);
    if (n < 3) relevance = min(relevance, 4.0);

    // --- Vocabulary ---
    final unique = words.toSet().length;
    final longWords = words.where((w) => w.length >= 7).length;
    final vocabStems = lessonVocab.expand(_words).map(_stem).toSet();
    final vocabHits = aStems.intersection(vocabStems).length;
    var vocabulary = 2 + min(4.0, unique / 3.0) + min(2.0, longWords * 0.5) + min(2.0, vocabHits * 1.0);
    vocabulary = vocabulary.clamp(0.0, 10.0).toDouble();
    if (unique < 3) vocabulary = min(vocabulary, 3.0);

    // --- Fluency ---
    final fillers = words.where(_fillers.contains).length;
    double fluency;
    if (n < 3) {
      fluency = 2;
    } else {
      final base = min(9.0, 3 + n / 3);
      if (durationSec > 3) {
        final wpm = n / (durationSec / 60);
        final speed = wpm < 30 ? 3.0 : wpm < 60 ? 5.0 : wpm < 90 ? 7.0 : wpm <= 170 ? 9.0 : 7.0;
        fluency = (base + speed) / 2;
      } else {
        fluency = base;
      }
      fluency = (fluency - fillers * 0.7).clamp(0.0, 10.0).toDouble();
    }

    // --- Pronunciation (only an approximation from STT confidence) ---
    final double? pronunciation = confidence > 0 ? (confidence * 10).clamp(0.0, 10.0).toDouble() : null;
    final recognitionUncertain = confidence > 0 && confidence < 0.5;

    final scores = <String, double?>{
      'grammar': _r(grammar),
      'vocabulary': _r(vocabulary),
      'pronunciation': pronunciation == null ? null : _r(pronunciation),
      'fluency': _r(fluency),
      'relevance': _r(relevance),
      'completeness': _r(completeness),
    };
    final avail = scores.values.whereType<double>().toList();
    var total = avail.reduce((a, b) => a + b) / avail.length;
    if (issues >= 3) total = min(total, 7.0);
    if (issues >= 1) total = min(total, 9.0);
    if (n < 3) total = min(total, 3.0);

    // --- Feedback ---
    final fb = <String>[...notes];
    if (n < 8) fb.add('پاسخ کوتاه بود. سعی کنید دلیل یا مثال اضافه کنید (حداقل دو یا سه جمله).');
    if (relevance < 6) fb.add('پاسخ با سؤال ارتباط کمی داشت؛ مستقیم به همان چیزی که پرسیده شد جواب دهید.');
    if (fillers > 1) fb.add('از مکث‌های «um/uh» کمتر استفاده کنید؛ می‌توانید با عبارت‌هایی مثل «Let me think...» وقت بگیرید.');
    if (recognitionUncertain) {
      fb.add('سیستم تشخیص گفتار به متن اطمینان کمی داشت؛ بعضی خطاها ممکن است خطای تشخیص باشند، نه اشتباه واقعی شما.');
    }
    if (pronunciation == null) {
      fb.add('نمره‌ی تلفظ در دسترس نیست (موتور تشخیص گفتار اطمینان‌سنجی ارائه نکرد) و در میانگین لحاظ نشد.');
    } else {
      fb.add('نمره‌ی تلفظ فقط تقریبی است و از میزان اطمینان تشخیص گفتار به‌دست آمده؛ جایگزین نظر معلم نیست.');
    }
    if (fb.isEmpty) fb.add('پاسخ خوب بود. برای نمره‌ی بالاتر، جزئیات و مثال بیشتری اضافه کنید.');

    final lower = answer.toLowerCase();
    final better = <String>[
      for (final e in _betterMap.entries)
        if (lower.contains(e.key)) '«${e.key}» ← ${e.value}',
    ];
    final suggested = lessonVocab.where((v) => !lower.contains(v.toLowerCase())).take(3).toList();

    var improved = corrected;
    if (n < 12 && corrected.isNotEmpty) {
      improved = '$corrected I think this is important because it is part of my daily life.';
    }

    return Evaluation(
      scores: scores,
      total: _r(total),
      corrected: corrected,
      feedbackFa: fb,
      betterExpressions: better,
      suggestedVocab: suggested,
      improvedExample: improved,
      pronunciationApprox: true,
      recognitionUncertain: recognitionUncertain,
    );
  }

  static double _r(num v) => (v * 10).round() / 10;
}
