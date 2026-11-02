import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/features/vjezbe/govor.dart';
import 'package:logomedo_app/features/vjezbe/modeli.dart';
import 'package:logomedo_app/features/vjezbe/scena.dart';
import 'package:logomedo_app/features/vjezbe/vjezbe_repo.dart';

/// Bilježnica kao igra: ekrani redom, preko cijelog ekrana.
class BiljeznicaIgraEkran extends ConsumerWidget {
  const BiljeznicaIgraEkran({required this.slug, super.key});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(biljeznicaProvider(slug))) {
        AsyncData(:final value) => IgraEkran(igra: value.igra, kraj: value.kraj, boja: _boja(value.boja)),
        AsyncError(:final error) => _Greska(porukaGreske(error), () => ref.invalidate(biljeznicaProvider(slug))),
        _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
      };
}

/// Jedan zadatak kao igra: pregled „Dijete rješava” u aplikaciji.
class ZadatakIgraEkran extends ConsumerWidget {
  const ZadatakIgraEkran({required this.id, super.key});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(zadatakIgraProvider(id))) {
        AsyncData(:final value) => IgraEkran(igra: value.igra, kraj: 'Bravo!'),
        AsyncError(:final error) => _Greska(porukaGreske(error), () => ref.invalidate(zadatakIgraProvider(id))),
        _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
      };
}

Color _boja(String hex) => Color(int.tryParse('FF${hex.replaceFirst('#', '')}', radix: 16) ?? 0xFF1B2A5C);

class IgraEkran extends ConsumerStatefulWidget {
  const IgraEkran({required this.igra, required this.kraj, this.boja = const Color(0xFF1B2A5C), super.key});
  final Igra igra;
  final String kraj;
  final Color boja;

  @override
  ConsumerState<IgraEkran> createState() => _IgraEkranState();
}

class _IgraEkranState extends ConsumerState<IgraEkran> {
  var _i = 0;
  final _pogodeni = <int, Set<int>>{};
  final _rijeseni = <int>{};

  List<Ekran> get _ekrani => widget.igra.ekrani;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
    WidgetsBinding.instance.addPostFrameCallback((_) => _procitaj());
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  void _procitaj() {
    if (!mounted) return;
    if (_i < _ekrani.length) unawaited(ref.read(govorProvider).reci(_ekrani[_i].uputa));
  }

  void _idi(int i) {
    setState(() => _i = i);
    _procitaj();
  }

  void _ponovi() {
    _pogodeni.clear();
    _rijeseni.clear();
    _idi(0);
  }

  @override
  Widget build(BuildContext context) {
    final kraj = _i >= _ekrani.length;
    return Scaffold(
      backgroundColor: widget.boja,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (kraj)
            _Kraj(tekst: _ekrani.isEmpty ? 'Ova bilježnica još nema ekrana za igru.' : widget.kraj, rijeseno: _rijeseni.length, ukupno: _ekrani.length, ponovi: _ponovi)
          else
            _ekran(_ekrani[_i]),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Okrugli(ikona: Icons.close_rounded, opis: 'Zatvori', naDodir: () => context.pop()),
                  const Spacer(),
                  if (!kraj && _ekrani.length > 1) _Napredak(trenutni: _i, ukupno: _ekrani.length, rijeseni: _rijeseni),
                  const SizedBox(width: 8),
                  if (!kraj && _i > 0) _Okrugli(ikona: Icons.chevron_left_rounded, opis: 'Natrag', naDodir: () => _idi(_i - 1)),
                  if (!kraj) ...[
                    const SizedBox(width: 8),
                    _Okrugli(
                      ikona: Icons.chevron_right_rounded,
                      opis: 'Dalje',
                      istaknut: _rijeseni.contains(_i),
                      naDodir: () => _idi(_i + 1),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ekran(Ekran e) {
    final s = e.scena;
    if (s == null) return _NijeUAplikaciji(vrsta: e.vrsta);
    final i = _i;
    return ScenaPrikaz(
      key: ValueKey('ekran-$i'),
      scena: s,
      pitanje: e.uputa,
      pozadina: widget.igra.pozadine[s.pozadinaId],
      rijeci: widget.igra.rijeci,
      pogodeni: _pogodeni.putIfAbsent(i, () => <int>{}),
      // Ispod trake (zatvori, lampice, dalje): 8 + 48 + 8 uz gornji sigurni rub.
      odmakVrha: MediaQuery.paddingOf(context).top + 56,
      naKraj: () {
        setState(() => _rijeseni.add(i));
        // Kao u pregledniku: trenutak da se vidi rješenje, pa sljedeći ekran.
        Future<void>.delayed(const Duration(milliseconds: 1600), () {
          if (mounted && _i == i) _idi(i + 1);
        });
      },
    );
  }
}

class _Okrugli extends StatelessWidget {
  const _Okrugli({required this.ikona, required this.opis, required this.naDodir, this.istaknut = false});
  final IconData ikona;
  final String opis;
  final VoidCallback naDodir;
  final bool istaknut;

  @override
  Widget build(BuildContext context) => Material(
        color: istaknut ? const Color(0xFFE0A526) : const Color(0xCCFBF5E8),
        shape: const CircleBorder(),
        elevation: 2,
        child: IconButton(tooltip: opis, icon: Icon(ikona), color: const Color(0xFF2F2619), onPressed: naDodir),
      );
}

/// Lampice: jedna po ekranu, upaljena kad je ekran riješen.
class _Napredak extends StatelessWidget {
  const _Napredak({required this.trenutni, required this.ukupno, required this.rijeseni});
  final int trenutni;
  final int ukupno;
  final Set<int> rijeseni;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var k = 0; k < ukupno; k++)
              Container(
                width: k == trenutni ? 14 : 10,
                height: k == trenutni ? 14 : 10,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rijeseni.contains(k) ? const Color(0xFFF4C75A) : const Color(0x55FFFFFF),
                  border: k == trenutni ? Border.all(color: Colors.white, width: 2) : null,
                ),
              ),
          ],
        ),
      );
}

class _NijeUAplikaciji extends StatelessWidget {
  const _NijeUAplikaciji({required this.vrsta});
  final String vrsta;

  @override
  Widget build(BuildContext context) => Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Vrsta „$vrsta” još nije u aplikaciji.\nRiješite je u pregledniku ili idite dalje.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
}

class _Kraj extends StatelessWidget {
  const _Kraj({required this.tekst, required this.rijeseno, required this.ukupno, required this.ponovi});
  final String tekst;
  final int rijeseno;
  final int ukupno;
  final VoidCallback ponovi;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tekst, textAlign: TextAlign.center, style: t.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          if (ukupno > 0) ...[
            const SizedBox(height: 8),
            Text('Riješeno $rijeseno od $ukupno', style: t.titleMedium?.copyWith(color: Colors.white70)),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: ponovi, icon: const Icon(Icons.replay_rounded), label: const Text('Ponovi')),
          ],
        ],
      ),
    );
  }
}

class _Greska extends StatelessWidget {
  const _Greska(this.poruka, this.ponovi);
  final String poruka;
  final VoidCallback ponovi;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(poruka),
            const SizedBox(height: 12),
            FilledButton(onPressed: ponovi, child: const Text('Pokušaj ponovno')),
          ]),
        ),
      );
}
