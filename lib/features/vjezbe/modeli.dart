// Modeli vježbenica: GET /api/v1/admin/biljeznice[/{slug}] i /api/v1/admin/zadaci[/{id}]
// (logomedo.com docs/app-api.md). Zadatak je JSON vrste (logomedo.com docs/zadaci.md);
// aplikacija dobiva i `ekrani` koje server već razloži kao igra u pregledniku.

import 'package:logomedo_app/core/konfig.dart';

/// Relativna adresa (lokalni `/cdn/…`) ide na naš server, apsolutna (CDN) ostaje.
String punaAdresa(String url) => url.startsWith('/') ? '$apiUrl$url' : url;

enum Orijentacija { uspravno, vodoravno }

class SlikaPozadine {
  SlikaPozadine.izJsona(Map<String, dynamic> j)
      : url = punaAdresa(j['url'] as String),
        sirina = j['sirina'] as int,
        visina = j['visina'] as int;
  final String url;
  final int sirina;
  final int visina;
}

class Pozadina {
  Pozadina.izJsona(Map<String, dynamic> j)
      : id = j['id'] as int,
        naziv = j['naziv'] as String,
        uspravno = j['uspravno'] == null ? null : SlikaPozadine.izJsona(j['uspravno'] as Map<String, dynamic>),
        vodoravno = j['vodoravno'] == null ? null : SlikaPozadine.izJsona(j['vodoravno'] as Map<String, dynamic>);
  final int id;
  final String naziv;
  final SlikaPozadine? uspravno;
  final SlikaPozadine? vodoravno;

  /// Tražena orijentacija, inače ona koja postoji (`tocna: false` → prikaz s obrubom).
  ({SlikaPozadine slika, bool tocna})? za(Orijentacija o) {
    final trazena = o == Orijentacija.uspravno ? uspravno : vodoravno;
    final druga = o == Orijentacija.uspravno ? vodoravno : uspravno;
    if (trazena != null) return (slika: trazena, tocna: true);
    return druga == null ? null : (slika: druga, tocna: false);
  }
}

/// Riječ s odobrenom slikom (CDN, bez tokena) ili bez slike (prikazuje se riječ).
class RijecPrikaz {
  RijecPrikaz.izJsona(Map<String, dynamic> j)
      : id = j['id'] as int,
        rijec = j['rijec'] as String,
        slika = j['slika'] == null ? null : punaAdresa(j['slika'] as String);
  final int id;
  final String rijec;
  final String? slika;
}

class GumbScene {
  GumbScene({required this.i, required this.rijecId, required this.tocno});
  /// Indeks u `sadrzaj.gumbi` (odgovori se bilježe po njemu).
  final int i;
  final int rijecId;
  final bool tocno;
}

/// Sadržaj vrste `scena`. Gumbi bez riječi se ne prikazuju (kao na webu).
class Scena {
  Scena.izJsona(Map<String, dynamic> j)
      : pozadinaId = j['pozadina_id'] as int?,
        gumbi = [
          for (final (i, g) in (j['gumbi'] as List).indexed)
            if ((g as Map<String, dynamic>)['rijec_id'] != null)
              GumbScene(i: i, rijecId: g['rijec_id'] as int, tocno: g['tocno'] == true),
        ];
  final int? pozadinaId;
  final List<GumbScene> gumbi;
}

/// Jedan ekran igre. Aplikacija zasad crta samo scenu; ostale vrste imaju zamjenski ekran.
class Ekran {
  Ekran.izJsona(Map<String, dynamic> j)
      : vrsta = j['vrsta'] as String,
        uputa = j['uputa'] as String,
        scena = j['vrsta'] == 'scena' ? Scena.izJsona(j['s'] as Map<String, dynamic>) : null;
  final String vrsta;
  final String uputa;
  final Scena? scena;
}

/// Ekrani i sve što trebaju za crtanje (riječi, pozadine).
class Igra {
  Igra.izJsona(Map<String, dynamic> j)
      : ekrani = [for (final e in j['ekrani'] as List) Ekran.izJsona(e as Map<String, dynamic>)],
        rijeci = {for (final r in j['rijeci'] as List) (r as Map<String, dynamic>)['id'] as int: RijecPrikaz.izJsona(r)},
        pozadine = {for (final p in j['pozadine'] as List) (p as Map<String, dynamic>)['id'] as int: Pozadina.izJsona(p)};
  final List<Ekran> ekrani;
  final Map<int, RijecPrikaz> rijeci;
  final Map<int, Pozadina> pozadine;
}

class BiljeznicaRed {
  BiljeznicaRed.izJsona(Map<String, dynamic> j)
      : slug = j['slug'] as String,
        naslov = j['naslov'] as String,
        podnaslov = j['podnaslov'] as String?,
        tema = j['tema'] as String,
        javna = j['javna'] as bool,
        zadataka = j['zadataka'] as int;
  final String slug;
  final String naslov;
  final String? podnaslov;
  final String tema;
  final bool javna;
  final int zadataka;
}

class ZadatakRed {
  ZadatakRed.izJsona(Map<String, dynamic> j)
      : id = j['id'] as int,
        vrsta = j['vrsta'] as String,
        naslov = j['naslov'] as String,
        uputa = j['uputa'] as String?;
  final int id;
  final String vrsta;
  final String naslov;
  final String? uputa;
}

/// Bilježnica za igru: naslov, tema (tekst na kraju, boja) i ekrani.
class BiljeznicaIgra {
  BiljeznicaIgra.izJsona(Map<String, dynamic> j)
      : naslov = (j['biljeznica'] as Map<String, dynamic>)['naslov'] as String,
        kraj = (j['tema'] as Map<String, dynamic>)['kraj'] as String,
        boja = (j['tema'] as Map<String, dynamic>)['boja'] as String,
        igra = Igra.izJsona(j);
  final String naslov;
  final String kraj;
  final String boja;
  final Igra igra;
}
