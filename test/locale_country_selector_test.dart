// Copyright (c) 2025 locale_country_selector authors. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locale_country_selector/locale_country_selector.dart';

void main() {
  group('LocaleCountrySelector.selectCountry', () {
    test('supported [KR, US], locale en-CA -> US', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'US'],
        locales: [const Locale('en', 'CA')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    test('supported [KR, US], locale ko-KR -> KR', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'US'],
        locales: [const Locale('ko', 'KR')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: 'US',
      );
      expect(result, 'KR');
    });

    test('supported [US, SG], locales [en-AU], champion en->US -> US', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['US', 'SG'],
        locales: [const Locale('en', 'AU')],
        countryLanguages: {
          'US': ['en'],
          'SG': ['en', 'zh', 'ms']
        },
        languageChampion: {'en': 'US'},
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    test(
        'supported [US, SG], locales [en-AU], no champion -> US (first in supportedCountries)',
        () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['US', 'SG'],
        locales: [const Locale('en', 'AU')],
        countryLanguages: {
          'US': ['en'],
          'SG': ['en', 'zh', 'ms']
        },
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    test('supported [KR, US], locales [fr-CA] -> fallbackCountry', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'US'],
        locales: [const Locale('fr', 'CA')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    test('supported [KR, US], locales [en-CA, ko-KR] -> US (first locale wins)',
        () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'US'],
        locales: [const Locale('en', 'CA'), const Locale('ko', 'KR')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    test('locale with null/empty countryCode -> language matching still works',
        () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'US'],
        locales: [const Locale('ko')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: 'US',
      );
      expect(result, 'KR');
    });

    test('fallbackCountry not supported -> returns first supported', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'US'],
        locales: [const Locale('fr', 'FR')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: 'JP',
      );
      expect(result, 'KR');
    });

    test('supportedCountries empty -> returns fallbackCountry as-is', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: [],
        locales: [const Locale('fr', 'FR')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: 'JP',
      );
      expect(result, 'JP');
    });

    test('exact region match takes precedence over language', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'US'],
        locales: [const Locale('en', 'US')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        languageChampion: {'en': 'KR'},
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    test('single language match returns that country', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'JP'],
        locales: [const Locale('ko')],
        countryLanguages: {
          'KR': ['ko'],
          'JP': ['ja']
        },
        fallbackCountry: 'JP',
      );
      expect(result, 'KR');
    });

    test('multiple language match with champion returns champion', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['US', 'GB', 'AU'],
        locales: [const Locale('en')],
        countryLanguages: {
          'US': ['en'],
          'GB': ['en'],
          'AU': ['en']
        },
        languageChampion: {'en': 'GB'},
        fallbackCountry: 'US',
      );
      expect(result, 'GB');
    });

    test('champion not in supportedCountries -> first match by supported order',
        () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['US', 'SG'],
        locales: [const Locale('en')],
        countryLanguages: {
          'US': ['en'],
          'SG': ['en']
        },
        languageChampion: {'en': 'GB'},
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    test('normalizes country codes to uppercase', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['kr', 'us'],
        locales: [const Locale('ko', 'kr')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: 'us',
      );
      expect(result, 'KR');
    });

    test('empty locales -> fallback', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'US'],
        locales: [],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    // --- Region affinity ---
    test('supported [DE, US], locales [en-GB], regionAffinityMap {GB:DE} -> DE',
        () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['DE', 'US'],
        locales: [const Locale('en', 'GB')],
        countryLanguages: {
          'DE': ['en', 'de'],
          'US': ['en']
        },
        regionAffinityMap: {'GB': 'DE'},
        fallbackCountry: 'US',
      );
      expect(result, 'DE');
    });

    test(
        'supported [US, DE], locales [en-GB], no regionAffinityMap -> language match picks first -> US',
        () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['US', 'DE'],
        locales: [const Locale('en', 'GB')],
        countryLanguages: {
          'DE': ['en', 'de'],
          'US': ['en']
        },
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    test(
        'regionAffinityMap points to unsupported country -> ignore, continue to language match',
        () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['US'],
        locales: [const Locale('en', 'GB')],
        countryLanguages: {
          'US': ['en']
        },
        regionAffinityMap: {'GB': 'DE'},
        fallbackCountry: 'US',
      );
      expect(result, 'US');
    });

    test('regionAffinityMap key normalization: " gb " works', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['DE', 'US'],
        locales: [const Locale('en', 'GB')],
        countryLanguages: {
          'DE': ['en', 'de'],
          'US': ['en']
        },
        regionAffinityMap: {' gb ': ' de '},
        fallbackCountry: 'US',
      );
      expect(result, 'DE');
    });

    test('fallbackCountry null and no match -> returns null', () {
      final result = LocaleCountrySelector.selectCountry(
        supportedCountries: ['KR', 'US'],
        locales: [const Locale('fr', 'FR')],
        countryLanguages: {
          'KR': ['ko'],
          'US': ['en']
        },
        fallbackCountry: null,
      );
      expect(result, null);
    });
  });
}
