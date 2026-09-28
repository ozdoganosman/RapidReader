/// Text Page Screen
///
/// A chapter as a page of text, in the reader's colors and font: for
/// reading it normally ("Düz Metin") or for listening to it ("Sesli
/// Okuma"), where the device's voice reads it paragraph by paragraph and
/// the paragraph and word being read are highlighted. Listening goes on
/// with the screen off and continues with the next chapter.
///
/// The reading position is shared with the speed reader (saved in words).
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/data/quran.dart';
import '../../core/models/book.dart';
import '../../core/models/rsvp_settings.dart';
import '../../core/services/book_service.dart';
import '../../core/services/read_aloud_player.dart';
import '../../core/services/reading_storage.dart';
import '../widgets/orp_text_widget.dart';
import 'reader_screen.dart';
import 'reading_mode_sheet.dart';

class TextPageScreen extends StatefulWidget {
  final String content;
  final String title;
  final RSVPSettings settings;

  /// The book or chapter (for the reading position and the next chapter)
  final Book? currentBook;

  /// All chapters of the series in reading order
  final List<Book>? seriesChapters;

  final ValueChanged<RSVPSettings>? onSettingsChanged;

  /// Read the text aloud, starting right away (otherwise just show it)
  final bool listen;

  /// The voice; tests pass a player with a mocked engine
  @visibleForTesting
  final ReadAloudPlayer Function(List<String> paragraphs, double rate)? playerBuilder;

  const TextPageScreen({
    super.key,
    required this.content,
    required this.title,
    this.settings = const RSVPSettings(),
    this.currentBook,
    this.seriesChapters,
    this.onSettingsChanged,
    this.listen = false,
    this.playerBuilder,
  });

  @override
  State<TextPageScreen> createState() => _TextPageScreenState();
}

class _TextPageScreenState extends State<TextPageScreen> {
  late RSVPSettings _settings = widget.settings;

  /// One paragraph per line, as in the speed reader
  late final List<String> _paragraphs = [
    for (final line in widget.content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];

  /// Words before each paragraph, with the total at the end
  late final List<int> _wordsBefore = () {
    final result = [0];
    for (final paragraph in _paragraphs) {
      result.add(result.last + Book.countWords(paragraph));
    }
    return result;
  }();

  late final List<GlobalKey> _keys = [for (var i = 0; i < _paragraphs.length; i++) GlobalKey()];
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  late final AppLifecycleListener _lifecycle;
  ReadAloudPlayer? _player;
  int _shownParagraph = -1;

  /// The first paragraph at the top of the page (plain reading), updated
  /// when scrolling stops
  int _topIndex = 0;

  /// Read to the end: the position is saved as finished (next time the
  /// chapter starts over)
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    if (widget.listen) {
      final build = widget.playerBuilder ?? (paragraphs, rate) => ReadAloudPlayer(paragraphs: paragraphs, rate: rate);
      _player = build(_paragraphs, _settings.speechRate)
        ..addListener(_onPlayer)
        ..onFinished = _onFinished
        ..onError = (_) => _showMessage('Sesli okuma durdu. Devam etmek için oynat\'a dokunun.');
    } else if (!kIsWeb) {
      // Reading the page: keep the screen on (listening lets it turn off)
      WakelockPlus.enable();
    }
    // The position is saved when the app goes to the background; listening
    // goes on there
    _lifecycle = AppLifecycleListener(onHide: _saveProgress);
    _start();
  }

