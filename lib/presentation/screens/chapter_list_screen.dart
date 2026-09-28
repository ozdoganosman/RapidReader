/// Chapter List Screen
///
/// Shows all chapters in a book series.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/book.dart';
import '../../core/models/rsvp_settings.dart';
import 'reader_screen.dart';

class ChapterListScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends ConsumerState<ChapterListScreen> {
  /// Settings, updated when the speed is changed while reading a chapter
  late RSVPSettings _settings = widget.settings;

  void _onSettingsChanged(RSVPSettings settings) {
    _settings = settings;
    widget.onSettingsChanged?.call(settings);
  }

  @override
  Widget build(BuildContext context) {
    // Sort chapters by chapter number
    final sortedChapters = List<Book>.from(widget.chapters)
      ..sort((a, b) => (a.chapterNumber ?? 0).compareTo(b.chapterNumber ?? 0));

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
        itemCount: sortedChapters.length,
        itemBuilder: (context, index) {
          final chapter = sortedChapters[index];
          return _buildChapterCard(context, chapter, index);
        },
      ),
    );
  }

  Widget _buildChapterCard(BuildContext context, Book chapter, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReaderScreen(
                  content: chapter.content,
                  title: '${widget.seriesName} - ${chapter.title}',
                  settings: _settings,
                  currentBook: chapter,
                  seriesChapters: widget.chapters,
                  onSettingsChanged: _onSettingsChanged,
                ),
              ),
            );
          },
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
                      color: Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${chapter.chapterNumber}',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
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
                      // Word count and reading time
                      Row(
                        children: [
                          Text(
                            '${chapter.wordCount} kelime',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
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
                            '${_formatReadingTime(chapter.wordCount, 800)} - ${_formatReadingTime(chapter.wordCount, 300)}',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.black26,
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
    if (wordCount == 0) return '0 sn';
    final totalSeconds = (wordCount / wpm * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes == 0) {
      return '$seconds sn';
    } else if (seconds == 0) {
      return '$minutes dk';
    } else {
      return '$minutes dk $seconds sn';
    }
  }
}
