import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PKCE (RFC 7636, S256): verifikator ostaje u aplikaciji, izazov ide u preglednik.
class Pkce {
  Pkce._(this.verifikator, this.izazov);

  factory Pkce.novi() {
    final r = Random.secure();
    final v = _b64url(List<int>.generate(32, (_) => r.nextInt(256)));
    return Pkce._(v, izazovIz(v));
  }

  final String verifikator;
  final String izazov;

  static String izazovIz(String verifikator) =>
      _b64url(sha256.convert(ascii.encode(verifikator)).bytes);

  static String _b64url(List<int> b) => base64Url.encode(b).replaceAll('=', '');
}
