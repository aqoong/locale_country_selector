// Copyright (c) 2025 locale_country_selector authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:locale_country_selector/locale_country_selector.dart';

void main() => runApp(const LocaleCountrySelectorExampleApp());

class LocaleCountrySelectorExampleApp extends StatelessWidget {
  const LocaleCountrySelectorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locale Country Selector Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _ExamplePage(),
    );
  }
}

class _ExamplePage extends StatefulWidget {
  const _ExamplePage();

  @override
  State<_ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<_ExamplePage> {
  static const List<String> supportedCountries = ['KR', 'US'];
  static const Map<String, List<String>> countryLanguages = {
    'KR': ['ko'],
    'US': ['en'],
  };
  static const Map<String, String> languageChampion = {
    'en': 'US',
    'ko': 'KR',
  };

  late String _selectedCountry;
  late List<Locale> _deviceLocales;

  @override
  void initState() {
    super.initState();
    _refreshFromDevice();
  }

  void _refreshFromDevice() {
    final platformLocales =
        WidgetsBinding.instance.platformDispatcher.locales;
    _deviceLocales = platformLocales
        .map((l) => Locale(l.languageCode, l.countryCode))
        .toList();
    _selectedCountry = LocaleCountrySelector.selectCountry(
      supportedCountries: supportedCountries,
      locales: _deviceLocales,
      countryLanguages: countryLanguages,
      languageChampion: languageChampion,
      fallbackCountry: 'US',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locale Country Selector'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Device preferred locales (priority order):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ..._deviceLocales.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${l.languageCode}${l.countryCode != null && l.countryCode!.isNotEmpty ? '-${l.countryCode}' : ''}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Selected country (from OS locales only):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCountry,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This app uses only the device locale list. No GPS, IP, SIM, or network.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _refreshFromDevice,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh from device locales'),
          ),
        ],
      ),
    );
  }
}
