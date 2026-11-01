import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logomedo_app/core/modeli.dart';
import 'package:logomedo_app/features/katalog/katalog_repo.dart';

/// Bez dijakritika i malim slovima, kao tražilica na webu („cvrcak” nađe ČVRČAK).
String bezKvacica(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[čć]'), 'c')
    .replaceAll('đ', 'd')
    .replaceAll('š', 's')
    .replaceAll('ž', 'z');

/// Riječi koje počinju upitom pa one koje ga sadrže.
List<StavkaIndeksa> filtriraj(List<StavkaIndeksa> sve, String upit) {
  final u = bezKvacica(upit.trim());
  if (u.isEmpty) return const [];
  final pocinje = <StavkaIndeksa>[];
  final sadrzi = <StavkaIndeksa>[];
  for (final s in sve) {
    final r = bezKvacica(s.rijec);
    if (r.startsWith(u)) {
      pocinje.add(s);
    } else if (r.contains(u)) {
      sadrzi.add(s);
    }
  }
  return [...pocinje, ...sadrzi].take(50).toList();
}

void otvoriTrazilicu(BuildContext context) {
  unawaited(showSearch<void>(context: context, delegate: _Trazilica()));
}

class _Trazilica extends SearchDelegate<void> {
  _Trazilica() : super(searchFieldLabel: 'Riječ');

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => const BackButton();

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) => Consumer(
        builder: (context, ref, _) => switch (ref.watch(indeksProvider)) {
          AsyncData(:final value) => ListView(
              children: [
                for (final s in filtriraj(value, query))
                  ListTile(
                    title: Text(s.rijec.toUpperCase()),
                    trailing: s.odobrena
                        ? const Icon(Icons.check_circle_outline)
                        : s.kandidata > 0
                            ? Text('${s.kandidata} za pregled')
                            : null,
                    onTap: () {
                      close(context, null);
                      unawaited(context.push('/rijec/${s.slug}'));
                    },
                  ),
              ],
            ),
          AsyncError() => const Center(child: Text('Indeks riječi nije dostupan.')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      );
}
