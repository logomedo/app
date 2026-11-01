import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/core/modeli.dart';

/// Odabrani stil slika (bojanka, ilustracija…), zajednički za sve ekrane kataloga.
class OdabraniStil extends Notifier<String> {
  @override
  String build() => 'bojanka';
  void postavi(String kod) => state = kod;
}

final stilProvider = NotifierProvider<OdabraniStil, String>(OdabraniStil.new);

final katalogProvider = FutureProvider.autoDispose<Katalog>((ref) async {
  final stil = ref.watch(stilProvider);
  final r = await ref.watch(apiProvider).get<Map<String, dynamic>>('/api/v1/admin/katalog', queryParameters: {'stil': stil});
  return Katalog.izJsona(r.data!);
});

final glasProvider = FutureProvider.autoDispose.family<GlasRijeci, String>((ref, slug) async {
  final stil = ref.watch(stilProvider);
  final r = await ref.watch(apiProvider).get<Map<String, dynamic>>('/api/v1/admin/glasovi/$slug', queryParameters: {'stil': stil});
  return GlasRijeci.izJsona(r.data!);
});

final rijecProvider = FutureProvider.autoDispose.family<RijecDetalj, String>((ref, slug) async {
  final r = await ref.watch(apiProvider).get<Map<String, dynamic>>('/api/v1/admin/rijeci/$slug');
  return RijecDetalj.izJsona(r.data!);
});

final indeksProvider = FutureProvider.autoDispose<List<StavkaIndeksa>>((ref) async {
  final r = await ref.watch(apiProvider).get<List<dynamic>>('/api/v1/admin/rijeci');
  return [for (final s in r.data!) StavkaIndeksa.izJsona(s as Map<String, dynamic>)];
});

/// Radnje nad katalogom (upload, odluka). Nakon njih pozivatelj invalidira providere.
class KatalogRadnje {
  KatalogRadnje(this._dio);
  final Dio _dio;

  Future<int> ucitajSliku({
    required int rijecId,
    required String putanja,
    required String mime,
    required String stil,
    required String prompt,
    String? alat,
    void Function(double)? napredak,
  }) async {
    final forma = FormData.fromMap({
      'slika': await MultipartFile.fromFile(putanja, contentType: DioMediaType.parse(mime)),
      'stil': stil,
      'prompt': prompt,
      if (alat != null && alat.isNotEmpty) 'alat': alat,
    });
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/v1/admin/rijeci/$rijecId/slike',
      data: forma,
      onSendProgress: (poslano, ukupno) => napredak?.call(ukupno > 0 ? poslano / ukupno : 0),
    );
    return r.data!['slika_id'] as int;
  }

  /// akcija: odobri | odbij | vrati. Vraća poruku ako je netko drugi već odlučio.
  Future<String?> odluci(int slikaId, String akcija, {String? razlog, bool ponovi = false}) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/v1/admin/slike/$slikaId/odluka',
      data: {'akcija': akcija, 'razlog': ?razlog, 'ponovi': ponovi},
      options: Options(validateStatus: (s) => s != null && (s < 300 || s == 409)),
    );
    final vec = r.data?['vec'] as Map<String, dynamic>?;
    return vec == null ? null : 'Već ${vec['status']} (${vec['pregledao'] ?? 'netko'}).';
  }
}

final katalogRadnjeProvider = Provider((ref) => KatalogRadnje(ref.watch(apiProvider)));
