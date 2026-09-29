import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/presentation/screens/settings_screen.dart';
import 'package:rapid_reader/l10n/app_localizations.dart';

void main() {
  testWidgets('settings are labelled with proper Turkish characters', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        locale: Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(settings: RSVPSettings())));

    for (final label in ['Okuma Hızı', 'Adaptif Hız', 'Görünüm', 'Odak Çizgileri']) {
      await tester.scrollUntilVisible(find.text(label), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text(label), findsOneWidget);
    }
  });

  test('the default colors are the dark theme (shown as chosen)', () {
    const d = RSVPSettings.defaults, dark = RSVPSettings.darkTheme;
    expect([d.darkMode, d.textColor, d.backgroundColor, d.orpHighlightColor],
        [dark.darkMode, dark.textColor, dark.backgroundColor, dark.orpHighlightColor]);
  });
}
