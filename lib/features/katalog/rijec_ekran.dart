import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/core/modeli.dart';
import 'package:logomedo_app/features/katalog/katalog_repo.dart';
import 'package:logomedo_app/features/katalog/slika.dart';

/// Riječ: pozicije, sve slike po statusu, odluka o kandidatu i upload nove slike.
class RijecEkran extends ConsumerWidget {
  const RijecEkran({required this.slug, super.key});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rijec = ref.watch(rijecProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(rijec.value?.rijec.toUpperCase() ?? '')),
      floatingActionButton: rijec.value == null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Učitaj sliku'),
              onPressed: () async {
                final r = rijec.value!;
                final ucitano = await context.push<bool>('/rijec/${r.slug}/upload', extra: r);
                if (ucitano ?? false) ref.invalidate(rijecProvider(slug));
              },
            ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(rijecProvider(slug).future),
        child: switch (rijec) {
          AsyncData(:final value) => _Detalj(r: value),
          AsyncError(:final error) => ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(porukaGreske(error)))]),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Detalj extends StatelessWidget {
  const _Detalj({required this.r});
  final RijecDetalj r;

  static const _redoslijed = ['odobrena', 'kandidat', 'odbijena'];
  static const _naslovi = {'odobrena': 'Odobrena', 'kandidat': 'Za pregled', 'odbijena': 'Odbijene'};

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in r.pozicije)
              Chip(
                label: Text('${p.oznaka} · ${naziviPozicija[p.pozicija]}'),
                avatar: p.potvrdeno ? const Icon(Icons.check, size: 16) : null,
              ),
          ],
        ),
        if (r.opisZaSliku != null) ...[const SizedBox(height: 12), Text('Opis za sliku: ${r.opisZaSliku}', style: t.bodyMedium)],
        if (r.recenica != null) ...[const SizedBox(height: 4), Text('„${r.recenica}”', style: t.bodyMedium)],
        if (r.uRedu > 0) ...[const SizedBox(height: 8), Text('${r.uRedu} u redu za generiranje', style: t.bodySmall)],
        for (final status in _redoslijed)
          if (r.slike.any((s) => s.status == status)) ...[
            const SizedBox(height: 20),
            Text(_naslovi[status]!, style: t.titleMedium),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final s in r.slike.where((s) => s.status == status))
                  _SlikaKartica(s: s, slug: r.slug),
              ],
            ),
          ],
        if (r.slike.isEmpty) const Padding(padding: EdgeInsets.only(top: 32), child: Center(child: Text('Još nema slika.'))),
      ],
    );
  }
}

class _SlikaKartica extends ConsumerWidget {
  const _SlikaKartica({required this.s, required this.slug});
  final Slika s;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _odluka(context, ref),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SlikaKataloga(url: s.url, cdn: s.cdn),
              if (s.izvor == 'upload')
                const Positioned(right: 6, top: 6, child: Icon(Icons.upload, size: 18)),
            ],
          ),
        ),
      );

  Future<void> _odluka(BuildContext context, WidgetRef ref) async {
    final razlog = TextEditingController();
    final akcija = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(aspectRatio: 1, child: SlikaKataloga(url: s.url, cdn: s.cdn)),
            if (s.prompt != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.prompt!, maxLines: 4, overflow: TextOverflow.ellipsis)),
            if (s.razlog != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Razlog: ${s.razlog}')),
            const SizedBox(height: 12),
            if (s.status == 'kandidat') ...[
              TextField(controller: razlog, decoration: const InputDecoration(labelText: 'Razlog odbijanja (ide u sljedeći prompt)')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, 'odbij'), child: const Text('Odbij'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, 'odobri'), child: const Text('Odobri'))),
                ],
              ),
            ] else
              OutlinedButton(onPressed: () => Navigator.pop(context, 'vrati'), child: const Text('Vrati u kandidate')),
          ],
        ),
      ),
    );
    if (akcija == null || !context.mounted) return;
    final poruka = ScaffoldMessenger.of(context);
    try {
      final vec = await ref.read(katalogRadnjeProvider).odluci(s.id, akcija, razlog: razlog.text.trim().isEmpty ? null : razlog.text.trim());
      if (vec != null) poruka.showSnackBar(SnackBar(content: Text(vec)));
    } on Object catch (e) {
      poruka.showSnackBar(SnackBar(content: Text(porukaGreske(e))));
    }
    ref
      ..invalidate(rijecProvider(slug))
      ..invalidate(katalogProvider);
  }
}
