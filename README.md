# locale_country_selector

Deterministic country auto-selection using **only** the device's OS locales (language + region). No GPS, IP, SIM, telephony, network, or any permissioned APIs.

**Supported platforms:** Android and iOS (Flutter mobile only). The implementation is pure Dart with no platform channels, so behavior is consistent across both platforms.

## What this package does

- Takes a list of **supported country codes** and the device's **preferred locales** (e.g. from `PlatformDispatcher.locales`).
- Selects **one** country from the supported list that best matches the user's locale preferences.
- Uses only **language** and **region** from the OS; no location or network data.

## What this package does NOT do

- **Does not** use GPS, IP geolocation, SIM country, telephony, or network APIs.
- **Does not** require any permissions (location, network, etc.).
- **Does not** support web or desktop; it is intended for Android and iOS only.

## Selection algorithm (priority)

For each locale in the preferred locales list, in order:

1. **Exact region match:** If the locale's region code (from `Locale`, e.g. "en_US" → "US") is in `supportedCountries`, return that country.
2. **Region affinity mapping:** If the region is not supported, `regionAffinityMap` is consulted (e.g. `"GB"` → `"DE"`). If the mapped country is supported, return it. This helps avoid unintuitive outcomes like "UK user → US" when only language matching would apply—e.g. supported `[DE, US]`, locale `en-GB` → with `regionAffinityMap: {'GB': 'DE'}` you get `DE` instead of `US`.
3. **Language match:** Find all supported countries whose `countryLanguages` list contains the locale's language code.
   - If exactly one match → return it.
   - If multiple matches:
     - If `languageChampion` has an entry for this language and that country is supported → return the champion.
     - Otherwise → return the first match according to the original `supportedCountries` order.
4. **Fallback:** If no locale yields a match:
   - If `fallbackCountry` is null → return null.
   - If `supportedCountries` is empty → return `fallbackCountry` as-is.
   - If `fallbackCountry` is in `supportedCountries` → return it.
   - Otherwise → return the first item in `supportedCountries`.

Inputs are normalized: country/region codes to uppercase, language codes to lowercase. `regionAffinityMap` keys and values are normalized the same way.

## Usage

```dart
import 'package:flutter/widgets.dart';
import 'package:locale_country_selector/locale_country_selector.dart';

// From your Flutter app (e.g. in initState or when building):
final locales = WidgetsBinding.instance.platformDispatcher.locales;

final country = LocaleCountrySelector.selectCountry(
  supportedCountries: ['KR', 'US'],
  locales: locales,
  countryLanguages: {
    'KR': ['ko'],
    'US': ['en'],
  },
  languageChampion: {'en': 'US', 'ko': 'KR'},
  fallbackCountry: 'US',
);
// country is e.g. 'US' or 'KR'
```

With **region affinity** (e.g. UK users → DE when you support DE and US):

```dart
final country = LocaleCountrySelector.selectCountry(
  supportedCountries: ['DE', 'US'],
  locales: [const Locale('en', 'GB')],
  countryLanguages: {'DE': ['en', 'de'], 'US': ['en']},
  languageChampion: {'en': 'US'},
  regionAffinityMap: {'GB': 'DE'},
  fallbackCountry: 'US',
);
// Returns 'DE' (en-GB region mapped to DE); without the map it would be 'US' (the English champion).
```

## Configuration tips

### countryLanguages

- Map each **supported** country code to the list of BCP-47 primary language subtags (e.g. `"en"`, `"ko"`, `"fr"`) that your app supports for that country.
- Include only languages you actually support; the selector will not choose a country for a language that isn’t in any list.

### regionAffinityMap

- Maps **unsupported** region codes to **supported** country codes (e.g. `'GB': 'DE'`).
- Applied after exact region match and before language match. If the user's region (e.g. GB) is not in `supportedCountries`, the selector checks this map; if the mapped country (e.g. DE) is supported, that country is returned. This avoids "UK user → US" when you prefer another market (e.g. DE) for that region.

### languageChampion

- When several supported countries share the same language (e.g. US, GB, AU for English), the champion tells the selector which one to prefer.
- Use it to match your product’s default or primary market (e.g. `'en': 'US'` if US English is default).

### Common pitfalls

- **Forgetting to pass device locales:** Always use `WidgetsBinding.instance.platformDispatcher.locales` (or equivalent) so the selection reflects the user’s system preferences.
- **Champion not in supported list:** If `languageChampion[language]` is not in `supportedCountries`, that champion is ignored and the first matching country in `supportedCountries` order is used.
- **Empty or missing countryLanguages:** If a supported country has no (or empty) languages, it can only be chosen by exact region match or as fallback.

## Example app

Run the example (Android/iOS):

```bash
fvm flutter pub get
cd example && fvm flutter run
```

The example shows the device’s preferred locales and the selected country using `supportedCountries: ['KR', 'US']`.

## Testing

```bash
fvm flutter test
fvm flutter analyze
```

## License

BSD 3-Clause. See [LICENSE](LICENSE).
