/// Deterministic country auto-selection using only OS locales (language + region).
/// No GPS, IP, SIM, or permissioned APIs. Android and iOS, pure Dart.
library locale_country_selector;

import 'package:flutter/widgets.dart' show Locale;

import 'src/locale_pair.dart';

List<String> _normalizeCountryList(List<String> list) {
  return list
      .map((s) => s.trim().toUpperCase())
      .where((s) => s.isNotEmpty)
      .toList();
}

Map<String, List<String>> _normalizeCountryLanguages(
  Map<String, List<String>> map,
) {
  final result = <String, List<String>>{};
  for (final e in map.entries) {
    final key = e.key.trim().toUpperCase();
    if (key.isEmpty) continue;
    final langs = e.value
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();
    if (langs.isNotEmpty) result[key] = langs;
  }
  return result;
}

Map<String, String> _normalizeLanguageChampion(Map<String, String> map) {
  final result = <String, String>{};
  for (final e in map.entries) {
    final lang = e.key.trim().toLowerCase();
    final country = e.value.trim().toUpperCase();
    if (lang.isNotEmpty && country.isNotEmpty) result[lang] = country;
  }
  return result;
}

/// Normalizes region affinity map: keys and values trim + uppercase; drop empties.
Map<String, String> _normalizeRegionAffinityMap(Map<String, String> map) {
  final result = <String, String>{};
  for (final e in map.entries) {
    final key = e.key.trim().toUpperCase();
    final value = e.value.trim().toUpperCase();
    if (key.isNotEmpty && value.isNotEmpty) result[key] = value;
  }
  return result;
}

String? _normalizeCountry(String? s) {
  final v = s?.trim().toUpperCase();
  return (v == null || v.isEmpty) ? null : v;
}

/// Extracts region (country code equivalent) from [Locale] via toString().
/// Handles "en_US", "en-US", "en_US_POSIX". Returns alpha-2 uppercase or M49.
String? _extractRegion(Locale l) {
  final s = l.toString().trim();
  if (s.isEmpty) return null;
  final parts = s.split(RegExp('[-_]'));
  if (parts.length < 2) return null;
  final candidate = parts[1];
  final isAlpha2 = RegExp(r'^[A-Za-z]{2}$').hasMatch(candidate);
  if (isAlpha2) return candidate.toUpperCase();
  final isM49 = RegExp(r'^\d{3}$').hasMatch(candidate);
  if (isM49) return candidate;
  return null;
}

/// Extracts and normalizes language code from [Locale].
/// Uses [Locale.languageCode] (non-null in Flutter). Returns empty string if empty after trim.
String _extractLanguage(Locale l) {
  final s = l.languageCode.trim().toLowerCase();
  return s;
}

String? _selectCountryImpl({
  required List<String> supportedCountries,
  required List<LocalePair> localePairs,
  required Map<String, List<String>> countryLanguages,
  required Map<String, String> languageChampion,
  required Map<String, String> regionAffinityMap,
  required String? fallbackCountry,
}) {
  for (final pair in localePairs) {
    // 1) Exact region match
    if (pair.regionCode != null &&
        supportedCountries.contains(pair.regionCode)) {
      return pair.regionCode!;
    }

    // 2) Region affinity mapping
    if (pair.regionCode != null) {
      final mapped = regionAffinityMap[pair.regionCode];
      if (mapped != null && supportedCountries.contains(mapped)) {
        return mapped;
      }
    }

    // 3) Language match
    if (pair.languageCode.isNotEmpty) {
      final lang = pair.languageCode;
      final matches = supportedCountries
          .where((cc) => (countryLanguages[cc] ?? []).contains(lang))
          .toList();

      if (matches.length == 1) return matches.single;
      if (matches.length > 1) {
        final champ = languageChampion[lang];
        if (champ != null && supportedCountries.contains(champ)) {
          return champ;
        }
        return matches.first;
      }
    }
  }

  // 4) Fallback
  if (fallbackCountry == null) return null;
  if (supportedCountries.isEmpty) return fallbackCountry;
  if (supportedCountries.contains(fallbackCountry)) return fallbackCountry;
  return supportedCountries.first;
}

/// Public API for locale-based country selection.
class LocaleCountrySelector {
  LocaleCountrySelector._();

