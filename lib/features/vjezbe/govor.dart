import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Glas sustava (hr-HR) za pitanje i riječi, kao `speechSynthesis` u igri preglednika.
/// Kasnije snimke logopedice po riječi imaju prednost (logomedo.com docs/biljeznice.md).
class Govor {
  final _tts = FlutterTts();
  Future<void>? _priprema;

  Future<void> _pripremi() => _priprema ??= () async {
        await _tts.setLanguage('hr-HR');
        // flutter_tts: 0.5 je normalna brzina na Androidu; nešto sporije za djecu.
        await _tts.setSpeechRate(0.42);
      }();

  Future<void> reci(String tekst) async {
    if (tekst.trim().isEmpty) return;
    await _pripremi();
    await _tts.stop();
    await _tts.speak(tekst);
  }

  void stani() => unawaited(_tts.stop());
}

final govorProvider = Provider((ref) {
  final g = Govor();
  ref.onDispose(g.stani);
  return g;
});
