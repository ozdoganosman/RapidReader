/// Arabic Surah Screen
///
/// Shows the Arabic text of one surah, verse by verse.
library;

import 'package:flutter/material.dart';

import '../../core/data/quran.dart';

class ArabicSurahScreen extends StatefulWidget {
  /// Surah number in mushaf order
  final int mushafNumber;

  /// Title shown in the app bar, e.g. "Alak Suresi (العلق)"
  final String title;

  const ArabicSurahScreen({super.key, required this.mushafNumber, required this.title});

  @override
  State<ArabicSurahScreen> createState() => _ArabicSurahScreenState();
}

class _ArabicSurahScreenState extends State<ArabicSurahScreen> {
  late final Future<List<String>> _verses = loadArabicSurah(widget.mushafNumber);

  @override
  Widget build(BuildContext context) {
    final mushafNumber = widget.mushafNumber;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w300),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _verses,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Arapça metin yüklenemedi'));
          }
          final verses = snapshot.data;
          if (verses == null) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black26));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              if (quranHasBasmalaHeading(mushafNumber))
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    quranBasmala,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: quranArabicFont, fontSize: 28, height: 1.9, color: Colors.black87),
                  ),
                ),
              for (var i = 0; i < verses.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    '${verses[i]} ﴿${arabicDigits(i + 1)}﴾',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: quranArabicFont, fontSize: 26, height: 2.0, color: Colors.black87),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                quranArabicSource,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          );
        },
      ),
    );
  }
}