  /// Selects the best country code from [supportedCountries] based on the
  /// user's preferred [locales].
  ///
  /// **Inputs:**
  ///
  /// * [supportedCountries]: Allowed country codes (ISO 3166-1 alpha-2
  ///   uppercase recommended). Order is used as tie-breaker when multiple
  ///   countries match a language and no champion is set.
  /// * [locales]: Preferred locales in priority order (e.g. from
  ///   [dart:ui.PlatformDispatcher.locales] or
  ///   [WidgetsBinding.instance.platformDispatcher.locales]).
  /// * [countryLanguages]: Map from country code to list of BCP-47 primary
  ///   language subtags (e.g. "en", "ko", "fr") spoken in that country.
  /// * [languageChampion]: When multiple supported countries share a language,
  ///   this map picks a representative country (e.g. "en" -> "US").
  /// * [regionAffinityMap]: Optional. Maps unsupported region codes to supported
  ///   country codes (e.g. "GB" -> "DE"). Applied after exact region match and
  ///   before language match. Helps avoid "UK user -> US" when you prefer another
  ///   market (e.g. DE) for that region. Keys and values are normalized (trim +
  ///   uppercase).
  /// * [fallbackCountry]: Returned when no locale yields a match. If null, returns
  ///   null. If not in [supportedCountries], the first element of [supportedCountries]
  ///   is returned; if [supportedCountries] is empty, [fallbackCountry] is returned as-is.
  ///
  /// **Selection priority (per locale, in [locales] order):**
  ///
  /// 1. **Exact region match:** If the locale's region code (from
  ///    [Locale.toString()], e.g. "en_US" → "US") is in [supportedCountries],
  ///    that country is returned.
  /// 2. **Region affinity mapping:** If the region is not supported, [regionAffinityMap]
  ///    is consulted (e.g. "GB" → "DE"). If the mapped country is supported, it is
  ///    returned. This avoids unintuitive outcomes like "UK user → US" when only
  ///    language matching exists (e.g. supported [DE, US], en-GB → DE when mapping
  ///    is provided).
  /// 3. **Language match:** Find supported countries whose [countryLanguages]
  ///    list contains the locale's language code. If exactly one match, return it.
  ///    If multiple matches: use [languageChampion] for that language if
  ///    present and supported; otherwise return the first match by
  ///    [supportedCountries] order.
  /// 4. **Fallback:** If no locale yields a match: if [fallbackCountry] is null,
  ///    return null; if [supportedCountries] is empty, return [fallbackCountry];
  ///    if [fallbackCountry] is supported, return it; else return
  ///    [supportedCountries].first.
  ///
  /// **Normalization:** Country/region codes are trimmed and uppercased; language
  /// codes are trimmed and lowercased. Empty entries are dropped. [regionAffinityMap]
  /// keys and values are normalized the same way.
  ///
  /// Example:
  ///
  /// ```dart
  /// import 'package:flutter/widgets.dart';
  /// import 'package:locale_country_selector/locale_country_selector.dart';
  ///
  /// final locales = WidgetsBinding.instance.platformDispatcher.locales;
  /// final country = LocaleCountrySelector.selectCountry(
  ///   supportedCountries: ['KR', 'US'],
  ///   locales: locales.map((l) => Locale(l.languageCode, l.countryCode)).toList(),
  ///   countryLanguages: {'KR': ['ko'], 'US': ['en']},
  ///   languageChampion: {'en': 'US', 'ko': 'KR'},
  ///   fallbackCountry: 'US',
  /// );
  /// ```
  ///
  /// With region affinity (e.g. UK → DE when only DE and US are supported):
  ///
  /// ```dart
  /// final country = LocaleCountrySelector.selectCountry(
  ///   supportedCountries: ['DE', 'US'],
  ///   locales: [const Locale('en', 'GB')],
  ///   countryLanguages: {'DE': ['en', 'de'], 'US': ['en']},
  ///   regionAffinityMap: {'GB': 'DE'},
  ///   fallbackCountry: 'US',
  /// );
  /// // Returns 'DE' (en-GB region mapped to DE).
  /// ```
  ///
  /// Returns the selected country code (uppercase), or null if no match and
  /// [fallbackCountry] is null.
  static String? selectCountry({
    required List<String> supportedCountries,
    required List<Locale> locales,
    required Map<String, List<String>> countryLanguages,
    Map<String, String>? languageChampion,
    Map<String, String>? regionAffinityMap,
    String? fallbackCountry,
  }) {
    languageChampion ??= const {};
    regionAffinityMap ??= const {};

    final supported = _normalizeCountryList(supportedCountries);
    final countryLangs = _normalizeCountryLanguages(countryLanguages);
    final champion = _normalizeLanguageChampion(languageChampion);
    final affinity = _normalizeRegionAffinityMap(regionAffinityMap);
    final fallback = _normalizeCountry(fallbackCountry);

    final localePairs = locales.map((l) {
      return LocalePair(
        languageCode: _extractLanguage(l),
        regionCode: _extractRegion(l),
      );
    }).toList();

    return _selectCountryImpl(
      supportedCountries: supported,
      localePairs: localePairs,
      countryLanguages: countryLangs,
      languageChampion: champion,
      regionAffinityMap: affinity,
      fallbackCountry: fallback,
    );
  }

  /// Returns the normalized language code for [l] (e.g. "en").
  /// Uses [Locale.languageCode]; returns empty string if empty after trim.
  static String localeLanguageCode(Locale l) => _extractLanguage(l);

  /// Returns the region (country) code for [l] (e.g. "US" from "en_US").
  /// Uses [Locale.toString()] for compatibility across Flutter versions.
  static String? localeRegionCode(Locale l) => _extractRegion(l);
}
