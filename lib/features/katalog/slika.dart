import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/core/konfig.dart';

/// Slika kataloga: odobrena s CDN-a (javno), ostale kroz API s tokenom. Ključ sadrži hash
/// sadržaja, pa je keš na uređaju trajan.
class SlikaKataloga extends ConsumerWidget {
  const SlikaKataloga({required this.url, this.cdn, this.fit = BoxFit.contain, super.key});

  /// Putanja slike na API-ju (npr. `/api/v1/admin/slike/12`).
  factory SlikaKataloga.poId(int id, {BoxFit fit = BoxFit.contain, Key? key}) =>
      SlikaKataloga(url: '/api/v1/admin/slike/$id', fit: fit, key: key);

  final String url;
  final String? cdn;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final javno = cdn != null;
    return ColoredBox(
      color: Colors.white,
      child: CachedNetworkImage(
        imageUrl: javno ? cdn! : '$apiUrl$url',
        httpHeaders: javno ? null : zaglavljaSlike(ref.read(tokeniProvider)),
        // Isti ključ za obje adrese: kad slika postane odobrena, ne skida se ponovno.
        cacheKey: url,
        fit: fit,
        placeholder: (_, _) => const Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
