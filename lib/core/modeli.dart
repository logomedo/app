// Modeli ugovora /api/v1 (logomedo.com docs/app-api.md). Imena polja kao u JSON-u.

class Ja {
  Ja({required this.email, required this.uloga, required this.api, required this.minBuild, this.uredaj});
  factory Ja.izJsona(Map<String, dynamic> j) => Ja(
        email: j['email'] as String,
        uloga: j['uloga'] as String,
        uredaj: j['uredaj'] as String?,
        api: j['api'] as int,
        minBuild: j['min_build'] as int,
      );
  final String email;
  final String uloga;
  final String? uredaj;
  final int api;
  final int minBuild;
  bool get admin => uloga == 'admin';
}

class Stil {
  Stil(this.kod, this.naziv);
  factory Stil.izJsona(Map<String, dynamic> j) => Stil(j['kod'] as String, j['naziv'] as String);
  final String kod;
  final String naziv;
}

class GlasPregled {
  GlasPregled.izJsona(Map<String, dynamic> j)
      : oznaka = j['oznaka'] as String,
        slug = j['slug'] as String,
        skupina = j['skupina'] as String?,
        rijeci = j['rijeci'] as int,
        odobreno = j['odobreno'] as int,
        kandidata = j['kandidata'] as int,
        uRedu = j['uRedu'] as int;
  final String oznaka;
  final String slug;
  final String? skupina;
  final int rijeci;
  final int odobreno;
  final int kandidata;
  final int uRedu;
}

class Katalog {
  Katalog.izJsona(Map<String, dynamic> j)
      : stil = j['stil'] as String,
        stilovi = [for (final s in j['stilovi'] as List) Stil.izJsona(s as Map<String, dynamic>)],
        glasovi = [for (final g in j['glasovi'] as List) GlasPregled.izJsona(g as Map<String, dynamic>)],
        rijeci = (j['ukupno'] as Map<String, dynamic>)['rijeci'] as int,
        odobreno = (j['ukupno'] as Map<String, dynamic>)['odobreno'] as int,
        kandidata = (j['ukupno'] as Map<String, dynamic>)['kandidata'] as int;
  final String stil;
  final List<Stil> stilovi;
  final List<GlasPregled> glasovi;
  final int rijeci;
  final int odobreno;
  final int kandidata;
}

/// Pozicija glasa u riječi; redoslijed kao na webu.
const pozicije = ['inicijalna', 'medijalna', 'finalna', 'skupina'];
const naziviPozicija = {'inicijalna': 'Inicijalna', 'medijalna': 'Medijalna', 'finalna': 'Finalna', 'skupina': 'Skupine'};

class RijecRed {
  RijecRed.izJsona(Map<String, dynamic> j)
      : id = j['id'] as int,
        rijec = j['rijec'] as String,
        slug = j['slug'] as String,
        pozicija = j['pozicija'] as String,
        odobrenaId = j['odobrena_id'] as int?,
        kandidata = j['kandidata'] as int,
        uRedu = j['u_redu'] as int;
  final int id;
  final String rijec;
  final String slug;
  final String pozicija;
  final int? odobrenaId;
  final int kandidata;
  final int uRedu;
}

class GlasRijeci {
  GlasRijeci.izJsona(Map<String, dynamic> j)
      : oznaka = (j['glas'] as Map<String, dynamic>)['oznaka'] as String,
        rijeci = [for (final r in j['rijeci'] as List) RijecRed.izJsona(r as Map<String, dynamic>)];
  final String oznaka;
  final List<RijecRed> rijeci;
}

/// Stavka indeksa za tražilicu: r = riječ, s = slug, o = ima odobrenu, k = kandidata.
class StavkaIndeksa {
  StavkaIndeksa.izJsona(Map<String, dynamic> j)
      : rijec = j['r'] as String,
        slug = j['s'] as String,
        odobrena = j['o'] == 1,
        kandidata = j['k'] as int;
  final String rijec;
  final String slug;
  final bool odobrena;
  final int kandidata;
}

class Slika {
  Slika.izJsona(Map<String, dynamic> j)
      : id = j['id'] as int,
        status = j['status'] as String,
        razlog = j['razlog'] as String?,
        prompt = j['prompt'] as String?,
        model = j['model'] as String?,
        izvor = j['izvor'] as String,
        url = j['url'] as String,
        cdn = j['cdn'] as String?;
  final int id;
  final String status;
  final String? razlog;
  final String? prompt;
  final String? model;
  final String izvor;
  final String url;
  final String? cdn;
}

class Pozicija {
  Pozicija.izJsona(Map<String, dynamic> j)
      : oznaka = j['oznaka'] as String,
        pozicija = j['pozicija'] as String,
        potvrdeno = j['potvrdeno'] == 1;
  final String oznaka;
  final String pozicija;
  final bool potvrdeno;
}

class RijecDetalj {
  RijecDetalj.izJsona(Map<String, dynamic> j)
      : id = j['id'] as int,
        rijec = j['rijec'] as String,
        slug = j['slug'] as String,
        opisZaSliku = j['opis_za_sliku'] as String?,
        recenica = j['recenica'] as String?,
        pozicije = [for (final p in j['pozicije'] as List) Pozicija.izJsona(p as Map<String, dynamic>)],
        slike = [for (final s in j['slike'] as List) Slika.izJsona(s as Map<String, dynamic>)],
        uRedu = (j['red'] as List).length;
  final int id;
  final String rijec;
  final String slug;
  final String? opisZaSliku;
  final String? recenica;
  final List<Pozicija> pozicije;
  final List<Slika> slike;
  final int uRedu;
}
