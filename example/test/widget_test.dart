// Basic smoke test for the example app.

import 'package:flutter_test/flutter_test.dart';

import 'package:locale_country_selector_example/main.dart';

void main() {
  testWidgets('Example app shows Locale Country Selector', (WidgetTester tester) async {
    await tester.pumpWidget(const LocaleCountrySelectorExampleApp());
    expect(find.text('Locale Country Selector'), findsOneWidget);
    expect(find.text('Selected country (from OS locales only):'), findsOneWidget);
  });
}
