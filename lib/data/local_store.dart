import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'lesson_seed.dart';
import 'models.dart';

/// Local persistence (JSON in SharedPreferences).
/// Swap for sqflite/Isar by re-implementing this class; nothing else touches storage.
class LocalStore {
  final SharedPreferences _p;
  LocalStore(this._p);

  static const _kLessons = 'lessons_v1';
  static const _kSessions = 'sessions_v1';
  static const _kPlan = 'plan_v1';
  static const _kSettings = 'settings_v1';

  List<Lesson>? loadLessons() {
    final s = _p.getString(_kLessons);
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List)
          .map((e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLessons(List<Lesson> l) =>
      _p.setString(_kLessons, jsonEncode(l.map((e) => e.toJson()).toList()));

  List<SessionRecord> loadSessions() {
    final s = _p.getString(_kSessions);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List)
          .map((e) => SessionRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(List<SessionRecord> l) =>
      _p.setString(_kSessions, jsonEncode(l.map((e) => e.toJson()).toList()));

  List<PlanDay> loadPlan() {
    final s = _p.getString(_kPlan);
    if (s == null) return defaultPlan();
    try {
      return (jsonDecode(s) as List)
          .map((e) => PlanDay.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return defaultPlan();
    }
  }

  Future<void> savePlan(List<PlanDay> l) =>
      _p.setString(_kPlan, jsonEncode(l.map((e) => e.toJson()).toList()));

  AppSettings loadSettings() {
    final s = _p.getString(_kSettings);
    if (s == null) return const AppSettings();
    try {
      return AppSettings.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings s) =>
      _p.setString(_kSettings, jsonEncode(s.toJson()));

  /// Deletes ALL local learning data (sessions, edited lessons, plan, settings).
  Future<void> clearAll() async {
    for (final k in [_kLessons, _kSessions, _kPlan, _kSettings]) {
      await _p.remove(k);
    }
  }
}
