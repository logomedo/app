# Prvi test na uređajima (1. 11. 2026.)

## Što je potvrđeno

| Uređaj | Server | Što je prošlo |
|---|---|---|
| motorola edge 30 ultra (USB, `ZY22G9DDR3`) | lokalni `wrangler dev` (`adb reverse tcp:8787`) | dev token, katalog, glas, tražilica, riječ, slike iz privatnog R2, upload kroz Photo Picker, odobravanje |
| motorola edge 30 ultra | produkcija | Custom Tab otvara logomedo.com/admin/login (prijava nije dovršena, nitko nije bio uz telefon) |
| Xiaomi 17 Ultra (`2512BPNDAG`, preko Tailscalea) | produkcija | **cijela prijava**: web sesija u pregledniku → „Potvrdi prijavu” → shema `com.logomedo.app` → token. U D1 `app_sesije` red s uređajem „Xiaomi 2512BPNDAG”, kod potrošen |

Prijava preuzima onoga tko je već prijavljen u pregledniku na uređaju. Na Xiaomiju je to bila
Anitina passkey sesija od istog jutra, pa aplikacija radi kao ona (i dnevnik aktivnosti je bilježi kao nju).

## Bugovi nađeni testom (popravljeni u 6954e42)

- Kartica glasa se prelijevala 8 px kad ima redak „N za pregled” (`childAspectRatio` 1.1 → 0.95).
- Oznaka uploada bila je bijela ikona na bijeloj slici; sad je u krugu boje površine.
- Gumbi Odbij/Odobri u donjem sheetu bili su ispod Androidove navigacijske trake: klik je otvarao
  nedavne aplikacije. Sheet sad dodaje `MediaQuery.paddingOf(context).bottom` i `useSafeArea`.

Pouka: edge-to-edge na Androidu 15+ znači da svaki donji sheet i FAB treba provjeriti na pravom
uređaju s gestama ili tipkama, ne samo u emulatoru.

## Instalacija na uređaj bez USB-a

- **Taildrop (`tailscale file cp`) na Android ne radi pouzdano**: dva pokušaja (55 MB i 19 MB) zapela
  su na ~1 MB, preko DERP relaya i izravno. Odbačeno.
- **Radi:** obični HTTP server vezan samo na Tailscale IP Maca, link poslan sebi na mobitel:
  ```bash
  python3 -m http.server 8765 --bind <tailscale-ip-maca>   # iz mape s APK-om
  # na telefonu: http://<tailscale-ip-maca>:8765/LogoMedo.apk (samo s uključenim Tailscaleom)
  ```
  Ugasiti nakon instalacije.
- **APK za jedan ABI**: `flutter build apk --release --split-per-abi --target-platform android-arm64
  --dart-define-from-file=config/prod.json` → 18,9 MB umjesto 54,7 MB (svi ABI-ji).
- Release je zasad potpisan debug ključem (nema `android/key.properties`), pa Play Protect upozorava.
  Instalacija preko starijeg buildа radi samo dok je potpis isti.
- Za stalni rad na Xiaomiju: bežični adb preko Tailscalea (Wireless debugging → Pair with code, na
  HyperOS-u i „Install via USB” + „USB debugging (Security settings)”). Još nije upareno.

## Emulator

Ne radi dok DOMOVINA1TB nije spojen: `~/Library/Android/sdk/system-images` je symlink na njega, a
interni disk je ~98 % pun (11 GB slobodno). Pravi telefoni su zato prvi izbor; Motorole imaju PIN,
otključavanje je `~/.claude/scripts/android_otkljucaj.sh` (PIN u `~/.config/android-unlock/pin`).

## Vezani dokumenti

- [arhitektura.md](arhitektura.md), [izdavanje.md](izdavanje.md)
- `logomedo.com/docs/app-api.md` (ugovor i tok prijave)