  Future<void> _start() async {
    final paragraph = await _savedParagraph();
    if (!mounted) return;
    if (paragraph > 0) {
      _topIndex = paragraph;
      _player?.seek(paragraph);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(paragraph, animate: false));
    }
    if (_player != null) {
      final available = await _player!.isAvailable();
      if (!mounted) return;
      if (!available) {
        _showMessage(kIsWeb
            ? 'Tarayıcıda Türkçe ses bulunamadı. Başka bir tarayıcı deneyin ya da Android uygulamasını kullanın.'
            : 'Cihazda Türkçe ses bulunamadı. Android ayarlarında "Metin okuma çıkışı" bölümünden '
                'Türkçe ses verisini indirin.');
        return;
      }
      _player!.play();
    }
  }

  /// The paragraph where this chapter was left off (0 if new or finished)
  Future<int> _savedParagraph() async {
    final book = widget.currentBook;
    if (book == null || _paragraphs.isEmpty) return 0;
    final saved = await ReadingStorage.loadProgress(book.id);
    if (saved == null || saved.isComplete) return 0;
    final total = _wordsBefore.last;
    var word = saved.index;
    if (saved.total > 0 && saved.total != total) word = word * total ~/ saved.total;
    var paragraph = 0;
    while (paragraph + 1 < _paragraphs.length && _wordsBefore[paragraph + 1] <= word) {
      paragraph++;
    }
    return paragraph;
  }

  void _saveProgress() {
    final book = widget.currentBook;
    if (book == null || _paragraphs.isEmpty) return;
    final total = _wordsBefore.last;
    final index = _finished ? total : _wordsBefore[(_player?.paragraph ?? _topIndex).clamp(0, _paragraphs.length - 1)];
    ReadingStorage.saveProgress(book.id, ReadingProgress(index: index, total: total));
  }

  /// The first paragraph visible at the top of the page
  int _topParagraph() {
    final viewport = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) return _topIndex;
    final top = viewport.localToGlobal(Offset.zero).dy;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero).dy + box.size.height > top) return i;
    }
    return _keys.length - 1;
  }

  void _scrollTo(int paragraph, {bool animate = true}) {
    final target = _keys[paragraph].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.2,
      duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
    );
  }

  void _onPlayer() {
    if (!mounted) return;
    setState(() {});
    final paragraph = _player!.paragraph;
    if (paragraph != _shownParagraph) {
      _shownParagraph = paragraph;
      _scrollTo(paragraph);
      _saveProgress();
    }
  }

  /// The chapter was read to the end: go on with the next one
  void _onFinished() {
    _finished = true;
    _saveProgress();
    final next = _nextChapter();
    if (next == null || !mounted) return;
    ReaderScreen.open(
      context,
      book: next,
      title: '${BookService.seriesDisplayName(next.seriesName ?? '')} - ${next.title}',
      settings: _settings,
      seriesChapters: widget.seriesChapters,
      onSettingsChanged: widget.onSettingsChanged,
      mode: widget.listen ? ReadingMode.listen : ReadingMode.plain,
      replace: true,
    );
  }

  Book? _nextChapter() {
    final chapters = widget.seriesChapters;
    final current = widget.currentBook?.chapterNumber;
    if (chapters == null || current == null) return null;
    final index = chapters.indexWhere((b) => b.chapterNumber == current);
    return index == -1 || index + 1 >= chapters.length ? null : chapters[index + 1];
  }

  void _setRate(double rate) {
    _player!.setRate(rate);
    _settings = _settings.copyWith(speechRate: rate);
    widget.onSettingsChanged?.call(_settings);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _saveProgress();
    _lifecycle.dispose();
    _player
      ?..removeListener(_onPlayer)
      ..dispose();
    _scroll.dispose();
    if (!widget.listen && !kIsWeb) WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = Color(_settings.backgroundColor);
    final textColor = Color(_settings.textColor);
    final accent = Color(_settings.orpHighlightColor);
    // The reader's font, at a page size (the speed reader's is much larger)
    final base = ORPTextWidget.readingFontStyle(
      _settings.fontFamily,
      fontSize: (_settings.fontSize * 0.6).clamp(16.0, 30.0),
      color: textColor,
    );
    final style = base.copyWith(
      height: 1.6,
      // Arabic words (surah names) in the bundled Arabic font
      fontFamilyFallback: [...?base.fontFamilyFallback, if (kIsWeb) 'Roboto', quranArabicFont],
    );
    final next = _nextChapter();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w400)),
        actions: [if (_player != null) _buildRateMenu(textColor)],
      ),
      body: NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          if (_player == null) {
            _topIndex = _topParagraph();
            _finished = notification.metrics.extentAfter < 1;
          }
          return false;
        },
        child: SingleChildScrollView(
          key: _viewportKey,
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _paragraphs.length; i++)
                Padding(
                  key: _keys[i],
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildParagraph(i, style, accent),
                ),
              if (!widget.listen && next != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _finished = true;
                      _onFinished();
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Sonraki Bölüm'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: textColor.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _player == null ? null : _buildControls(background, textColor, accent),
    );
  }

  Widget _buildParagraph(int i, TextStyle style, Color accent) {
    final player = _player;
    final current = player != null && player.paragraph == i;
    final text = _paragraphs[i];
    final start = current ? player.wordStart : null;
    final end = current ? player.wordEnd : null;

    final Widget child;
    if (start != null && end != null && start >= 0 && end <= text.length && start < end) {
      child = Text.rich(
        TextSpan(children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: TextStyle(color: accent, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(end)),
        ]),
        style: style,
      );
    } else {
      child = Text(text, style: style);
    }

    if (player == null) return child;
    // Tap a paragraph to read from there
    return GestureDetector(
      onTap: () => player.play(from: i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: current ? accent.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: child,
      ),
    );
  }

  /// Speech speed, chosen from a menu in the app bar
  Widget _buildRateMenu(Color textColor) {
    final rates = [
      for (var r = RSVPSettings.minSpeechRate; r <= RSVPSettings.maxSpeechRate; r += RSVPSettings.speechRateStep) r,
    ];
    return PopupMenuButton<double>(
      tooltip: 'Konuşma hızı',
      initialValue: _player!.rate,
      onSelected: _setRate,
      itemBuilder: (context) => [
        for (final rate in rates) PopupMenuItem(value: rate, child: Text(speechRateLabel(rate))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text('Ses ${speechRateLabel(_player!.rate)}', style: TextStyle(color: textColor, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildControls(Color background, Color textColor, Color accent) {
    final player = _player!;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.12))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Önceki paragraf',
              icon: Icon(Icons.skip_previous, color: textColor),
              onPressed: () => player.seek(player.paragraph - 1),
            ),
            const SizedBox(width: 24),
            IconButton(
              iconSize: 56,
              tooltip: player.isPlaying ? 'Duraklat' : 'Oku',
              icon: Icon(player.isPlaying ? Icons.pause_circle : Icons.play_circle, color: accent),
              onPressed: player.isPlaying ? player.pause : () => player.play(),
            ),
            const SizedBox(width: 24),
            IconButton(
              tooltip: 'Sonraki paragraf',
              icon: Icon(Icons.skip_next, color: textColor),
              onPressed: () => player.seek(player.paragraph + 1),
            ),
          ],
        ),
      ),
    );
  }
}
