# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
