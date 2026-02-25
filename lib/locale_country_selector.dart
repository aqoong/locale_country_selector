// Copyright (c) 2025 locale_country_selector authors. All rights reserved.
// Use of this source is governed by an MIT-style license.

/// Deterministic country auto-selection using only OS locales (language + region).
/// No GPS, IP, SIM, or permissioned APIs. Android and iOS, pure Dart.
library locale_country_selector;

import 'package:flutter/widgets.dart' show Locale;

/// Internal pair to keep core logic free of Flutter types.
class _LocalePair {
  final String? languageCode;
  final String? countryCode;

  _LocalePair(this.languageCode, this.countryCode);
}

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

String _normalizeCountry(String s) {
  return s.trim().toUpperCase();
}

String _selectCountryImpl({
  required List<String> supportedCountries,
  required List<_LocalePair> localePairs,
  required Map<String, List<String>> countryLanguages,
  required Map<String, String> languageChampion,
  required String fallbackCountry,
}) {
  for (final pair in localePairs) {
    // 1-1) Exact region match
    if (pair.countryCode != null &&
        supportedCountries.contains(pair.countryCode)) {
      return pair.countryCode!;
    }

    // 1-2) Language match
    if (pair.languageCode != null && pair.languageCode!.isNotEmpty) {
      final lang = pair.languageCode!;
      final matches = supportedCountries
          .where((cc) =>
              (countryLanguages[cc] ?? []).contains(lang),)
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

  // 2) No match: fallback
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
  /// * [fallbackCountry]: Returned when no locale yields a match. If it is
  ///   not in [supportedCountries], the first element of [supportedCountries]
  ///   is returned instead; if [supportedCountries] is empty, [fallbackCountry]
  ///   is returned as-is.
  ///
  /// **Selection priority (per locale, in [locales] order):**
  ///
  /// 1. **Exact region match:** If [locale.countryCode] is in
  ///    [supportedCountries], that country is returned.
  /// 2. **Language match:** Find supported countries whose [countryLanguages]
  ///    list contains [locale.languageCode]. If exactly one match, return it.
  ///    If multiple matches: use [languageChampion] for that language if
  ///    present and supported; otherwise return the first match by
  ///    [supportedCountries] order.
  /// 3. If no locale matches, return [fallbackCountry] (or first supported if
  ///    fallback is not supported; or fallback as-is if [supportedCountries]
  ///    is empty).
  ///
  /// **Normalization:** Country codes are normalized to uppercase and
  /// language codes to lowercase for comparison.
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
  /// Returns the selected country code (uppercase).
  static String selectCountry({
    required List<String> supportedCountries,
    required List<Locale> locales,
    required Map<String, List<String>> countryLanguages,
    Map<String, String>? languageChampion,
    String fallbackCountry = 'US',
  }) {
    languageChampion ??= const {};

    final supported = _normalizeCountryList(supportedCountries);
    final countryLangs = _normalizeCountryLanguages(countryLanguages);
    final champion = _normalizeLanguageChampion(languageChampion);
    final fallback = _normalizeCountry(fallbackCountry);

    final localePairs = locales.map((l) {
      final lang = (l.languageCode).isEmpty ? null : l.languageCode.toLowerCase();
      final country = (l.countryCode == null || l.countryCode!.isEmpty)
          ? null
          : l.countryCode!.toUpperCase();
      return _LocalePair(lang, country);
    }).toList();

    return _selectCountryImpl(
      supportedCountries: supported,
      localePairs: localePairs,
      countryLanguages: countryLangs,
      languageChampion: champion,
      fallbackCountry: fallback,
    );
  }
}
