import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logomedo_app/core/modeli.dart';
import 'package:logomedo_app/core/prijava.dart';
import 'package:logomedo_app/features/katalog/glas_ekran.dart';
import 'package:logomedo_app/features/katalog/katalog_ekran.dart';
import 'package:logomedo_app/features/katalog/rijec_ekran.dart';
import 'package:logomedo_app/features/katalog/upload_ekran.dart';
import 'package:logomedo_app/features/prijava/prijava_ekran.dart';
import 'package:logomedo_app/features/vjezbe/igra_ekran.dart';
import 'package:logomedo_app/features/vjezbe/vjezbe_ekran.dart';

/// Rute. Admin dio je pod korijenom; kasnije vježbenice za logopede dobivaju svoj dio
/// (npr. /vjezbe), a početni ekran se bira po ulozi.
final routerProvider = Provider<GoRouter>((ref) {
  final osvjezi = ValueNotifier(0);
  ref
    ..listen(prijavaProvider, (_, _) => osvjezi.value++)
    ..onDispose(osvjezi.dispose);
  return GoRouter(
    refreshListenable: osvjezi,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, s) {
      final stanje = ref.read(prijavaProvider);
      final naPrijavi = s.matchedLocation == '/prijava';
      return switch (stanje) {
        Ucitava() => s.matchedLocation == '/ucitava' ? null : '/ucitava',
        Odjavljen() => naPrijavi ? null : '/prijava',
        Prijavljen() => (naPrijavi || s.matchedLocation == '/ucitava') ? '/' : null,
      };
    },
    routes: [
      GoRoute(path: '/ucitava', builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
      GoRoute(path: '/prijava', builder: (_, _) => const PrijavaEkran()),
      GoRoute(path: '/', builder: (_, _) => const KatalogEkran()),
      GoRoute(path: '/vjezbe', builder: (_, _) => const VjezbeEkran()),
      GoRoute(path: '/biljeznica/:slug', builder: (_, s) => BiljeznicaIgraEkran(slug: s.pathParameters['slug']!)),
      GoRoute(path: '/zadatak/:id', builder: (_, s) => ZadatakIgraEkran(id: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/glas/:slug', builder: (_, s) => GlasEkran(slug: s.pathParameters['slug']!)),
      GoRoute(
        path: '/rijec/:slug',
        builder: (_, s) => RijecEkran(slug: s.pathParameters['slug']!),
        routes: [
          GoRoute(path: 'upload', builder: (_, s) => UploadEkran(rijec: s.extra! as RijecDetalj)),
        ],
      ),
    ],
  );
});
