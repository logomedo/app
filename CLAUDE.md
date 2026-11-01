# app (LogoMedo, Flutter)

Android i iOS aplikacija. Server je Worker u `../logomedo.com`; aplikacija govori samo s
`/api/v1` (ugovor: `../logomedo.com/docs/app-api.md`). Radni prostor: `../CLAUDE.md`.

- Arhitektura i dugoročne odluke: `docs/arhitektura.md`. Izdavanje: `docs/izdavanje.md`.
- Imena u kodu i UI-ju su hrvatska (kao na webu).
- `applicationId`/bundle `com.logomedo.app` je i shema povratka prijave: ne mijenjati.
- Repo je javni klijent: nikakve tajne, e-mailovi ni tokeni u kodu ili configu.
- Prije commita: `flutter analyze && flutter test`.
- Lokalno: `flutter run --dart-define-from-file=config/dev.json` uz `wrangler dev --port 8787`,
  `adb reverse tcp:8787 tcp:8787` i token iz `../logomedo.com/scripts/app-token.sh`.
- Produkcija: `--dart-define-from-file=config/prod.json` (zadano i bez njega).
