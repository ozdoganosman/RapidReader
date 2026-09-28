/// Reading Mode Sheet
///
/// Asked when a chapter or text is opened: speed reading (RSVP), the plain
/// text, or listening to it.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ReadingMode {
  /// Word by word at the chosen speed (RSVP)
  speed,

  /// The text as a page
  plain,

  /// The text read aloud by the device's voice
  listen,
}

/// Let the user choose how to read; null if the sheet was dismissed
Future<ReadingMode?> showReadingModeSheet(BuildContext context) {
  return showModalBottomSheet<ReadingMode>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _option(context, ReadingMode.speed, Icons.bolt, 'Hızlı Okuma', 'Kelime kelime, seçtiğin hızda'),
            _option(context, ReadingMode.plain, Icons.article_outlined, 'Düz Metin', 'Sayfa olarak, kendi hızında'),
            _option(context, ReadingMode.listen, Icons.headphones_outlined, 'Sesli Okuma',
                'Cihazın Türkçe sesiyle; ekran kapalıyken de'),
          ],
        ),
      ),
    ),
  );
}

Widget _option(BuildContext context, ReadingMode mode, IconData icon, String title, String subtitle) {
  return ListTile(
    leading: Icon(icon, color: Colors.black87),
    title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 16)),
    subtitle: Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
    onTap: () => Navigator.of(context).pop(mode),
  );
}
