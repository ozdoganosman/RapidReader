import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('settings are labelled with proper Turkish characters', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen(settings: RSVPSettings())));

    for (final label in ['Okuma Hızı', 'Adaptif Hız', 'Görünüm', 'Odak Çizgileri']) {
      await tester.scrollUntilVisible(find.text(label), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text(label), findsOneWidget);
    }
  });
}
