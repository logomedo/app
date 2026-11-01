import 'package:flutter_test/flutter_test.dart';
import 'package:logomedo_app/core/modeli.dart';
import 'package:logomedo_app/features/katalog/trazilica.dart';

StavkaIndeksa s(String r) => StavkaIndeksa.izJsona({'r': r, 's': r, 'o': 0, 'k': 0});

void main() {
  test('bez kvačica, prvo one koje počinju upitom', () {
    final sve = [s('kišobran'), s('čvrčak'), s('miš'), s('šišmiš')];
    expect(filtriraj(sve, 'cvrc').map((x) => x.rijec), ['čvrčak']);
    expect(filtriraj(sve, 'mis').map((x) => x.rijec), ['miš', 'šišmiš']);
    expect(filtriraj(sve, '  '), isEmpty);
  });
}
