// Renderer vrste `scena` (logomedo.com docs/zadaci.md „scena”): pozadina preko cijelog
// prostora, pitanje sa zvučnikom na vrhu, traka gumba sa slikama uz donji rub.
// Mjere su prepisane iz logomedo.com src/lib/scena.css: `m` je 1 % kraće strane (cqmin),
// `cw` 1 % širine (cqw), pa scena izgleda isto kao u adminu i u igri preglednika.

import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logomedo_app/features/vjezbe/govor.dart';
import 'package:logomedo_app/features/vjezbe/modeli.dart';

String _veliko(String s) => s.toUpperCase();

/// Raspored trake: vodoravno jedan red, uspravno dva reda kad je više od 4 gumba.
@visibleForTesting
int stupacaScene(int gumba, Orijentacija o) =>
    math.max(1, o == Orijentacija.uspravno && gumba > 4 ? (gumba / 2).ceil() : gumba);

class ScenaPrikaz extends ConsumerStatefulWidget {
  const ScenaPrikaz({
    required this.scena,
    required this.pitanje,
    required this.pozadina,
    required this.rijeci,
    required this.pogodeni,
    this.naDodir,
    this.naKraj,
    this.odmakVrha = 0,
    super.key,
  });

  final Scena scena;
  final String pitanje;
  final Pozadina? pozadina;
  final Map<int, RijecPrikaz> rijeci;

  /// Indeksi točno dirnutih gumba. Drži ih pozivatelj, pa okretanje ekrana ništa ne gubi.
  final Set<int> pogodeni;
  final void Function(int i, {required bool tocno})? naDodir;
  final VoidCallback? naKraj;

  /// Prostor iznad pitanja (traka s gumbima igre preko scene).
  final double odmakVrha;

  @override
  ConsumerState<ScenaPrikaz> createState() => _ScenaPrikazState();
}

class _ScenaPrikazState extends ConsumerState<ScenaPrikaz> {
  List<GumbScene> get _gumbi => widget.scena.gumbi;
  bool get _gotovo => _gumbi.any((g) => g.tocno) && _gumbi.every((g) => !g.tocno || widget.pogodeni.contains(g.i));

  void _reci(String t) => unawaited(ref.read(govorProvider).reci(t));

