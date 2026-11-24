import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Provider-agnostic speech-to-text interface. Replace the implementation
/// (e.g. with a cloud STT) by overriding speechInputProvider.
abstract class SpeechInput {
  /// Returns false when unavailable. Error codes passed to [onError]:
  /// 'mic_denied', 'stt_unavailable', or the platform's own error message.
  Future<bool> init({void Function(String code)? onError});
  Future<void> start({
    required void Function(String text, bool isFinal, double confidence) onResult,
    required void Function() onDone,
    void Function(String code)? onError,
  });
  Future<void> stop();
  Future<void> cancel();
  bool get isListening;
}

class PlatformSpeechInput implements SpeechInput {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _ready = false;
  void Function()? _onDone;
  void Function(String)? _onError;

  @override
  bool get isListening => _stt.isListening;

  @override
  Future<bool> init({void Function(String code)? onError}) async {
    _onError = onError;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      onError?.call('mic_denied');
      return false;
    }
    try {
      _ready = await _stt.initialize(
        onError: (e) => _onError?.call(e.errorMsg),
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') _onDone?.call();
        },
      );
    } catch (_) {
      _ready = false;
    }
    if (!_ready) onError?.call('stt_unavailable');
    return _ready;
  }

  @override
  Future<void> start({
    required void Function(String text, bool isFinal, double confidence) onResult,
    required void Function() onDone,
    void Function(String code)? onError,
  }) async {
    _onDone = onDone;
    if (onError != null) _onError = onError;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult, r.confidence),
      localeId: 'en_US',
      listenFor: const Duration(seconds: 90),
      pauseFor: const Duration(seconds: 6),
    );
  }

  @override
  Future<void> stop() => _stt.stop();

  @override
  Future<void> cancel() => _stt.cancel();
}
