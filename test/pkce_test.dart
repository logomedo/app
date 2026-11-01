import 'package:flutter_test/flutter_test.dart';
import 'package:logomedo_app/core/pkce.dart';

void main() {
  test('S256 izazov iz RFC 7636, dodatak B (isti test kao na serveru)', () {
    expect(Pkce.izazovIz('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'), 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
  });

  test('novi verifikator: 43 znaka base64url, izazov odgovara', () {
    final p = Pkce.novi();
    expect(p.verifikator, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(p.izazov, Pkce.izazovIz(p.verifikator));
  });
}
