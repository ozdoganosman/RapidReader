/// Reader Screen - Main RSVP reading interface
///
/// Full-screen reading experience with:
/// - Centered word display with ORP highlighting
/// - Tap to play/pause
/// - Swipe to seek
/// - Speed controls
/// - Progress indicator
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  }

  void _exitImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

            // Progress bar at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildProgressBar(state, orpColor),
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
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
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
              iconSize: 80,
              icon: Icon(
                state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: accentColor,
              ),
              onPressed: _handleTap,
            ),

            const SizedBox(height: 32),

            // Speed control
            _buildSpeedControl(textColor, accentColor),

            const SizedBox(height: 24),

            // Progress info
            Text(
              '${state.currentIndex + 1} / ${state.totalTokens}',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),

            if (state.isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Okuma Tamamlandi!',
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

  Widget _buildProgressBar(RSVPPlaybackState state, Color accentColor) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        _engine.seekTo(progress);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          minHeight: 4,
        ),
      ),
    );
  }
}
