import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/core/services/library_storage.dart';
import 'package:rapid_reader/presentation/screens/home_screen.dart';
import 'package:rapid_reader/presentation/screens/reader_screen.dart';

import 'helpers.dart';

Future<void> _pumpHome(WidgetTester tester, LibraryStorage storage) async {
  mockWakelock(tester);
  await tester.pumpWidget(MaterialApp(home: HomeScreen(storage: storage)));
}

/// Scroll the home screen to [finder] and tap it
Future<void> _tapOnHome(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Leave the reader with its back button
Future<void> _closeReader(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the saved reading speed', (tester) async {
    final storage = InMemoryLibraryStorage();
    await storage.saveSettings(const RSVPSettings(wordsPerMinute: 450));

    await _pumpHome(tester, storage);

    expect(find.text('450 kelime/dakika'), findsOneWidget);
  });

  testWidgets('reading position is saved and resumed from the history', (tester) async {
    final storage = InMemoryLibraryStorage();
    await _pumpHome(tester, storage);
    expect(find.text('Son Okunanlar'), findsNothing);

    // Read the sample for a while, then leave the reader
    await _tapOnHome(tester, find.text('Örnek Metni Oku'));
    await tester.tap(find.byIcon(Icons.play_circle));
    await tester.pump(const Duration(seconds: 5));
    await _closeReader(tester);

    final book = storage.recentBooks().single;
    expect(book.title, 'Örnek Metin');
    expect(book.currentWordIndex, greaterThan(0));
    expect(find.text('Son Okunanlar'), findsOneWidget);
    expect(find.textContaining('okundu'), findsOneWidget);

    // Reopening from the history continues at the saved word
    await _tapOnHome(tester, find.text('Örnek Metin'));
    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('${book.currentWordIndex + 1} / ${book.totalWords}'), findsOneWidget);
    await _closeReader(tester);
  });

  testWidgets('speed changed in the reader is saved', (tester) async {
    final storage = InMemoryLibraryStorage();
    await _pumpHome(tester, storage);

    await _tapOnHome(tester, find.text('Örnek Metni Oku'));
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    await _closeReader(tester);

    expect(storage.loadSettings().wordsPerMinute, 350);
    expect(find.text('350 kelime/dakika'), findsOneWidget);
  });

  testWidgets('books can be removed from the history', (tester) async {
    final storage = InMemoryLibraryStorage();
    await _pumpHome(tester, storage);

    await _tapOnHome(tester, find.text('Örnek Metni Oku'));
    await _closeReader(tester);
    expect(find.text('Örnek Metin'), findsOneWidget);

    await _tapOnHome(tester, find.byTooltip('Geçmişten kaldır'));

    expect(storage.recentBooks(), isEmpty);
    expect(find.text('Son Okunanlar'), findsNothing);
  });
}
