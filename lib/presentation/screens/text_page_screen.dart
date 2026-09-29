/// Text Page Screen
///
/// A chapter as a page of text ("Düz Metin"), in the reader's colors and
/// font, with guided reading: a highlight moving word by word at the
/// reading speed.
///
/// The reading position is shared with the speed reader (saved in words).
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/data/quran.dart';
import '../../core/models/book.dart';
import '../../core/models/rsvp_settings.dart';
import '../../core/services/app_language.dart';
import '../../core/services/book_service.dart';
import '../../core/services/reading_storage.dart';
import '../../core/utils/timing_calculator.dart';
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

  const TextPageScreen({
    super.key,
    required this.content,
    required this.title,
    this.settings = const RSVPSettings(),
    this.currentBook,
    this.seriesChapters,
    this.onSettingsChanged,
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

  /// The first paragraph at the top of the page, updated
  /// when scrolling stops
  int _topIndex = 0;

  /// Read to the end: the position is saved as finished (next time the
  /// chapter starts over)
  bool _finished = false;

  /// Guided reading: a highlight moving word by word at the reading
  /// speed; shown from its first start on
  Timer? _pacer;
  bool _showPace = false;
  int _paceParagraph = 0;
  int _paceWord = 0;

  /// Start and end of each word of each paragraph
  late final List<List<(int, int)>> _wordSpans = [
    for (final paragraph in _paragraphs) [for (final m in RegExp(r'\S+').allMatches(paragraph)) (m.start, m.end)],
  ];

  bool get _pacing => _pacer != null;

  @override
  void initState() {
    super.initState();
    // Reading the page: keep the screen on
    if (!kIsWeb) WakelockPlus.enable();
    // The position is saved when the app goes to the background
    _lifecycle = AppLifecycleListener(onHide: _saveProgress);
    _start();
  }

  Future<void> _start() async {
    final paragraph = await _savedParagraph();
    if (!mounted) return;
    if (paragraph > 0) {
      _topIndex = paragraph;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(paragraph, animate: false));
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
    final paragraph = _showPace ? _paceParagraph : _topIndex;
    final index = _finished ? total : _wordsBefore[paragraph.clamp(0, _paragraphs.length - 1)];
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

  /// The chapter was read to the end: go on with the next one
  void _openNextChapter() {
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
      mode: ReadingMode.plain,
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

  /// Start guided reading at [paragraph], or where it stopped (the top of
  /// the page the first time)
  void _startPacing({int? paragraph}) {
    if (_paragraphs.isEmpty) return;
    if (paragraph != null || !_showPace) {
      _paceParagraph = paragraph ?? _topParagraph();
      _paceWord = 0;
    }
    _showPace = true;
    _pacer?.cancel();
    _scrollTo(_paceParagraph);
    _schedulePace();
    setState(() {});
  }

  void _stopPacing() {
    _pacer?.cancel();
    _pacer = null;
    _saveProgress();
    setState(() {});
  }

  /// Show the current word as long as the speed reader would, with shorter
  /// stops at sentence and paragraph ends: the page shows where the
  /// sentence goes on
  void _schedulePace() {
    final spans = _wordSpans[_paceParagraph];
    final (start, end) = spans[_paceWord];
    final duration = TimingCalculator.calculateDuration(
      config: TimingConfig(baseWPM: _settings.wordsPerMinute, adaptiveSpeed: _settings.adaptiveSpeed),
      word: _paragraphs[_paceParagraph].substring(start, end),
      isParagraphEnd: _paceWord == spans.length - 1,
      pauseScale: 0.25,
    );
    _pacer = Timer(Duration(milliseconds: duration), _paceNext);
  }

  void _paceNext() {
    if (!mounted) return;
    if (_paceWord + 1 < _wordSpans[_paceParagraph].length) {
      _paceWord++;
    } else if (_paceParagraph + 1 < _paragraphs.length) {
      _paceParagraph++;
      _paceWord = 0;
      _scrollTo(_paceParagraph);
    } else {
      // The end of the chapter
      _pacer = null;
      _finished = true;
      _saveProgress();
      setState(() {});
      return;
    }
    setState(() {});
    _schedulePace();
  }

  void _changeSettings(RSVPSettings settings) {
    setState(() => _settings = settings);
    widget.onSettingsChanged?.call(settings);
  }

  @override
  void dispose() {
    _pacer?.cancel();
    _saveProgress();
    _lifecycle.dispose();
    _scroll.dispose();
    if (!kIsWeb) WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = Color(_settings.pageBackgroundColor);
    final textColor = Color(_settings.pageTextColor);
    // Dark red on light pages, amber on dark ones
    final accent = background.computeLuminance() > 0.4 ? const Color(0xFFB71C1C) : const Color(0xFFFFB74D);
    final base = ORPTextWidget.readingFontStyle(
      _settings.pageFontFamily,
      fontSize: _settings.pageFontSize,
      color: textColor,
    );
    final style = base.copyWith(
      height: 1.6,
      // Arabic words (surah names) in the bundled Arabic font
      fontFamilyFallback: [...?base.fontFamilyFallback, if (kIsWeb) 'Roboto', quranArabicFont],
    );
    final next = _nextChapter();

    final page = Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w400)),
        actions: [
          IconButton(
            tooltip: context.l10n.pageSettings,
            icon: const Icon(Icons.text_fields),
            onPressed: _showPageSettings,
          ),
        ],
      ),
      body: NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          _topIndex = _topParagraph();
          _finished = notification.metrics.extentAfter < 1;
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
              if (next != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton.icon(
                    onPressed: _openNextChapter,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(context.l10n.nextChapter),
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
      bottomNavigationBar: _buildPaceControls(background, textColor, accent),
    );

    // Brightness: the page is dimmed (on top of the device's brightness)
    return Stack(
      children: [
        page,
        if (_settings.pageBrightness < 1)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Colors.black.withValues(alpha: 1 - _settings.pageBrightness)),
            ),
          ),
      ],
    );
  }

  Widget _buildParagraph(int i, TextStyle style, Color accent) {
    final text = _paragraphs[i];
    int? start;
    int? end;
    final current = _showPace && _paceParagraph == i;
    if (current && _wordSpans[i].isNotEmpty) (start, end) = _wordSpans[i][_paceWord];

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

    if (!_showPace) return child;
    // Tap a paragraph to read from there
    return GestureDetector(
      onTap: () {
        if (_pacing) {
          _startPacing(paragraph: i);
        } else {
          setState(() {
            _paceParagraph = i;
            _paceWord = 0;
          });
        }
      },
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

  /// Guided reading: start/stop and the reading speed
  Widget _buildPaceControls(Color background, Color textColor, Color accent) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.12))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              iconSize: 40,
              tooltip: _pacing ? context.l10n.stopGuidedReading : context.l10n.guidedReading,
              icon: Icon(_pacing ? Icons.pause_circle : Icons.play_circle, color: accent),
              onPressed: _pacing ? _stopPacing : _startPacing,
            ),
            Expanded(
              child: Text(
                context.l10n.guidedReading,
                style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: context.l10n.slower,
              icon: Icon(Icons.remove_circle_outline, color: textColor),
              onPressed: () => _changePaceSpeed(-RSVPSettings.wordsPerMinuteStep),
            ),
            Text('${_settings.wordsPerMinute} WPM', style: TextStyle(color: textColor, fontSize: 14)),
            IconButton(
              tooltip: context.l10n.faster,
              icon: Icon(Icons.add_circle_outline, color: textColor),
              onPressed: () => _changePaceSpeed(RSVPSettings.wordsPerMinuteStep),
            ),
          ],
        ),
      ),
    );
  }

  void _changePaceSpeed(int change) {
    final wpm =
        (_settings.wordsPerMinute + change).clamp(RSVPSettings.minWordsPerMinute, RSVPSettings.maxWordsPerMinute);
    _changeSettings(_settings.copyWith(wordsPerMinute: wpm));
  }

  /// Page themes: name, background and text colors
  List<(String, int, int)> _themes(BuildContext context) => [
        (context.l10n.pageThemeLight, 0xFFFFFFFF, 0xFF1F1F1F),
        (context.l10n.pageThemeSepia, 0xFFF8F1E3, 0xFF3B2F2A),
        (context.l10n.pageThemeGray, 0xFFE8E8E3, 0xFF2A2A2A),
        (context.l10n.pageThemeDark, 0xFF1E1E1E, 0xFFDADADA),
        (context.l10n.pageThemeNight, 0xFF15110D, 0xFFC9B59A), // warm, little blue light
      ];

  static const _backgroundChoices = [
    0xFFFFFFFF, 0xFFFDF6E3, 0xFFF8F1E3, 0xFFEAE4D3, 0xFFE3EFE3, 0xFFE6ECF5, 0xFF2B2B2B, 0xFF000000, //
  ];

  static const _textChoices = [0xFF000000, 0xFF1F1F1F, 0xFF3B2F2A, 0xFF4A4A4A, 0xFFDADADA, 0xFFC9B59A, 0xFFFFFFFF];

  static const _pageFonts = [
    'Literata',
    'Merriweather',
    'Lora',
    'Noto Serif',
    'Roboto',
    'Open Sans',
    'Lato',
    'OpenDyslexic'
  ];

  /// Font, size, colors and brightness of the page
  void _showPageSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void change(RSVPSettings settings) {
            _changeSettings(settings);
            setSheetState(() {});
          }

          Widget label(String text) => Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              );

          Widget swatch(int background, int text, bool selected, VoidCallback onTap, {String? name}) => Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 6),
                child: GestureDetector(
                  onTap: onTap,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color(background),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: selected ? Colors.black87 : Colors.black26, width: selected ? 2.5 : 1),
                        ),
                        child: Text('Aa', style: TextStyle(color: Color(text), fontSize: 13)),
                      ),
                      if (name != null) Text(name, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
              );

          final s = _settings;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  label(context.l10n.pageFont),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final font in _pageFonts)
                        ChoiceChip(
                          label: Text(font,
                              style: ORPTextWidget.readingFontStyle(font, fontSize: 14, color: Colors.black87)),
                          selected: s.pageFontFamily == font,
                          onSelected: (_) => change(s.copyWith(pageFontFamily: font)),
                        ),
                    ],
                  ),
                  label(context.l10n.pageTextSize),
                  Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Slider(
                          value: s.pageFontSize,
                          min: RSVPSettings.minPageFontSize,
                          max: RSVPSettings.maxPageFontSize,
                          divisions: (RSVPSettings.maxPageFontSize - RSVPSettings.minPageFontSize).round(),
                          label: s.pageFontSize.round().toString(),
                          onChanged: (value) => change(s.copyWith(pageFontSize: value.roundToDouble())),
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  label(context.l10n.theme),
                  Wrap(
                    children: [
                      for (final (name, background, text) in _themes(context))
                        swatch(
                          background,
                          text,
                          s.pageBackgroundColor == background && s.pageTextColor == text,
                          () => change(s.copyWith(pageBackgroundColor: background, pageTextColor: text)),
                          name: name,
                        ),
                    ],
                  ),
                  label(context.l10n.pageBackground),
                  Wrap(
                    children: [
                      for (final background in _backgroundChoices)
                        swatch(background, s.pageTextColor, s.pageBackgroundColor == background,
                            () => change(s.copyWith(pageBackgroundColor: background))),
                    ],
                  ),
                  label(context.l10n.pageTextColor),
                  Wrap(
                    children: [
                      for (final text in _textChoices)
                        swatch(s.pageBackgroundColor, text, s.pageTextColor == text,
                            () => change(s.copyWith(pageTextColor: text))),
                    ],
                  ),
                  label(context.l10n.pageBrightness),
                  Row(
                    children: [
                      const Icon(Icons.brightness_low, size: 20, color: Colors.black54),
                      Expanded(
                        child: Slider(
                          value: s.pageBrightness,
                          min: RSVPSettings.minPageBrightness,
                          max: 1,
                          onChanged: (value) => change(s.copyWith(pageBrightness: value)),
                        ),
                      ),
                      const Icon(Icons.brightness_high, size: 20, color: Colors.black54),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
