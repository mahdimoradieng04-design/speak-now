import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _ensure() async {
    if (_ready) return;
    await _tts.setLanguage('en-US');
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// English voices installed on the device: [{name, locale}].
  Future<List<Map<String, String>>> englishVoices() async {
    await _ensure();
    final raw = await _tts.getVoices;
    final out = <Map<String, String>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final name = e['name']?.toString();
          final loc = e['locale']?.toString();
          if (name != null &&
              loc != null &&
              loc.toLowerCase().replaceAll('_', '-').startsWith('en')) {
            out.add({'name': name, 'locale': loc});
          }
        }
      }
    }
    return out;
  }

  Future<void> configure(String? voiceName, String? voiceLocale, double rate) async {
    await _ensure();
    await _tts.setSpeechRate(rate);
    if (voiceName != null && voiceLocale != null) {
      await _tts.setVoice({'name': voiceName, 'locale': voiceLocale});
    }
  }

  Future<void> speak(String text) async {
    await _ensure();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
