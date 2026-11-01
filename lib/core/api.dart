import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logomedo_app/core/konfig.dart';
import 'package:logomedo_app/core/prijava.dart';

/// Token u memoriji i u Keystoreu/Keychainu (flutter_secure_storage). Nikad u logu.
class Tokeni {
  Tokeni(this._pohrana);
  final FlutterSecureStorage _pohrana;
  static const _kljuc = 'api_token';
  String? token;

  Future<String?> ucitaj() async => token = await _pohrana.read(key: _kljuc);
  Future<void> spremi(String t) async {
    token = t;
    await _pohrana.write(key: _kljuc, value: t);
  }

  Future<void> obrisi() async {
    token = null;
    await _pohrana.delete(key: _kljuc);
  }
}

final tokeniProvider = Provider((ref) => Tokeni(const FlutterSecureStorage()));

BaseOptions _osnovno() => BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'x-logomedo-api': '$apiVerzija'},
    );

/// Bez tokena: samo za zamjenu koda (prijava).
Dio goliDio() => Dio(_osnovno());

/// Klijent za /api/v1: bearer token, a 401 vraća na prijavu.
final apiProvider = Provider<Dio>((ref) {
  final dio = Dio(_osnovno());
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) {
        final t = ref.read(tokeniProvider).token;
        if (t != null) o.headers['authorization'] = 'Bearer $t';
        h.next(o);
      },
      onError: (e, h) {
        if (e.response?.statusCode == 401) ref.read(prijavaProvider.notifier).istekla();
        h.next(e);
      },
    ),
  );
  return dio;
});

/// Zaglavlja za sliku iz privatnog dijela API-ja (CachedNetworkImage).
Map<String, String> zaglavljaSlike(Tokeni tokeni) {
  final t = tokeni.token;
  return t == null ? const {} : {'authorization': 'Bearer $t'};
}

/// Poruka greške za korisnika: server vraća `{error}`, inače opća poruka.
String porukaGreske(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['error'] is String) return d['error'] as String;
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Nema veze sa serverom.';
    }
    return 'Greška ${e.response?.statusCode ?? ''}'.trim();
  }
  return e.toString();
}
