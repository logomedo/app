import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/core/konfig.dart';
import 'package:logomedo_app/core/modeli.dart';
import 'package:logomedo_app/core/pkce.dart';

sealed class StanjePrijave {
  const StanjePrijave();
}

class Ucitava extends StanjePrijave {
  const Ucitava();
}

class Odjavljen extends StanjePrijave {
  const Odjavljen([this.poruka]);
  final String? poruka;
}

class Prijavljen extends StanjePrijave {
  const Prijavljen(this.ja);
  final Ja ja;
}

/// Prijava kroz preglednik (docs/prijava.md): Custom Tab / ASWebAuthenticationSession otvori
/// logomedo.com/admin/app/prijava (Access OTP ili passkey), admin potvrdi, server vrati
/// jednokratni kod na shemu aplikacije, a aplikacija ga s PKCE verifikatorom zamijeni za token.
class Prijava extends Notifier<StanjePrijave> {
  @override
  StanjePrijave build() {
    unawaited(Future.microtask(_pokreni));
    return const Ucitava();
  }

  Tokeni get _tokeni => ref.read(tokeniProvider);

  Future<void> _pokreni() async {
    if (await _tokeni.ucitaj() == null) {
      state = const Odjavljen();
      return;
    }
    await _osvjeziJa();
  }

  Future<void> _osvjeziJa() async {
    try {
      final r = await ref.read(apiProvider).get<Map<String, dynamic>>('/api/v1/ja');
      state = Prijavljen(Ja.izJsona(r.data!));
    } on Object catch (e) {
      // 401 već je obrisao token (istekla); bez mreže ostaje token i poruka.
      if (state is! Odjavljen) state = Odjavljen(porukaGreske(e));
    }
  }

  Future<void> prijaviSe() async {
    final pkce = Pkce.novi();
    final url = Uri.parse('$apiUrl/admin/app/prijava').replace(
      queryParameters: {'izazov': pkce.izazov, 'metoda': 'S256', 'uredaj': await _oznakaUredaja()},
    );
    try {
      final povratak = await FlutterWebAuth2.authenticate(url: url.toString(), callbackUrlScheme: shemaPovratka);
      final kod = Uri.parse(povratak).queryParameters['kod'];
      if (kod == null) throw const FormatException('Povratak bez koda.');
      final r = await goliDio().post<Map<String, dynamic>>(
        '/api/v1/prijava/token',
        data: {'kod': kod, 'verifikator': pkce.verifikator},
      );
      await _tokeni.spremi(r.data!['token'] as String);
      await _osvjeziJa();
    } on PlatformException catch (e) {
      // CANCELED: korisnik je zatvorio preglednik.
      state = Odjavljen(e.code == 'CANCELED' ? null : 'Prijava nije uspjela (${e.code}).');
    } on Object catch (e) {
      state = Odjavljen('Prijava nije uspjela: ${porukaGreske(e)}');
    }
  }

  /// Samo debug i lokalni server: token iz `scripts/app-token.sh` (Access lokalno ne radi).
  Future<void> prijaviTokenom(String token) async {
    await _tokeni.spremi(token.trim());
    await _osvjeziJa();
  }

  Future<void> odjaviSe() async {
    try {
      await ref.read(apiProvider).post<void>('/api/v1/odjava');
    } on Object catch (_) {
      // Lokalna odjava vrijedi i bez mreže; sesija na serveru istječe sama.
    }
    await _tokeni.obrisi();
    state = const Odjavljen();
  }

  /// Server je vratio 401: token više ne vrijedi.
  void istekla() {
    if (state is Odjavljen) return;
    unawaited(_tokeni.obrisi());
    state = const Odjavljen('Prijava je istekla. Prijavi se ponovno.');
  }

  static Future<String> _oznakaUredaja() async {
    final d = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await d.androidInfo;
      return '${a.manufacturer} ${a.model}';
    }
    if (Platform.isIOS) return (await d.iosInfo).utsname.machine;
    return Platform.operatingSystem;
  }
}

final prijavaProvider = NotifierProvider<Prijava, StanjePrijave>(Prijava.new);
