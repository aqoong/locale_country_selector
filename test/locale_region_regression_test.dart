import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locale_country_selector/locale_country_selector.dart';

void main() {
  const taiwan = Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hant',
    countryCode: 'TW',
  );

  test('script locale exposes its region', () {
    expect(LocaleCountrySelector.localeRegionCode(taiwan), 'TW');
  });

  test('script locale exact region beats affinity and language champion', () {
    expect(
      LocaleCountrySelector.selectCountry(
        supportedCountries: ['CN', 'TW'],
        locales: [taiwan],
        countryLanguages: {
          'CN': ['zh'],
          'TW': ['zh'],
        },
        languageChampion: {'zh': 'CN'},
        regionAffinityMap: {'TW': 'CN'},
        fallbackCountry: 'CN',
      ),
      'TW',
    );
  });

  test('script locale region can use affinity', () {
    expect(
      LocaleCountrySelector.selectCountry(
        supportedCountries: ['CN', 'HK'],
        locales: [taiwan],
        countryLanguages: {
          'CN': ['zh'],
          'HK': ['zh'],
        },
        languageChampion: {'zh': 'CN'},
        regionAffinityMap: {'TW': 'HK'},
      ),
      'HK',
    );
  });

  test('script without region does not invent a region', () {
    expect(
      LocaleCountrySelector.localeRegionCode(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
      isNull,
    );
  });

  test('alpha-2 and M49 region extraction is preserved', () {
    expect(
      LocaleCountrySelector.localeRegionCode(const Locale('en', 'US')),
      'US',
    );
    expect(
      LocaleCountrySelector.localeRegionCode(
        const Locale.fromSubtags(languageCode: 'es', countryCode: '419'),
      ),
      '419',
    );
  });

  test('README affinity example changes only its affinity map', () {
    String? select(Map<String, String> affinity) =>
        LocaleCountrySelector.selectCountry(
          supportedCountries: ['DE', 'US'],
          locales: [const Locale('en', 'GB')],
          countryLanguages: {
            'DE': ['en', 'de'],
            'US': ['en'],
          },
          languageChampion: {'en': 'US'},
          regionAffinityMap: affinity,
          fallbackCountry: 'US',
        );
    expect(select({}), 'US');
    expect(select({'GB': 'DE'}), 'DE');
  });
}
