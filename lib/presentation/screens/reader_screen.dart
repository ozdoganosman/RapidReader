/// Reader Screen - Main RSVP reading interface
///
/// Full-screen reading experience with:
/// - Centered word display with ORP highlighting
/// - Tap to play/pause
/// - Swipe to seek
/// - Speed controls
/// - Progress indicator
/// - Read-aloud with the device's Turkish voice
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/models/book.dart';
import '../../core/models/rsvp_settings.dart';
import '../../core/models/word_token.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/book_service.dart';
import '../../core/services/narrator.dart';
import '../../core/services/reading_stats.dart';
import '../../core/services/reading_storage.dart';
import '../../core/services/rsvp_engine.dart';
import '../../core/services/speech_narrator.dart';
import '../../core/utils/text_parser.dart';
import '../../core/utils/timing_calculator.dart';
import '../widgets/orp_text_widget.dart';

/// Main RSVP reader screen
class ReaderScreen extends StatefulWidget {
  /// Text content to read
  final String content;

  /// Book title (optional)
  final String? title;

  /// Initial settings
  final RSVPSettings settings;

  /// Starting word index
  final int startIndex;

  /// Callback when reading position changes
  final void Function(int index)? onProgressChanged;

  /// Current book (for series navigation)
  final Book? currentBook;

  /// All chapters in the series in reading order (for the next chapter
  /// button)
  final List<Book>? seriesChapters;

  /// Callback when settings change in the reader (e.g. speed)
  final ValueChanged<RSVPSettings>? onSettingsChanged;

  const ReaderScreen({
    super.key,
    required this.content,
    this.title,
    this.settings = const RSVPSettings(),
    this.startIndex = 0,
    this.onProgressChanged,
    this.currentBook,
    this.seriesChapters,
    this.onSettingsChanged,
  });

  /// Open [book] in the reader, loading its text first (bundled texts are
  /// only loaded when they are opened)
  static Future<void> open(
    BuildContext context, {
    required Book book,
    required String title,
    required RSVPSettings settings,
    List<Book>? seriesChapters,
    ValueChanged<RSVPSettings>? onSettingsChanged,
    bool replace = false,
  }) async {
    final content = await BookService.loadContent(book);
    if (!context.mounted) return;
    final route = MaterialPageRoute<void>(
      builder: (context) => ReaderScreen(
        content: content,
        title: title,
        settings: settings,
        currentBook: book,
        seriesChapters: seriesChapters,
        onSettingsChanged: onSettingsChanged,
      ),
    );
    final navigator = Navigator.of(context);
    replace ? await navigator.pushReplacement(route) : await navigator.push(route);
  }

  /// Index of the token that holds word number [word] (0-based), given the
  /// number of words before each token
  @visibleForTesting
  static int tokenIndexOfWord(List<int> wordsBefore, int word) {
    // The last token starting at or before the word
    var low = 0;
    var high = wordsBefore.length - 2;
    if (high < 0) return 0;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (wordsBefore[mid] <= word) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  /// Words read between progress saves while playing (the position is
  /// also saved on pause, at the end, on close and in the background).
  /// Kept high: on Android every save rewrites the whole preferences file,
  /// which also holds the custom books.
  static const _progressSaveInterval = 300;

  late final RSVPEngine _engine;
  late final AppLifecycleListener _lifecycleListener;
  int? _lastSavedIndex;
  bool _wasComplete = false;
  late RSVPSettings _settings;
  late List<WordToken> _tokens;

  /// Number of words before each token (a chunk holds several words), with
  /// the total at the end
  late List<int> _wordsBefore;
  bool _showControls = true;
  bool _isDraggingSlider = false;
  int _previewIndex = 0;
  bool _showContextView = false;

  /// Start of the current reading session (while playing), for the stats
  DateTime? _sessionStart;
  int _sessionStartIndex = 0;

  /// Last word shown while playing (a seek has already moved the engine
  /// away from it when the session ends)
  int _sessionLastIndex = 0;

  /// The voice for read-aloud, created when it is first turned on
  SpeechNarrator? _narrator;

  /// Whether the text is being read aloud (the voice moves the words)
  bool get _readingAloud => _engine.narrator != null;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _engine = RSVPEngine();

    // Parse text into tokens
    _tokens = TextParser.parse(widget.content, chunkSize: _settings.chunkSize);
    _wordsBefore = [0];
    for (final token in _tokens) {
      _wordsBefore.add(_wordsBefore.last + token.chunkSize);
    }

    // Initialize engine
    _engine.initialize(
      tokens: _tokens,
      config: TimingConfig(
        baseWPM: _settings.wordsPerMinute,
        adaptiveSpeed: _settings.adaptiveSpeed,
        microPauseInterval: _settings.microPauseInterval,
        microPauseDuration: _settings.microPauseDuration,
        warmUp: _settings.speedWarmUp,
      ),
      startIndex: widget.startIndex,
    );
    _lastSavedIndex = _engine.state.currentIndex;

    // Listen for progress changes
    _engine.addListener(_onEngineStateChanged);

    // Stop reading (and save the position) when the app goes to background
    _lifecycleListener = AppLifecycleListener(onHide: _engine.pause);

    // Continue where this book was left off
    _restoreProgress();

    if (_settings.readAloud) _setReadAloud(true);

    // Enter immersive mode
    _enterImmersiveMode();
  }

