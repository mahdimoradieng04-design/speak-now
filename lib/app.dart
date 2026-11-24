import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'data/models.dart';
import 'features/authentication/welcome_screen.dart';
import 'features/dashboard/home_screen.dart';
import 'features/evaluation/results_screen.dart';
import 'features/lessons/lesson_detail_screen.dart';
import 'features/lessons/lesson_edit_screen.dart';
import 'features/lessons/lessons_screen.dart';
import 'features/plan/plan_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/speaking/session_screen.dart';
import 'features/vocabulary/vocab_screen.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
    GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/lessons', builder: (c, s) => const LessonsScreen()),
    GoRoute(
        path: '/lesson/:id',
        builder: (c, s) => LessonDetailScreen(lessonId: int.parse(s.pathParameters['id']!))),
    GoRoute(
        path: '/lesson-edit/:id',
        builder: (c, s) => LessonEditScreen(lessonId: int.parse(s.pathParameters['id']!))),
    GoRoute(path: '/session', builder: (c, s) => SessionScreen(config: s.extra as SessionConfig)),
    GoRoute(path: '/results', builder: (c, s) => ResultsScreen(record: s.extra as SessionRecord)),
    GoRoute(path: '/progress', builder: (c, s) => const ProgressScreen()),
    GoRoute(path: '/plan', builder: (c, s) => const PlanScreen()),
    GoRoute(path: '/vocab', builder: (c, s) => const VocabScreen()),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
  ],
);

class SpeakNowApp extends StatelessWidget {
  const SpeakNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Speak Now Exam Coach',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
