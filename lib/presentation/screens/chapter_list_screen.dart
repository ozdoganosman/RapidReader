/// Chapter List Screen
///
/// Shows all chapters in a book series.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/quran.dart';
import '../../core/models/book.dart';
import '../../core/models/rsvp_settings.dart';
import '../../core/services/app_language.dart';
import '../../core/services/reading_storage.dart';
import '../route_observer.dart';
import '../theme/app_colors.dart';
import 'arabic_surah_screen.dart';
import 'reader_screen.dart';

class ChapterListScreen extends StatefulWidget {
  final String seriesName;
  final List<Book> chapters;
  final RSVPSettings settings;

  /// Callback when settings change in the reader (e.g. speed)
  final ValueChanged<RSVPSettings>? onSettingsChanged;

  const ChapterListScreen({
    super.key,
    required this.seriesName,
    required this.chapters,
    required this.settings,
    this.onSettingsChanged,
  });

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> with RouteAware {
  /// Settings, updated when the speed is changed while reading a chapter
  late RSVPSettings _settings = widget.settings;

  /// How far each chapter was read (0-1), by book id
  Map<String, double> _progress = {};

  /// Remembers whether the Quran is listed in mushaf order
  static const _mushafOrderKey = 'quran_mushaf_order';

  /// The meal gets surah search, an order switch and the Arabic text
  late final bool _isQuran = widget.chapters.isNotEmpty && widget.chapters.first.seriesName == quranSeriesName;

  bool _mushafOrder = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (_isQuran) _loadOrder();
    _loadProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  /// Back from reading a chapter
  @override
  void didPopNext() => _loadProgress();

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final progress = <String, double>{};
    for (final chapter in widget.chapters) {
      final saved = await ReadingStorage.loadProgress(chapter.id);
      if (saved != null && saved.total > 0) progress[chapter.id] = (saved.index / saved.total).clamp(0.0, 1.0);
    }
    if (mounted) setState(() => _progress = progress);
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final mushafOrder = prefs.getBool(_mushafOrderKey) ?? false;
    if (mounted && mushafOrder != _mushafOrder) setState(() => _mushafOrder = mushafOrder);
  }

  Future<void> _setMushafOrder(bool mushafOrder) async {
    setState(() => _mushafOrder = mushafOrder);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mushafOrderKey, mushafOrder);
  }

  /// Surah number in mushaf order (the meal files are in order of revelation)
  int _mushafNumber(Book chapter) => quranMushafNumber(chapter.chapterNumber ?? 1);

  /// Search by surah name or by its number in either order
  bool _matchesQuery(Book chapter) {
    final query = normalizeForSearch(_query.trim());
    if (query.isEmpty) return true;
    final number = int.tryParse(query);
    if (number != null) return number == chapter.chapterNumber || number == _mushafNumber(chapter);
    return normalizeForSearch(chapter.title).contains(query);
  }

  void _onSettingsChanged(RSVPSettings settings) {
    // Rebuild so the reading times follow a speed change made in the reader
    if (mounted) setState(() => _settings = settings);
    widget.onSettingsChanged?.call(settings);
  }

  @override
  Widget build(BuildContext context) {
    // Sort chapters by chapter number (the Quran optionally in mushaf order)
    final orderedChapters = List<Book>.from(widget.chapters)
      ..sort((a, b) => (a.chapterNumber ?? 0).compareTo(b.chapterNumber ?? 0));
    if (_isQuran && _mushafOrder) orderedChapters.sort((a, b) => _mushafNumber(a).compareTo(_mushafNumber(b)));
    final sortedChapters = _isQuran ? orderedChapters.where(_matchesQuery).toList() : orderedChapters;
    final header = _isQuran ? 1 : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.seriesName,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: Colors.black12,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: sortedChapters.length + header,
        itemBuilder: (context, index) {
          if (index < header) return _buildQuranControls();
          final chapter = sortedChapters[index - header];
          return _buildChapterCard(context, chapter, orderedChapters);
        },
      ),
    );
  }

  /// Surah search and the order switch (Quran only)
  Widget _buildQuranControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: context.l10n.searchSurah,
              hintStyle: const TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w300),
              prefixIcon: const Icon(Icons.search, color: Colors.black45),
              isDense: true,
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(context.l10n.revelationOrder)),
              ButtonSegment(value: true, label: Text(context.l10n.mushafOrder)),
            ],
            selected: {_mushafOrder},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => _setMushafOrder(selection.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Colors.black87,
              selectedForegroundColor: Colors.white,
              foregroundColor: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  /// [orderedChapters]: all chapters in the shown order ("Sonraki Bölüm"
  /// follows it)
  Widget _buildChapterCard(BuildContext context, Book chapter, List<Book> orderedChapters) {
    final mushafNumber = _isQuran ? _mushafNumber(chapter) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ReaderScreen.open(
            context,
            book: chapter,
            title: '${widget.seriesName} - ${chapter.title}',
            settings: _settings,
            seriesChapters: orderedChapters,
            onSettingsChanged: _onSettingsChanged,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                // Chapter number
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${_isQuran && _mushafOrder ? mushafNumber : chapter.chapterNumber}',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Chapter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chapter title (sure name)
                      Text(
                        chapter.title,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Word count and reading time (wraps on narrow phones)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            context.l10n.wordCount(chapter.wordCount),
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            _formatReadingTime(chapter.wordCount, _settings.wordsPerMinute),
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          // The surah's number in the other order
                          if (mushafNumber != null)
                            Text(
                              '  ·  ${_mushafOrder ? context.l10n.revelationNumber(chapter.chapterNumber ?? 0) : context.l10n.mushafNumber(mushafNumber)}',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arabic text of the surah
                if (mushafNumber != null)
                  IconButton(
                    tooltip: context.l10n.arabicText,
                    icon: const Text('ع', style: TextStyle(fontSize: 20, color: AppColors.secondaryText)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ArabicSurahScreen(mushafNumber: mushafNumber, title: chapter.title),
                      ),
                    ),
                  ),

                // How far it was read: done, or a percentage
                if ((_progress[chapter.id] ?? 0) >= 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle, size: 18, color: Colors.green),
                  )
                else if ((_progress[chapter.id] ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      context.l10n.percent(((_progress[chapter.id] ?? 0) * 100).round()),
                      style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ),

                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.black38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format reading time with minutes and seconds
  String _formatReadingTime(int wordCount, int wpm) {
    final l10n = context.l10n;
    if (wordCount == 0) return l10n.durationSeconds(0);
    final totalSeconds = (wordCount / wpm * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes == 0) {
      return l10n.durationSeconds(seconds);
    } else if (seconds == 0) {
      return l10n.durationMinutes(minutes);
    } else {
      return l10n.durationMinutesSeconds(minutes, seconds);
    }
  }
}
