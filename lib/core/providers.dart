import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/lesson_seed.dart';
import '../data/local_store.dart';
import '../data/models.dart';
import '../features/ai_examiner/examiner_service.dart';
import '../features/progress/progress_calc.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';

final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('override in main'));
final storeProvider = Provider<LocalStore>((ref) => LocalStore(ref.watch(prefsProvider)));
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

class SettingsNotifier extends StateNotifier<AppSettings> {
  final LocalStore _store;
  SettingsNotifier(this._store) : super(_store.loadSettings());
  void update(AppSettings s) {
    state = s;
    _store.saveSettings(s);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier(ref.watch(storeProvider)));

class LessonsNotifier extends StateNotifier<List<Lesson>> {
  final LocalStore _store;
  LessonsNotifier(this._store) : super(_store.loadLessons() ?? seedLessons());
  void update(Lesson l) {
    state = [for (final x in state) x.id == l.id ? l : x];
    _store.saveLessons(state);
  }

  void resetToSeed() {
    state = seedLessons();
    _store.saveLessons(state);
  }
}

final lessonsProvider =
    StateNotifierProvider<LessonsNotifier, List<Lesson>>((ref) => LessonsNotifier(ref.watch(storeProvider)));

class SessionsNotifier extends StateNotifier<List<SessionRecord>> {
  final LocalStore _store;
  SessionsNotifier(this._store) : super(_store.loadSessions());
  Future<void> add(SessionRecord r) async {
    state = [...state, r];
    await _store.saveSessions(state);
  }

  void clear() {
    state = [];
  }
}

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, List<SessionRecord>>((ref) => SessionsNotifier(ref.watch(storeProvider)));

class PlanNotifier extends StateNotifier<List<PlanDay>> {
  final LocalStore _store;
  PlanNotifier(this._store) : super(_store.loadPlan());
  void update(PlanDay d) {
    state = [for (final x in state) x.day == d.day ? d : x];
    _store.savePlan(state);
  }

  void reset() {
    state = defaultPlan();
    _store.savePlan(state);
  }
}

final planProvider =
    StateNotifierProvider<PlanNotifier, List<PlanDay>>((ref) => PlanNotifier(ref.watch(storeProvider)));

final progressProvider =
    Provider<ProgressSummary>((ref) => computeProgress(ref.watch(sessionsProvider)));

final examinerProvider = Provider<ExaminerService>((ref) {
  final s = ref.watch(settingsProvider);
  final demo = DemoExaminer();
  if (!s.useBackend) return demo;
  final storage = ref.read(secureStorageProvider);
  return FallbackExaminer(
    RemoteExaminer(s.backendUrl.trim(), () => storage.read(key: 'api_token')),
    demo,
  );
});

final speechInputProvider = Provider<SpeechInput>((ref) => PlatformSpeechInput());
final ttsProvider = Provider<TtsService>((ref) => TtsService());