  void _enterImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Keep screen awake while reading (not supported on web)
    if (!kIsWeb) {
      WakelockPlus.enable();
    }
  }

  void _exitImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Allow screen to sleep again
    if (!kIsWeb) {
      WakelockPlus.disable();
    }
  }

  void _onEngineStateChanged() {
    if (mounted) {
      setState(() {});

      // Report progress
      widget.onProgressChanged?.call(_engine.state.currentIndex);

      // Reading time and words for the stats
      if (_engine.state.isPlaying) {
        if (_sessionStart == null) {
          _sessionStart = DateTime.now();
          _sessionStartIndex = _engine.state.currentIndex;
        }
        _sessionLastIndex = _engine.state.currentIndex;
      } else {
        _endSession();
      }

      // Count finished chapters for the interstitial ad (every 3rd one)
      final isComplete = _engine.state.isComplete;
      if (isComplete && !_wasComplete) {
        AdService().onReadingSessionComplete();
      }
      _wasComplete = isComplete;

      // Save when playback stops, and periodically while playing
      final state = _engine.state;
      final lastIndex = _lastSavedIndex;
      if (!state.isPlaying || lastIndex == null || (state.currentIndex - lastIndex).abs() >= _progressSaveInterval) {
        _saveProgress();
      }
    }
  }

  /// Jump to the saved position of the current book, if there is one
  Future<void> _restoreProgress() async {
    final book = widget.currentBook;
    if (book == null || widget.startIndex != 0) return;

    final saved = await ReadingStorage.loadProgress(book.id);
    final state = _engine.state;
    // Don't jump if the reader already started or moved on its own
    if (!mounted || saved == null || saved.isComplete || state.totalTokens == 0) return;
    if (state.isPlaying || state.currentIndex != 0) return;

    // The position is saved in words, so a changed chunk size keeps it; a
    // text that changed length (or a position saved in word groups by an
    // older version) is scaled
    final totalWords = _wordsBefore.last;
    var word = saved.index;
    if (saved.total > 0 && saved.total != totalWords) {
      word = word * totalWords ~/ saved.total;
    }
    final index = ReaderScreen.tokenIndexOfWord(_wordsBefore, word);
    _lastSavedIndex = index;
    _engine.seekToIndex(index);
  }

  /// Turn read-aloud on or off (on needs a Turkish voice on the device)
  Future<void> _setReadAloud(bool on) async {
    if (!on) {
      _engine
        ..pause()
        ..setNarrator(null);
      _changeSettings(_settings.copyWith(readAloud: false));
      return;
    }

    final narrator = _narrator ??= SpeechNarrator(rate: _settings.speechRate, onError: _onSpeechError);
    final available = await narrator.isAvailable();
    if (!mounted) return;
    if (!available) {
      _changeSettings(_settings.copyWith(readAloud: false));
      _showMessage(kIsWeb
          ? 'Tarayıcıda Türkçe ses bulunamadı. Başka bir tarayıcı deneyin ya da Android uygulamasını kullanın.'
          : 'Cihazda Türkçe ses bulunamadı. Android ayarlarında "Metin okuma çıkışı" bölümünden '
              'Türkçe ses verisini indirin.');
      return;
    }
    _engine.setNarrator(narrator);
    _changeSettings(_settings.copyWith(readAloud: true));
  }

  void _onSpeechError(String message) {
    if (!mounted) return;
    _engine.pause();
    setState(() => _showControls = true);
    _showMessage('Sesli okuma durdu. Tekrar başlatmak için oynat\'a dokunun.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _changeSettings(RSVPSettings settings) {
    if (settings == _settings) return;
    setState(() => _settings = settings);
    widget.onSettingsChanged?.call(settings);
  }

  /// Add the words read since playback started to the reading stats
  void _endSession() {
    final start = _sessionStart;
    if (start == null) return;
    _sessionStart = null;

    final end = _engine.state.isComplete ? _tokens.length : _sessionLastIndex.clamp(0, _tokens.length);
    if (end <= _sessionStartIndex) return;
    final words = _wordsBefore[end] - _wordsBefore[_sessionStartIndex];
    ReadingStats.addReading(words: words, time: DateTime.now().difference(start));
  }

  /// Save the reading position of the current book
  void _saveProgress() {
    final book = widget.currentBook;
    final state = _engine.state;
    if (book == null || state.totalTokens == 0) return;

    // A finished book is saved as index == total and restarts next time
    final index = state.isComplete ? state.totalTokens : state.currentIndex;
    if (index == _lastSavedIndex) return;

    _lastSavedIndex = index;
    // Saved in words (not word groups), so it survives a chunk size change
    ReadingStorage.saveProgress(
      book.id,
      ReadingProgress(index: _wordsBefore[index.clamp(0, _tokens.length)], total: _wordsBefore.last),
    );
  }

  @override
  void dispose() {
    _endSession();
    _saveProgress();
    _lifecycleListener.dispose();
    _engine.removeListener(_onEngineStateChanged);
    _engine.dispose();
    _narrator?.dispose();
    _exitImmersiveMode();
    super.dispose();
  }

  void _handleTap() {
    if (_engine.state.isPlaying) {
      _engine.pause();
      setState(() => _showControls = true);
    } else {
      _engine.play();
      // Hide controls after a delay when playing
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _engine.state.isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _handleHorizontalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity > 300) {
      // Swipe right - go back
      _engine.skipBackward(10);
    } else if (velocity < -300) {
      // Swipe left - go forward
      _engine.skipForward(10);
    }
  }

  void _updateSpeed(int wpm) {
    _engine.setSpeed(wpm);
    // Show the speed the engine actually uses (it clamps to the valid range)
    _changeSettings(_settings.copyWith(wordsPerMinute: _engine.state.wordsPerMinute));
  }

  /// Change the speech speed in read-aloud mode (applies from the next sentence)
  void _changeSpeechRate(int steps) {
    final rate = (_settings.speechRate + steps * RSVPSettings.speechRateStep)
        .clamp(RSVPSettings.minSpeechRate, RSVPSettings.maxSpeechRate)
        .toDouble();
    _narrator?.rate = rate;
    _changeSettings(_settings.copyWith(speechRate: rate));
  }

  /// Words per minute of the current mode, for the reading time estimate
  int get _effectiveWordsPerMinute =>
      _readingAloud ? (SpeechNarrator.normalWordsPerMinute * _settings.speechRate).round() : _settings.wordsPerMinute;

  @override
  Widget build(BuildContext context) {
    final state = _engine.state;
    final backgroundColor = Color(_settings.backgroundColor);
    final textColor = Color(_settings.textColor);
    final orpColor = Color(_settings.orpHighlightColor);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onTap: _handleTap,
        onHorizontalDragEnd: _handleHorizontalDrag,
        child: Stack(
          children: [
            // Main RSVP display
            RSVPDisplay(
              word: state.currentToken?.word ?? '',
              fontSize: _settings.fontSize,
              textColor: textColor,
              orpColor: orpColor,
              backgroundColor: backgroundColor,
              fontFamily: _settings.fontFamily,
              showHighlight: _settings.showORPHighlight,
              showFocusGuides: _settings.showFocusGuides,
            ),

            // Controls overlay
            if (_showControls || !state.isPlaying) _buildControlsOverlay(state, textColor, orpColor),

            // Progress slider at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildProgressSlider(state, textColor, orpColor),
            ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor.withValues(alpha: 0.7)),
                onPressed: () {
                  _engine.pause();
                  Navigator.of(context).pop(_engine.state.currentIndex);
                },
              ),
            ),

            // Read-aloud and context view buttons (top right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    tooltip: _readingAloud ? 'Sesli okumayı kapat' : 'Sesli oku',
                    icon: Icon(
                      _readingAloud ? Icons.headphones : Icons.headphones_outlined,
                      color: _readingAloud ? orpColor : textColor.withValues(alpha: 0.7),
                    ),
                    onPressed: () => _setReadAloud(!_readingAloud),
                  ),
                  IconButton(
                    icon: Icon(Icons.article, color: textColor.withValues(alpha: 0.7)),
                    onPressed: () {
                      _engine.pause();
                      setState(() => _showContextView = true);
                    },
                  ),
                ],
              ),
            ),

            // Context view overlay
            if (_showContextView) _buildContextViewOverlay(state, textColor, orpColor, backgroundColor),

            // Completion overlay (shown when reading finishes)
            if (state.isComplete) _buildCompletionOverlay(textColor, orpColor),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(
    RSVPPlaybackState state,
    Color textColor,
    Color accentColor,
  ) {
    final playButton = IconButton(
      iconSize: _compactControls ? 44 : 64,
      icon: Icon(
        state.isPlaying ? Icons.pause_circle : Icons.play_circle,
        color: accentColor,
      ),
      onPressed: _handleTap,
    );

    // A short window (a phone in landscape, split screen): one row without
    // the title, so the controls stay above the word in the middle
    if (_compactControls) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              playButton,
              const SizedBox(width: 8),
              _buildSpeedControl(textColor, accentColor),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // Top section: Title + Play button + Speed control
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                // Title
                if (widget.title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      widget.title!,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Play/Pause button
                playButton,

                const SizedBox(height: 8),

                // Speed control
                _buildSpeedControl(textColor, accentColor),

                if (state.isComplete)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Okuma Tamamlandı!',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Spacer - word display area in the middle
          const Spacer(),
        ],
      ),
    );
  }

  /// Whether the window is too short for the stacked controls above the
  /// word
  bool get _compactControls => MediaQuery.sizeOf(context).height < 500;

  /// Format seconds to "X dk Y sn" format
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins dk $secs sn';
  }

  Widget _buildSpeedControl(Color textColor, Color accentColor) {
    // Calculate estimated reading time in seconds
    final totalWords = _wordsBefore.last;
    final remainingWords = totalWords - _wordsBefore[_engine.state.currentIndex.clamp(0, _tokens.length)];
    final wordsPerMinute = _effectiveWordsPerMinute;
    final totalSeconds = (totalWords / wordsPerMinute * 60).round();
    final remainingSeconds = (remainingWords / wordsPerMinute * 60).round();
    final aloud = _readingAloud;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: textColor),
              onPressed: aloud
                  ? () => _changeSpeechRate(-1)
                  : () => _updateSpeed(_settings.wordsPerMinute - RSVPSettings.wordsPerMinuteStep),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: accentColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                aloud ? 'Ses ${speechRateLabel(_settings.speechRate)}' : '${_settings.wordsPerMinute} WPM',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: textColor),
              onPressed: aloud
                  ? () => _changeSpeechRate(1)
                  : () => _updateSpeed(_settings.wordsPerMinute + RSVPSettings.wordsPerMinuteStep),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${aloud ? 'Sesli okuma · ' : ''}Kalan: ${_formatTime(remainingSeconds)} / Toplam: ${_formatTime(totalSeconds)}',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.75),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSlider(RSVPPlaybackState state, Color textColor, Color accentColor) {
    final maxIndex = state.totalTokens > 0 ? state.totalTokens - 1 : 0;
    final displayIndex = (_isDraggingSlider ? _previewIndex : state.currentIndex).clamp(0, maxIndex);
    // Fade into the theme's own background, so the text stays readable in
    // light themes too
    final backgroundColor = Color(_settings.backgroundColor);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor.withValues(alpha: 0),
            backgroundColor.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Context preview when dragging
          if (_isDraggingSlider)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color.alphaBlend(textColor.withValues(alpha: 0.08), backgroundColor),
                border: Border.all(color: textColor.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text.rich(
                _contextPreview(_previewIndex, accentColor),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Progress info
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${displayIndex + 1} / ${state.totalTokens}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: textColor.withValues(alpha: 0.24),
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: displayIndex.toDouble(),
              min: 0,
              max: maxIndex.toDouble(),
              onChangeStart: (value) {
                setState(() {
                  _isDraggingSlider = true;
                  _previewIndex = value.round();
                });
                _engine.pause();
              },
              onChanged: (value) {
                setState(() {
                  _previewIndex = value.round();
                });
              },
              onChangeEnd: (value) {
                _engine.seekToIndex(value.round());
                setState(() {
                  _isDraggingSlider = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The words around [index], with the word at [index] highlighted
  TextSpan _contextPreview(int index, Color highlightColor) {
    if (_tokens.isEmpty) return const TextSpan();

    final start = (index - 3).clamp(0, _tokens.length - 1);
    final end = (index + 4).clamp(0, _tokens.length);

    return TextSpan(children: [
      for (int i = start; i < end; i++) ...[
        if (i > start) const TextSpan(text: ' '),
        i == index
            ? TextSpan(
                text: _tokens[i].word,
                style: TextStyle(color: highlightColor, fontWeight: FontWeight.bold),
              )
            : TextSpan(text: _tokens[i].word),
      ],
    ]);
  }

  /// Build context view overlay showing full page with current word highlighted
  Widget _buildContextViewOverlay(
    RSVPPlaybackState state,
    Color textColor,
    Color orpColor,
    Color backgroundColor,
  ) {
    final currentIndex = state.currentIndex;

    // Show ~200 words: ±100 from current position
    final start = (currentIndex - 100).clamp(0, _tokens.length - 1);
    final end = (currentIndex + 100).clamp(0, _tokens.length);

    // Build text spans with current word highlighted
    final spans = <TextSpan>[];
    for (int i = start; i < end; i++) {
      final word = _tokens[i].word;
      final isCurrentWord = i == currentIndex;

      spans.add(TextSpan(
        text: word,
        style: TextStyle(
          color: isCurrentWord ? orpColor : textColor,
          fontWeight: isCurrentWord ? FontWeight.bold : FontWeight.normal,
          backgroundColor: isCurrentWord ? orpColor.withValues(alpha: 0.2) : null,
          fontSize: 16,
          height: 1.6,
        ),
      ));

      // Add space after word (except for punctuation)
      if (i < end - 1 && !_isPunctuation(_tokens[i + 1].word)) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return GestureDetector(
      onTap: () => setState(() => _showContextView = false),
      child: Container(
        color: backgroundColor.withValues(alpha: 0.95),
        child: SafeArea(
          child: Column(
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sayfa Görünümü',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => setState(() => _showContextView = false),
                    ),
                  ],
                ),
              ),

              // Scrollable text content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: RichText(
                    text: TextSpan(
                      children: spans,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),

              // Position info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Kelime ${_wordsBefore[currentIndex] + 1} / ${_wordsBefore.last}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if a word is punctuation only
  bool _isPunctuation(String word) {
    const punctuationChars = '.,!?;:"\'-()[]';
    return word.split('').every((c) => punctuationChars.contains(c));
  }

  /// The chapter after the current one, in the order of [seriesChapters]
  /// (the Quran can be read in revelation or mushaf order)
  Book? _getNextChapter() {
    final chapters = widget.seriesChapters;
    final currentChapter = widget.currentBook?.chapterNumber;
    if (chapters == null || currentChapter == null) return null;

    final currentIndex = chapters.indexWhere((b) => b.chapterNumber == currentChapter);
    if (currentIndex == -1 || currentIndex == chapters.length - 1) return null;

    return chapters[currentIndex + 1];
  }

  /// Navigate to the next chapter
  void _openNextChapter(Book nextChapter) {
    ReaderScreen.open(
      context,
      book: nextChapter,
      // Same title format as the chapter list
      title: '${BookService.seriesDisplayName(nextChapter.seriesName ?? '')} - ${nextChapter.title}',
      settings: _settings,
      seriesChapters: widget.seriesChapters,
      onSettingsChanged: widget.onSettingsChanged,
      replace: true,
    );
  }

  /// Build completion overlay with next chapter button
  Widget _buildCompletionOverlay(Color textColor, Color accentColor) {
    final nextChapter = _getNextChapter();

    // Taps and swipes beside the buttons must not reach the reader below
    // (a tap would restart the chapter)
    return GestureDetector(
      onTap: () {},
      onHorizontalDragEnd: (_) {},
      child: Container(
        // The theme's background (a fixed black made dark text unreadable)
        color: Color(_settings.backgroundColor).withValues(alpha: 0.95),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: accentColor),
                const SizedBox(height: 24),
                Text(
                  'Bölüm Tamamlandı!',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Next chapter button (if available)
                if (nextChapter != null) ...[
                  ElevatedButton.icon(
                    onPressed: () => _openNextChapter(nextChapter),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Sonraki Bölüm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      // Dark text on a light accent (the yellow of high contrast)
                      foregroundColor: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Return to home button
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home),
                  label: const Text('Ana Sayfaya Dön'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: textColor),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
