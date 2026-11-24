# Speak Now Exam Coach

Flutter app (Android + iOS) that simulates an English oral exam: an English-only AI/demo examiner asks
questions by voice (TTS), the student answers by voice (STT), and receives scores and Persian feedback.
UI is Persian (RTL); the examiner speaks only English.

## Honest status (read first)

This source was written in an environment **without Flutter/Dart, an Android SDK, Xcode or network access**.
Therefore **nothing has been compiled, run, or tested yet** — not the app, not the unit tests, not on a device.
Expect to fix a few compile errors or package-version mismatches on first `flutter pub get` / `flutter analyze`.
No APK or IPA was produced. Speech recognition/TTS can only be verified on a real device.

Also not done yet: user authentication, backend progress sync, a pronunciation engine
(pronunciation is only an approximation from the STT confidence), sqflite/Isar storage (JSON in
SharedPreferences is used behind `LocalStore`), Persian fonts, custom app icon.

## Lesson content

`lib/data/lesson_seed.dart` holds 17 **generic starter lessons, NOT official Oxford Speak Now 1 content**
(all `verified = false`). Edit each lesson in the app (Lessons > lesson > edit icon) to match your
exact textbook edition, then switch on "content verified".

## Setup

```bash
flutter --version            # Flutter 3.22+ / Dart 3.3+
cd speak_now_exam_coach
flutter create --platforms=android,ios --org com.example --project-name speak_now_exam_coach .
bash tool/configure_platforms.sh     # adds mic/speech permissions to AndroidManifest + Info.plist
flutter pub get
flutter analyze
flutter test
flutter run                  # on a physical device (emulator mics/TTS voices are unreliable)
```

Android release APK: `flutter build apk --release` (set up your own signing key for the Play Store).
iOS: needs macOS + Xcode + an Apple signing team: `flutter build ipa` (or open `ios/Runner.xcworkspace`).
Speech recognition on Android needs Google speech services; recognition usually needs internet.

## Modes

Lesson practice, Daily speaking (tiered difficulty), Mock oral exam (no hints, English only,
occasional unexpected questions, report at the end), Weakness practice (from past scores),
Free conversation, plus the editable 10-day plan (Home > برنامه ۱۰ روزه).
Feedback is shown only at the end of a session, never mid-answer.

## AI backend (optional)

Without a backend the app runs fully offline in **demo mode** (predefined questions + rule-based scoring;
the rule-based grammar check is a small set of patterns and misses most errors).
To use an LLM: run `backend/server.js` (see header comment; key stays in `backend/.env`), deploy it over
HTTPS, then in the app: Settings > Backend URL, access token, and consent switch. Only answer *text* is sent,
never audio. If the backend fails, the app falls back to demo mode automatically.
API contract: `POST /examiner/next` -> `{text, lessonId, isFollowUp}`, `POST /evaluate` -> `Evaluation` JSON
(see `lib/data/models.dart`). Swap providers by changing the backend only, or implement `ExaminerService`.
Voice providers are swappable via `SpeechInput` (`lib/core/services/speech_service.dart`).

## Privacy

Mic is requested only when a session starts, used only while recording, never in background; audio is not
stored or uploaded. Settings > "حذف همه‌ی داده‌ها" erases all local data.

## Layout

`lib/core` (theme, services, providers) · `lib/data` (models, seed, store) · `lib/features/*` (screens/logic) ·
`lib/shared/widgets` · `test/` · `backend/` · `tool/`