  /// Vraća je li dodir bio točan (krivi gumb se zatrese).
  bool _dodir(GumbScene g, String ime) {
    if (_gotovo || widget.pogodeni.contains(g.i)) {
      _reci(ime);
      return true;
    }
    widget.naDodir?.call(g.i, tocno: g.tocno);
    if (!g.tocno) return false;
    setState(() => widget.pogodeni.add(g.i));
    _reci(ime);
    if (_gotovo) widget.naKraj?.call();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final o = w >= h ? Orijentacija.vodoravno : Orijentacija.uspravno;
      final m = math.min(w, h) / 100;
      final cw = w / 100;
      final poz = widget.pozadina?.za(o);
      final gotovo = _gotovo;

      return ClipRect(
        child: ColoredBox(
          color: poz != null && !poz.tocna ? const Color(0xFF3A3226) : const Color(0xFFEFE6D4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (poz != null)
                CachedNetworkImage(
                  imageUrl: poz.slika.url,
                  fit: poz.tocna ? BoxFit.cover : BoxFit.contain,
                  errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined)),
                )
              else
                Center(
                  child: Text('Pozadina nije odabrana',
                      style: TextStyle(color: const Color(0xFF8A7B62), fontWeight: FontWeight.w700, fontSize: 4 * m)),
                ),
              Positioned(
                top: widget.odmakVrha + 2.5 * m,
                left: 0,
                right: 0,
                child: Center(child: _Pitanje(tekst: widget.pitanje, m: m, w: w, naZvuk: () => _reci(widget.pitanje))),
              ),
              Positioned(
                left: 2 * m,
                right: 2 * m,
                bottom: 2.5 * m,
                child: _traka(o, m, cw, w - 4 * m, gotovo),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _traka(Orijentacija o, double m, double cw, double dostupno, bool gotovo) {
    final g = _gumbi;
    final stupaca = stupacaScene(g.length, o);
    final sirina = o == Orijentacija.vodoravno ? math.min(dostupno, stupaca * 17 * cw) : dostupno;
    final razmak = 1.6 * m;
    final celija = (sirina - razmak * (stupaca - 1)) / stupaca;
    final gumbW = math.min(celija, o == Orijentacija.vodoravno ? 22 * m : 18 * cw);
    final gumbH = o == Orijentacija.vodoravno ? gumbW * 6 / 5 : gumbW;
    final redovi = <Widget>[];
    for (var r = 0; r * stupaca < g.length; r++) {
      if (r > 0) redovi.add(SizedBox(height: razmak));
      redovi.add(Row(
        children: [
          for (var k = 0; k < stupaca; k++) ...[
            if (k > 0) SizedBox(width: razmak),
            SizedBox(
              width: celija,
              child: r * stupaca + k < g.length
                  ? Center(child: _gumb(g[r * stupaca + k], m, gumbW, gumbH, gotovo))
                  : null,
            ),
          ],
        ],
      ));
    }
    return Center(child: SizedBox(width: sirina, child: Column(mainAxisSize: MainAxisSize.min, children: redovi)));
  }

  Widget _gumb(GumbScene g, double m, double w, double h, bool gotovo) {
    final r = widget.rijeci[g.rijecId];
    final ime = r == null ? '?' : _veliko(r.rijec);
    return _GumbScene(
      key: ValueKey(g.i),
      ime: ime,
      slika: r?.slika,
      m: m,
      sirina: w,
      visina: h,
      pogodak: widget.pogodeni.contains(g.i),
      ugaseno: gotovo && !g.tocno,
      naDodir: () => _dodir(g, ime),
    );
  }
}

class _Pitanje extends StatelessWidget {
  const _Pitanje({required this.tekst, required this.m, required this.w, required this.naZvuk});
  final String tekst;
  final double m;
  final double w;
  final VoidCallback naZvuk;

  @override
  Widget build(BuildContext context) {
    final font = (3.6 * m).clamp(14.0, 42.0);
    return Container(
      constraints: BoxConstraints(maxWidth: w * 0.88),
      padding: EdgeInsets.fromLTRB(3.4 * m, 1.6 * m, 2 * m, 1.6 * m),
      decoration: BoxDecoration(
        color: const Color(0xF2F6EDD9),
        borderRadius: BorderRadius.circular(1.6 * m),
        border: Border.all(color: const Color(0xFFB99566), width: 0.4 * m),
        boxShadow: [BoxShadow(color: const Color(0x44000000), blurRadius: 2.4 * m, offset: Offset(0, 0.8 * m))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              tekst.isEmpty ? '…' : tekst,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: font, fontWeight: FontWeight.w800, height: 1.2, color: const Color(0xFF2F2619)),
            ),
          ),
          SizedBox(width: 2 * m),
          Semantics(
            button: true,
            label: 'Poslušaj pitanje',
            child: Material(
              color: const Color(0xFF2D6FB7),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: naZvuk,
                child: SizedBox.square(
                  dimension: font * 1.9,
                  child: Icon(Icons.volume_up_rounded, color: Colors.white, size: font * 1.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _sivo = ColorFilter.matrix(<double>[
  0.5, 0.4, 0.1, 0, 0, //
  0.3, 0.6, 0.1, 0, 0, //
  0.3, 0.4, 0.3, 0, 0, //
  0, 0, 0, 1, 0,
]);

class _GumbScene extends StatefulWidget {
  const _GumbScene({
    required this.ime,
    required this.slika,
    required this.m,
    required this.sirina,
    required this.visina,
    required this.pogodak,
    required this.ugaseno,
    required this.naDodir,
    super.key,
  });
  final String ime;
  final String? slika;
  final double m;
  final double sirina;
  final double visina;
  final bool pogodak;
  final bool ugaseno;

  /// Vraća je li dodir bio točan.
  final bool Function() naDodir;

  @override
  State<_GumbScene> createState() => _GumbSceneState();
}

class _GumbSceneState extends State<_GumbScene> with SingleTickerProviderStateMixin {
  late final _trese = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void dispose() {
    _trese.dispose();
    super.dispose();
  }

  void _tap() {
    if (!widget.naDodir()) _trese.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final rijecFont = (2.3 * m).clamp(9.0, 22.0);
    final bezFont = (2.6 * m).clamp(9.0, 24.0);
    final mirno = MediaQuery.disableAnimationsOf(context);

    final kartica = AnimatedBuilder(
      animation: _trese,
      builder: (context, dijete) {
        final t = _trese.value;
        final krivo = _trese.isAnimating;
        // Kao @keyframes scena-trese: lijevo-desno dvaput, ±1.4 cqmin.
        final dx = mirno || !krivo ? 0.0 : math.sin(t * math.pi * 4) * 1.4 * m;
        final rub = widget.pogodak
            ? const Color(0xFFE0A526)
            : krivo
                ? const Color(0xFFC4473A)
                : const Color(0xFFC9AD80);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Container(
            width: widget.sirina,
            height: widget.visina,
            padding: EdgeInsets.fromLTRB(m, m, m, 0.6 * m),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF5E8),
              borderRadius: BorderRadius.circular(1.8 * m),
              border: Border.all(color: rub, width: 0.5 * m),
              boxShadow: [
                if (widget.pogodak) BoxShadow(color: const Color(0x88F4C75A), spreadRadius: 0.6 * m),
                BoxShadow(color: const Color(0x55000000), blurRadius: 1.6 * m, offset: Offset(0, 0.7 * m)),
              ],
            ),
            child: dijete,
          ),
        );
      },
      child: widget.slika != null
          ? Column(
              children: [
                Expanded(child: CachedNetworkImage(imageUrl: widget.slika!, fit: BoxFit.contain)),
                SizedBox(height: 0.4 * m),
                Text(widget.ime,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: rijecFont, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: const Color(0xFF2F2619))),
              ],
            )
          : Center(
              child: Text(widget.ime,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: bezFont, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: const Color(0xFF5C5345))),
            ),
    );

    Widget gumb = Semantics(
      button: true,
      label: widget.ime,
      child: GestureDetector(onTap: _tap, behavior: HitTestBehavior.opaque, child: kartica),
    );
    if (widget.pogodak) {
      gumb = Stack(
        clipBehavior: Clip.none,
        children: [
          gumb,
          Positioned(
            top: -2.4 * m,
            right: -1.6 * m,
            // Na webu je debela SVG kvačica; ovdje zlatni krug da se vidi i preko svijetle pozadine.
            child: Container(
              width: 5.2 * m,
              height: 5.2 * m,
              decoration: BoxDecoration(
                color: const Color(0xFFD99A12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 0.4 * m),
                boxShadow: [BoxShadow(color: const Color(0x55000000), blurRadius: m)],
              ),
              child: Icon(Icons.check_rounded, size: 3.6 * m, color: Colors.white),
            ),
          ),
        ],
      );
    }
    return AnimatedOpacity(
      opacity: widget.ugaseno ? 0.45 : 1,
      duration: const Duration(milliseconds: 300),
      child: widget.ugaseno ? ColorFiltered(colorFilter: _sivo, child: gumb) : gumb,
    );
  }
}
