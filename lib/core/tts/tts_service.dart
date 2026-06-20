import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  TTSService() {
    _init();
  }

  Future<void> _init() async {
    await _flutterTts.setSpeechRate(0.5); // Standard rate for learning pronunciation
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Speaks text in US English accent
  Future<void> speakUS(String text) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak(text);
  }

  /// Speaks text in UK English accent
  Future<void> speakUK(String text) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-GB');
    await _flutterTts.speak(text);
  }

  /// Stops current speech output
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});
