import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/features/vjezbe/modeli.dart';
import 'package:logomedo_app/features/vjezbe/vjezbe_repo.dart';

const _nazivVrste = {
  'scena': 'Scena',
  'odabir': 'Odabir',
  'uljez': 'Uljez',
  'povezivanje': 'Povezivanje',
  'listic': 'Listić',
};

/// Vježbenice: bilježnice (igra redom) i pojedinačne scene (pregled „Dijete rješava”).
/// Uređivanje ostaje na webu (/admin/biljeznice, /admin/zadaci).
class VjezbeEkran extends ConsumerWidget {
  const VjezbeEkran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(biljeznicePopisProvider);
    final z = ref.watch(zadaciPopisProvider);
    final t = Theme.of(context).textTheme;
    Widget naslov(String s) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 4), child: Text(s, style: t.titleMedium));

    return Scaffold(
      appBar: AppBar(title: const Text('Vježbenice')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(biljeznicePopisProvider)
            ..invalidate(zadaciPopisProvider);
          await ref.read(biljeznicePopisProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            naslov('Bilježnice'),
            ..._redovi<BiljeznicaRed>(b, (x) => ListTile(
                  leading: Icon(x.tema == 'proljece' ? Icons.local_florist_outlined : Icons.park_outlined),
                  title: Text(x.naslov),
                  subtitle: Text([
                    '${x.zadataka} zadataka',
                    if (!x.javna) 'nije javna',
                    if (x.podnaslov != null && x.podnaslov!.isNotEmpty) x.podnaslov!,
                  ].join(' · ')),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => context.push('/biljeznica/${x.slug}'),
                )),
            naslov('Zadaci'),
            ..._redovi<ZadatakRed>(z, (x) => ListTile(
                  leading: Icon(x.vrsta == 'scena' ? Icons.image_outlined : Icons.extension_outlined),
                  title: Text(x.naslov),
                  subtitle: Text([_nazivVrste[x.vrsta] ?? x.vrsta, if (x.uputa != null) x.uputa!].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
                  // Zasad aplikacija crta samo scenu; ostale vrste igraju se u pregledniku.
                  enabled: x.vrsta == 'scena',
                  onTap: () => context.push('/zadatak/${x.id}'),
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _redovi<T>(AsyncValue<List<T>> v, Widget Function(T) red) => switch (v) {
        AsyncData(:final value) when value.isEmpty => [const ListTile(title: Text('Još ništa.'))],
        AsyncData(:final value) => [for (final x in value) red(x)],
        AsyncError(:final error) => [ListTile(leading: const Icon(Icons.error_outline), title: Text(porukaGreske(error)))],
        _ => [const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))],
      };
}
