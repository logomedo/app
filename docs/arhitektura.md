# Arhitektura aplikacije

Odluka 1. 11. 2026.: native aplikacija u **Flutteru**, paralelno s webom (logomedo.com).
Prvo admin kataloga (riječi i slike), kasnije interaktivne vježbenice za logopede.

## Zašto Flutter

- **Vježbenice se crtaju jednom za Android i iOS.** Vrsta zadatka (povezivanje, uljez, bojanje,
  rime…) je jedan renderer koji iz podataka crta zadatak; Impeller crta isto na obje platforme.
  Compose + SwiftUI bi značio svaku vrstu dvaput, s različitim Canvasom i gestama.
- Model sadržaja to već pretpostavlja (`logomedo.com/docs/zadaci.md`): **vrsta zadatka =
  predložak u kodu, zadatak = podaci (JSON)**.
- Odbačeno: Compose + SwiftUI (dvostruko održavanje vježbenica), Capacitor/WebView (naslijedi
  ograničenja weba i Access prijavu u WebViewu), React Native (bez prednosti uz Flutter iskustvo).
  Compose Multiplatform bio bi jedina ozbiljna alternativa (isto Skia na iOS-u).

## Što se gdje radi

| | Web (logomedo.com) | Aplikacija |
|---|---|---|
| Admin kataloga | da (puni) | da: pregled, upload iz galerije, odluke |
| Zadaci, bilježnice (editor) | da | ne zasad |
| A4 ispis | da | ne (ostaje web) |
| Dijeljeni link za igru (`/b/<slug>`) | da | ne |
| Vježbenice s djetetom, snimanje izgovora, offline | ne | da (kasnije) |

Server je jedan: Worker na logomedo.com. Aplikacija govori samo s `/api/v1`
(`logomedo.com/docs/app-api.md`) i nikad s D1 ili R2 izravno.

## Struktura koda

```
lib/
  main.dart
  app/        app.dart (MaterialApp.router), router.dart (go_router + redirect po prijavi), tema.dart
  core/       konfig.dart (API_URL), api.dart (Dio + token), prijava.dart (PKCE), modeli.dart, pkce.dart
  features/
    prijava/  ekran prijave
    katalog/  glasovi, glas, riječ, upload, tražilica, slika (keš)
    (vjezbe/  kasnije: renderer po vrsti zadatka, sesija s djetetom, snimanje)
```

- **Stanje:** Riverpod 3 (bez code-gena). Provideri po ekranu (`FutureProvider.autoDispose.family`),
  radnje u klasi (`KatalogRadnje`), nakon radnje `invalidate`.
- **Navigacija:** go_router; `redirect` ovisi o `prijavaProvider` (Učitava → Odjavljen → Prijavljen).
  Kad dođe uloga `logoped`, početna ruta se bira po ulozi; admin rute ostaju pod `/`.
- **Mreža:** Dio, jedan klijent s interceptorom (bearer, 401 → odjava). Modeli rukom
  (`modeli.dart`), polja kao u JSON-u. Kad API naraste: OpenAPI na serveru i generirani klijent.
- **Slike:** `cached_network_image`, ključ keša = API putanja slike. Odobrene idu s
  `cdn.logomedo.com` bez tokena, ostale kroz API s tokenom. Ključ u R2 sadrži hash, pa je keš trajan.
- **Tajne:** token u `flutter_secure_storage` (Android Keystore / iOS Keychain), nikad u logu.
- **Konfiguracija:** `--dart-define-from-file=config/prod.json` ili `config/dev.json`. Nema tajni u
  repou: aplikacija je javni klijent, sigurnost je na serveru.

## Galerija i fotografije

Zasad sistemski **Photo Picker** (`image_picker`): pregled slika, bez dozvole za cijelu galeriju.
Vlastita mreža galerije unutar aplikacije (`photo_manager`) traži `READ_MEDIA_IMAGES`, a Play to
dopušta samo aplikacijama kojima je galerija glavna funkcija, pa bi admin aplikacija riskirala
odbijanje. Između toga je *embedded photo picker* (Android 14+, `androidx.photopicker`): picker
ugrađen u naš ekran, bez dozvole. Za njega treba mali vlastiti plugin; vrijedi kad upload postane
čest posao.

## Kasnije, s vježbenicama

- **Renderer po vrsti zadatka:** widgeti (`Stack`, `Draggable`/`DragTarget`, implicitne animacije)
  za većinu, `CustomPainter` samo gdje se stvarno crta (crte kod povezivanja, bojanje, trag).
  Flame za vježbe nalik igri, Rive za animirane likove.
- **Fontovi u aplikaciji** (Nunito/Inter/Fraunces kao web), ne sistemski: tek tada je tekst
  identičan na obje platforme. Zasad sistemski font.
- **Snimanje izgovora:** `record` (AAC/Opus), upload u R2 kroz API, red uploada koji preživi
  gubitak mreže. Dijete nema račun; snimka pripada rješavanju (tablice već postoje, `zadaci.md`).
- **Offline:** lokalna baza (drift/SQLite) za zadatke i rješavanja, sinkronizacija kad ima mreže.
- **Uloga `logoped`:** računi u D1, ista prijava kroz preglednik; admin rute skrivene po ulozi,
  server svejedno provjerava.
- **iOS:** projekt postoji (`ios/`, bundle `com.logomedo.app`), nije buildan. Treba Apple
  Developer račun i potpis; prijava radi preko `ASWebAuthenticationSession` bez dodatne
  konfiguracije sheme.

## Identitet

- `applicationId` / bundle id: **`com.logomedo.app`**. Ne mijenja se nakon prve objave.
- Ista vrijednost je shema povratka prijave (`com.logomedo.app://prijava`), u `AndroidManifest.xml`,
  `lib/core/konfig.dart` i na serveru (`src/pages/admin/api/app-kod.ts`).

## Vezani dokumenti

- [2026-11-01-prvi-test-na-uredajima.md](2026-11-01-prvi-test-na-uredajima.md): što je potvrđeno na
  uređajima, bugovi, instalacija bez USB-a (Taildrop ne radi, HTTP na Tailscale IP radi)
- [izdavanje.md](izdavanje.md), `logomedo.com/docs/app-api.md`
