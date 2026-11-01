/// Adresa servera iz `--dart-define-from-file=config/<okolina>.json`.
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://logomedo.com');

/// Verzija ugovora /api/v1 koju ova aplikacija razumije (logomedo.com src/lib/app/api.ts).
const apiVerzija = 1;

/// Shema povratka prijave: ista kao applicationId i APP_POVRATAK na serveru.
const shemaPovratka = 'com.logomedo.app';

bool get lokalniServer => Uri.parse(apiUrl).host == 'localhost';
