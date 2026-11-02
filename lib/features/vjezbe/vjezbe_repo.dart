import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/features/vjezbe/modeli.dart';

final biljeznicePopisProvider = FutureProvider.autoDispose<List<BiljeznicaRed>>((ref) async {
  final r = await ref.watch(apiProvider).get<List<dynamic>>('/api/v1/admin/biljeznice');
  return [for (final b in r.data!) BiljeznicaRed.izJsona(b as Map<String, dynamic>)];
});

final zadaciPopisProvider = FutureProvider.autoDispose<List<ZadatakRed>>((ref) async {
  final r = await ref.watch(apiProvider).get<List<dynamic>>('/api/v1/admin/zadaci');
  return [for (final z in r.data!) ZadatakRed.izJsona(z as Map<String, dynamic>)];
});

final biljeznicaProvider = FutureProvider.autoDispose.family<BiljeznicaIgra, String>((ref, slug) async {
  final r = await ref.watch(apiProvider).get<Map<String, dynamic>>('/api/v1/admin/biljeznice/$slug');
  return BiljeznicaIgra.izJsona(r.data!);
});

/// Jedan zadatak kao igra (pregled „Dijete rješava”), s naslovom zadatka.
final zadatakIgraProvider = FutureProvider.autoDispose.family<({String naslov, Igra igra}), int>((ref, id) async {
  final r = await ref.watch(apiProvider).get<Map<String, dynamic>>('/api/v1/admin/zadaci/$id');
  final j = r.data!;
  return (naslov: (j['zadatak'] as Map<String, dynamic>)['naslov'] as String, igra: Igra.izJsona(j));
});
