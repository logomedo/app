import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/core/modeli.dart';
import 'package:logomedo_app/core/prijava.dart';
import 'package:logomedo_app/features/katalog/katalog_repo.dart';
import 'package:logomedo_app/features/katalog/trazilica.dart';

/// Početni ekran admina: stil i glasovi s brojem riječi, odobrenih i kandidata.
class KatalogEkran extends ConsumerWidget {
  const KatalogEkran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final katalog = ref.watch(katalogProvider);
    final stil = ref.watch(stilProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog'),
        actions: [
          IconButton(
            tooltip: 'Traži riječ',
            icon: const Icon(Icons.search),
            onPressed: () => otvoriTrazilicu(context),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'odjava') unawaited(ref.read(prijavaProvider.notifier).odjaviSe());
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(switch (ref.read(prijavaProvider)) { Prijavljen(:final ja) => ja.email, _ => '' }),
              ),
              const PopupMenuItem(value: 'odjava', child: Text('Odjava')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(katalogProvider.future),
        child: switch (katalog) {
          AsyncData(:final value) => _Sadrzaj(katalog: value, stil: stil),
          AsyncError(:final error) => _Greska(poruka: porukaGreske(error), ponovi: () => ref.invalidate(katalogProvider)),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Sadrzaj extends ConsumerWidget {
  const _Sadrzaj({required this.katalog, required this.stil});
  final Katalog katalog;
  final String stil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: [for (final s in katalog.stilovi) ButtonSegment(value: s.kod, label: Text(s.naziv))],
                  selected: {stil},
                  onSelectionChanged: (v) => ref.read(stilProvider.notifier).postavi(v.first),
                ),
                const SizedBox(height: 12),
                Text(
                  '${katalog.rijeci} riječi · ${katalog.odobreno} odobreno · ${katalog.kandidata} kandidata',
                  style: t.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: katalog.glasovi.length,
            itemBuilder: (context, i) => _GlasKartica(g: katalog.glasovi[i]),
          ),
        ),
      ],
    );
  }
}

class _GlasKartica extends StatelessWidget {
  const _GlasKartica({required this.g});
  final GlasPregled g;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final boje = Theme.of(context).colorScheme;
    final udio = g.rijeci == 0 ? 0.0 : g.odobreno / g.rijeci;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/glas/${g.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(g.oznaka, style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w600, color: boje.primary)),
              const Spacer(),
              Text('${g.odobreno} / ${g.rijeci}', style: t.titleMedium),
              if (g.kandidata > 0 || g.uRedu > 0)
                Text(
                  [if (g.kandidata > 0) '${g.kandidata} za pregled', if (g.uRedu > 0) '${g.uRedu} u redu'].join(' · '),
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: udio, borderRadius: BorderRadius.circular(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greska extends StatelessWidget {
  const _Greska({required this.poruka, required this.ponovi});
  final String poruka;
  final VoidCallback ponovi;

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(poruka)),
          const SizedBox(height: 12),
          Center(child: FilledButton.tonal(onPressed: ponovi, child: const Text('Pokušaj ponovno'))),
        ],
      );
}
