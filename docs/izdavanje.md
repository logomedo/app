# Izdavanje (Android)

Nije još napravljeno ništa od ovoga; zapisano da se ne izgubi.

1. **Upload ključ** (jednom, čuva se izvan repoa, npr. u 1Password):
   ```bash
   keytool -genkey -v -keystore ~/keys/logomedo-upload.jks -keyalg RSA -keysize 4096 -validity 10000 -alias upload
   ```
   `android/key.properties` (gitignored):
   ```properties
   storeFile=/Users/ms/keys/logomedo-upload.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```
   Bez tog filea release se potpisuje debug ključem (`android/app/build.gradle.kts`).
2. **Play Console:** nova aplikacija `com.logomedo.app`, Play App Signing (Google drži ključ za
   potpis, mi samo upload ključ). Prvo interno testiranje, pa zatvoreno.
3. **Build:** `flutter build appbundle --release --dart-define-from-file=config/prod.json`.
   Verzija iz `pubspec.yaml` (`version: x.y.z+build`); build broj raste sa svakim uploadom.
   `MIN_BUILD_APLIKACIJE` na serveru diže se samo kad stari buildovi stvarno ne smiju dalje.
4. **Nakon prve objave:** SHA-256 ključa za potpis iz Play Consolea (App integrity) ide u
   `logomedo.com/public/.well-known/assetlinks.json`: preduvjet za App Links i native passkey
   (`logomedo.com/docs/app-api.md`, „Kasnije”).
5. Politika privatnosti na logomedo.com (Play je traži) i Data safety obrazac: aplikacija šalje
   e-mail admina i slike koje admin sam učita; nema analitike ni oglasa.

Mobilni ekrani se na Playu objavljuju tek kad ima smisla za korisnike (logopedi). Admin dio
može ostati na internom testiranju neograničeno.
