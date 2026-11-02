import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logomedo_app/features/vjezbe/modeli.dart';
import 'package:logomedo_app/features/vjezbe/scena.dart';

void main() {
  test('traka: vodoravno jedan red, uspravno dva iznad 4 gumba', () {
    expect(stupacaScene(7, Orijentacija.vodoravno), 7);
    expect(stupacaScene(7, Orijentacija.uspravno), 4);
    expect(stupacaScene(4, Orijentacija.uspravno), 4);
    expect(stupacaScene(0, Orijentacija.uspravno), 1);
  });

  test('scena preskače prazne gumbe i čuva izvorni indeks', () {
    final s = Scena.izJsona({
      'pozadina_id': 2,
      'gumbi': [
        {'rijec_id': 1, 'tocno': true},
        {'rijec_id': null, 'tocno': true},
        {'rijec_id': 3, 'tocno': false},
      ],
    });
    expect(s.gumbi.map((g) => g.i), [0, 2]);
    expect(s.gumbi.last.tocno, isFalse);
  });

  test('pozadina bez tražene orijentacije daje drugu', () {
    final p = Pozadina.izJsona({
      'id': 1, 'naziv': 'x', 'uspravno': null,
      'vodoravno': {'url': 'https://cdn.logomedo.com/a.jpg', 'sirina': 1024, 'visina': 765},
    });
    expect(p.za(Orijentacija.uspravno)?.tocna, isFalse);
    expect(p.za(Orijentacija.vodoravno)?.tocna, isTrue);
  });

  testWidgets('točan dodir označi gumb, krivi ne; kraj kad su svi točni', (t) async {
    final scena = Scena.izJsona({
      'pozadina_id': null,
      'gumbi': [
        {'rijec_id': 1, 'tocno': true},
        {'rijec_id': 2, 'tocno': false},
        {'rijec_id': 3, 'tocno': true},
      ],
    });
    final rijeci = {
      for (final (id, r) in [(1, 'brašno'), (2, 'čekić'), (3, 'jaje')]) id: RijecPrikaz.izJsona({'id': id, 'rijec': r, 'slika': null}),
    };
    final pogodeni = <int>{};
    var kraj = 0;
    final dodiri = <(int, bool)>[];
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: SizedBox(
          width: 1024,
          height: 768,
          child: ScenaPrikaz(
            scena: scena, pitanje: 'Što treba?', pozadina: null, rijeci: rijeci, pogodeni: pogodeni,
            naDodir: (i, {required tocno}) => dodiri.add((i, tocno)),
            naKraj: () => kraj++,
          ),
        ),
      ),
    ));
    expect(find.text('ČEKIĆ'), findsOneWidget);
    await t.tap(find.text('ČEKIĆ'));
    await t.pump(const Duration(milliseconds: 500));
    expect(pogodeni, isEmpty);
    await t.tap(find.text('BRAŠNO'));
    await t.tap(find.text('JAJE'));
    await t.pump();
    expect(pogodeni, {0, 2});
    expect(kraj, 1);
    expect(dodiri, [(1, false), (0, true), (2, true)]);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
  });
}
