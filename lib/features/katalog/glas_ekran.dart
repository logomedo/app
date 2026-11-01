import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/core/modeli.dart';
import 'package:logomedo_app/features/katalog/katalog_repo.dart';
import 'package:logomedo_app/features/katalog/slika.dart';

/// Riječi jednog glasa po pozicijama, s odobrenom slikom u odabranom stilu.
class GlasEkran extends ConsumerWidget {
  const GlasEkran({required this.slug, super.key});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glas = ref.watch(glasProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(glas.value != null ? 'Glas ${glas.value!.oznaka}' : 'Glas')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(glasProvider(slug).future),
        child: switch (glas) {
          AsyncData(:final value) => _Popis(g: value),
          AsyncError(:final error) => ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(porukaGreske(error)))]),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Popis extends StatelessWidget {
  const _Popis({required this.g});
  final GlasRijeci g;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        for (final p in pozicije)
          if (g.rijeci.any((r) => r.pozicija == p)) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(child: Text(naziviPozicija[p]!, style: t.titleMedium)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: g.rijeci.where((r) => r.pozicija == p).length,
                itemBuilder: (context, i) => _Rijec(r: g.rijeci.where((r) => r.pozicija == p).elementAt(i)),
              ),
            ),
          ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _Rijec extends StatelessWidget {
  const _Rijec({required this.r});
  final RijecRed r;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/rijec/${r.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: r.odobrenaId != null
                  ? SlikaKataloga.poId(r.odobrenaId!)
                  : Center(
                      child: Text(
                        r.kandidata > 0 ? '${r.kandidata} za pregled' : (r.uRedu > 0 ? 'u redu' : '—'),
                        style: t.bodySmall,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(r.rijec.toUpperCase(), style: t.labelLarge, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
