/// Reader Screen - Main RSVP reading interface
///
/// Full-screen reading experience with:
/// - Centered word display with ORP highlighting
/// - Tap to play/pause
/// - Swipe to seek
/// - Speed controls
/// - Progress indicator
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/models/rsvp_settings.dart';
import '../../core/models/word_token.dart';
import '../../core/services/rsvp_engine.dart';
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

  const ReaderScreen({
    super.key,
    required this.content,
    this.title,
    this.settings = const RSVPSettings(),
    this.startIndex = 0,
    this.onProgressChanged,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final RSVPEngine _engine;
  late RSVPSettings _settings;
  late List<WordToken> _tokens;
  bool _showControls = true;
  bool _isDraggingSlider = false;
  int _previewIndex = 0;
  bool _showContextView = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _engine = RSVPEngine();

    // Parse text into tokens
    _tokens = TextParser.parse(widget.content, chunkSize: _settings.chunkSize);

    // Initialize engine
    _engine.initialize(
      tokens: _tokens,
      config: TimingConfig(
        baseWPM: _settings.wordsPerMinute,
        adaptiveSpeed: _settings.adaptiveSpeed,
        microPauseInterval: _settings.microPauseInterval,
        microPauseDuration: _settings.microPauseDuration,
      ),
      startIndex: widget.startIndex,
    );

    // Listen for progress changes
    _engine.addListener(_onEngineStateChanged);

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
    }
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineStateChanged);
    _engine.dispose();
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
    setState(() {
      _settings = _settings.copyWith(wordsPerMinute: wpm);
    });
    _engine.setSpeed(wpm);
  }

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
            if (_showControls || !state.isPlaying)
              _buildControlsOverlay(state, textColor, orpColor),

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
                icon: Icon(Icons.arrow_back, color: textColor.withOpacity(0.7)),
                onPressed: () {
                  _engine.pause();
                  Navigator.of(context).pop(_engine.state.currentIndex);
                },
              ),
            ),

            // Context view button (top right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.article, color: textColor.withOpacity(0.7)),
                onPressed: () {
                  _engine.pause();
                  setState(() => _showContextView = true);
                },
              ),
            ),

            // Context view overlay
            if (_showContextView)
              _buildContextViewOverlay(state, textColor, orpColor, backgroundColor),
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
                        color: textColor.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Play/Pause button
                IconButton(
                  iconSize: 64,
                  icon: Icon(
                    state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: accentColor,
                  ),
                  onPressed: _handleTap,
                ),

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

  Widget _buildSpeedControl(Color textColor, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: textColor),
          onPressed: () => _updateSpeed(_settings.wordsPerMinute - 50),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: accentColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_settings.wordsPerMinute} WPM',
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
          onPressed: () => _updateSpeed(_settings.wordsPerMinute + 50),
        ),
      ],
    );
  }

  Widget _buildProgressSlider(RSVPPlaybackState state, Color textColor, Color accentColor) {
    final displayIndex = _isDraggingSlider ? _previewIndex : state.currentIndex;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
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
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getContextPreview(_previewIndex),
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
                color: textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: Colors.white24,
              thumbColor: accentColor,
              overlayColor: accentColor.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: displayIndex.toDouble(),
              min: 0,
              max: (state.totalTokens - 1).toDouble().clamp(0, double.infinity),
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
                _engine.seekTo(value / (state.totalTokens - 1).clamp(1, double.infinity));
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

  /// Get context preview showing surrounding words
  String _getContextPreview(int index) {
    if (_tokens.isEmpty) return '';

    final start = (index - 3).clamp(0, _tokens.length - 1);
    final end = (index + 4).clamp(0, _tokens.length);

    final words = <String>[];
    for (int i = start; i < end; i++) {
      if (i == index) {
        words.add('【${_tokens[i].word}】');
      } else {
        words.add(_tokens[i].word);
      }
    }

    return words.join(' ');
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
          backgroundColor: isCurrentWord ? orpColor.withOpacity(0.2) : null,
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
        color: backgroundColor.withOpacity(0.95),
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
                  'Kelime ${currentIndex + 1} / ${state.totalTokens}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
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
}
