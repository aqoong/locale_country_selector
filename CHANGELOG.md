# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-02-26

### Added

- **Region affinity mapping:** Optional parameter `regionAffinityMap` (`Map<String, String>?`). When the locale's region is not in `supportedCountries`, the selector consults this map (e.g. `"GB"` → `"DE"`). If the mapped country is supported, it is returned. This avoids unintuitive outcomes like "UK user → US" when only language matching would apply.
- Normalization for `regionAffinityMap`: keys and values are trimmed and uppercased; empty entries are dropped.
- Explicit fallback rule when `fallbackCountry` is null: if no locale yields a match, the method now returns `null` (previously returned `supportedCountries.first`).

### Changed

- **Selection priority** (per locale, in order): (1) Exact region match → (2) Region affinity mapping → (3) Language match (single/multiple with champion or first in `supportedCountries`) → (4) Fallback (null / empty supported → fallback as-is; else supported check; else `supportedCountries.first`).
- **Locale extraction:** Region is derived from `Locale.toString()` only (`_extractRegion`) for compatibility across Flutter versions (no direct `countryCode`/`regionCode`). Language uses `Locale.languageCode` directly (`_extractLanguage`).
- **`LocaleCountrySelector.localeLanguageCode(Locale)`:** Return type changed from `String?` to `String`. Uses `Locale.languageCode` (non-null in Flutter); returns empty string when empty after trim.
- Internal `_selectCountryImpl` now accepts a normalized `regionAffinityMap` and applies it after exact region match and before language match.
- README and dartdocs updated with region affinity step, examples, and fallback behavior.

### Testing

- New tests: region affinity (supported [DE, US] + en-GB with/without map), map to unsupported country (ignore and continue), key normalization (`" gb "` → `"GB"`), and `fallbackCountry: null` returning null.
- All existing tests retained and passing.

## [0.1.0] - 2025-02-25

### Added

- Initial release.
- `LocaleCountrySelector.selectCountry()` for deterministic country selection from OS locales only.
- Support for `supportedCountries`, `locales`, `countryLanguages`, `languageChampion`, and `fallbackCountry`.
- Selection priority: exact region match → language match (with champion) → fallback.
- Input normalization (uppercase country codes, lowercase language codes).
- Unit tests covering edge cases.
- Example Flutter app (Android/iOS) showing device locales and selected country.
- README with usage, algorithm description, and configuration tips.
