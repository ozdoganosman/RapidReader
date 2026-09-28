/// Home Screen - Library
///
/// Main entry point showing pre-loaded books in a beautiful grid.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../core/models/book.dart';
import '../../core/models/rsvp_settings.dart';
import '../../core/services/article_extractor.dart';
import '../../core/services/book_service.dart';
import '../../core/services/custom_book_service.dart';
import '../../core/services/document_importer.dart';
import '../../core/services/reading_storage.dart';
import '../../core/services/text_cleaner.dart';
import '../theme/app_colors.dart';
import '../widgets/banner_ad_widget.dart';
import 'chapter_list_screen.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

/// Home screen with book library
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RSVPSettings _settings = const RSVPSettings();
  List<Book> _books = []; // Books from assets/books/
  List<Book> _customBooks = []; // Custom books from SharedPreferences
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadSettings();
    _listenForShares();
  }

  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  /// Texts, links and files shared from other apps (Android "Share" menu)
  void _listenForShares() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    // Sharing is optional: never let it break the library (e.g. in tests)
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handleShared(files);
      ReceiveSharingIntent.instance.reset();
    }).catchError((Object e) => debugPrint('Share error: $e'));
    _shareSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handleShared, onError: (Object e) => debugPrint('Share error: $e'));
  }

  /// Put a shared text, the article of a shared link or a shared document
  /// into the add dialog
  Future<void> _handleShared(List<SharedMediaFile> files) async {
    if (files.isEmpty || !mounted) return;
    final shared = files.first;
    String? title;
    String? author;
    String content;
    try {
      if (shared.type == SharedMediaType.file) {
        final bytes = await File(shared.path).readAsBytes();
        final document = await DocumentImporter.read(_sharedFileName(shared), bytes);
        title = document.title;
        author = document.author;
        content = document.content;
      } else if (shared.type == SharedMediaType.text || shared.type == SharedMediaType.url) {
        final text = shared.path.trim();
        final link = ArticleExtractor.linkInSharedText(text);
        if (link != null) {
          final article = await ArticleExtractor.fetch(link);
          title = article.title;
          content = article.text;
        } else {
          // Text shared from a PDF viewer comes line by line
          content = TextCleaner.joinWrappedLines(text, onlyIfWrapped: true);
        }
      } else {
        return;
      }
    } catch (e) {
      if (mounted) {
        final message =
            e is ArticleException || e is DocumentImportException ? e.toString() : 'Paylaşılan içerik okunamadı';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red[400]));
      }
      return;
    }
    if (!mounted || content.trim().isEmpty) return;
    _showAddBookDialog(
      initialTitle: title == null || title.isEmpty ? _titleFromText(content) : title,
      initialAuthor: author,
      initialContent: content,
    );
  }

  /// File name with an extension DocumentImporter understands
  static String _sharedFileName(SharedMediaFile file) {
    final name = file.path.split('/').last;
    if (name.contains('.')) return name;
    const extensions = {'application/pdf': 'pdf', 'application/epub+zip': 'epub', 'text/plain': 'txt'};
    return '$name.${extensions[file.mimeType] ?? 'txt'}';
  }

  /// Restore the settings saved on this device
  Future<void> _loadSettings() async {
    final settings = await ReadingStorage.loadSettings();
    if (mounted) setState(() => _settings = settings);
  }

  /// Apply and save settings (from the settings screen or the reader)
  void _saveSettings(RSVPSettings settings) {
    setState(() => _settings = settings);
    ReadingStorage.saveSettings(settings);
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);

    // Load both asset books and custom books
    final books = await BookService.loadBooks();
    final customBooks = await CustomBookService.loadCustomBooks();

    setState(() {
      _books = books;
      _customBooks = customBooks;
      _isLoading = false;
    });
  }

  List<Book> get _allBooks => [..._books, ..._customBooks]; // Combine asset and custom books

  /// Group books into series and standalone books
  /// Returns a list of "display items" - either a series representative or standalone book
  List<dynamic> get _displayItems {
    final items = <dynamic>[];
    final Map<String, List<Book>> seriesMap = {};
    final List<Book> standaloneBooks = [];

    for (final book in _allBooks) {
      if (book.isSeries && book.seriesName != null) {
        seriesMap.putIfAbsent(book.seriesName!, () => []);
        seriesMap[book.seriesName!]!.add(book);
      } else {
        standaloneBooks.add(book);
      }
    }

    // Add series (represented by first chapter)
    seriesMap.forEach((seriesName, chapters) {
      chapters.sort((a, b) => (a.chapterNumber ?? 0).compareTo(b.chapterNumber ?? 0));
      items.add({'type': 'series', 'seriesName': seriesName, 'chapters': chapters});
    });

    // Add standalone books
    for (final book in standaloneBooks) {
      items.add({'type': 'book', 'book': book});
    }

    return items;
  }

  void _openBook(Book book) {
    ReaderScreen.open(
      context,
      book: book,
      title: book.title,
      settings: _settings,
      onSettingsChanged: _saveSettings,
    );
  }

  void _openSeries(String seriesName, List<Book> chapters) {
    final route = MaterialPageRoute<void>(
      builder: (context) => ChapterListScreen(
        seriesName: seriesName,
        chapters: chapters,
        settings: _settings,
        onSettingsChanged: _saveSettings,
      ),
    );
    Navigator.of(context).push(route);
  }

  void _openSettings() async {
    final newSettings = await Navigator.of(context).push<RSVPSettings>(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(settings: _settings),
      ),
    );

    if (newSettings != null) {
      _saveSettings(newSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black54),
            )
          : _buildLibrary(),
      bottomNavigationBar: kIsWeb ? null : const BannerAdWidget(),
    );
  }

  Widget _buildLibrary() {
    return CustomScrollView(
      slivers: [
        // Minimal header
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),

        // Section title with thin line
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Kitaplık',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: Colors.black87,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_displayItems.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 0.5,
                  color: Colors.black12,
                ),
              ],
            ),
          ),
        ),

        // Book grid - minimal design
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return _buildAddCard();
                }
                final item = _displayItems[index - 1];
                // The cards size their parts by the cell height
                return LayoutBuilder(
                  builder: (context, cell) => item['type'] == 'series'
                      ? _buildSeriesCard(
                          item['seriesName'] as String,
                          item['chapters'] as List<Book>,
                          cardHeight: cell.maxHeight,
                        )
                      : _buildBookCard(item['book'] as Book, index - 1, cardHeight: cell.maxHeight),
                );
              },
              childCount: _displayItems.length + 1,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 20,
        24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with title and settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'RapidReader',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.black87,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined),
                color: Colors.black45,
                iconSize: 24,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Speed indicator - minimal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.speed_outlined,
                  color: Colors.black45,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Okuma Hızı',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_settings.wordsPerMinute}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'kelime/dk',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _openSettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ayarla',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Decoded custom cover images, so base64 is not decoded on every build
  final _customCoverCache = <String, Uint8List>{};

  /// Cover image of a book: bundled asset, custom image or a placeholder icon
  Widget _buildCoverImage(Book book, IconData placeholderIcon) {
    final Widget image;
    if (book.coverAsset != null) {
      image = Image.asset(book.coverAsset!, fit: BoxFit.cover);
    } else if (book.imageBase64 != null && book.imageBase64!.isNotEmpty) {
      final bytes = _customCoverCache.putIfAbsent(
        book.id,
        () => base64Decode(book.imageBase64!),
      );
      image = Image.memory(bytes, fit: BoxFit.cover);
    } else {
      return Center(
        child: Icon(
          placeholderIcon,
          size: 40,
          color: Colors.black38,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      child: image,
    );
  }

  Widget _buildSeriesCard(String seriesName, List<Book> chapters, {required double cardHeight}) {
    final firstChapter = chapters.first;
    final totalWords = chapters.fold<int>(0, (sum, ch) => sum + ch.wordCount);

    // Map series names to display names
    final displayName = BookService.seriesDisplayName(seriesName);

    // The Quran files list the book name as author; describe the text instead
    final author = seriesName.toLowerCase() == 'kuran' ? 'Arapça aslından meal' : firstChapter.author;

    return GestureDetector(
      onTap: () => _openSeries(displayName, chapters),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover area
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
                child: _buildCoverImage(firstChapter, Icons.library_books_outlined),
              ),
            ),

            // Info area: at least its 2/5 of the card, more when the text
            // needs it (small phones, larger system text); the cover gives way
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: cardHeight * 0.4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          author,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${chapters.length} bölüm · ${_formatTotalTime(totalWords)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book, int index, {required double cardHeight}) {
    return GestureDetector(
      onTap: () => _openBook(book),
      onLongPress: book.isCustomBook ? () => _showCustomBookOptions(book) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover area
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    child: _buildCoverImage(book, Icons.auto_stories_outlined),
                  ),
                ),

                // Info area: at least its 2/5 of the card, more when the text
                // needs it (small phones, larger system text); the cover gives way
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cardHeight * 0.4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              book.author,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${book.wordCount} kelime',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            Icon(
                              Icons.play_arrow,
                              size: 14,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Delete button for custom books
            if (book.isCustomBook)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _deleteCustomBook(book),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCard() {
    return GestureDetector(
      onTap: _showAddBookDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.08),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
              ),
              child: Icon(
                Icons.add,
                size: 32,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Metin Ekle',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kendi metnini ekle',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBookDialog({String? initialTitle, String? initialAuthor, String? initialContent}) {
    final titleController = TextEditingController(text: initialTitle);
    final authorController = TextEditingController(text: initialAuthor);
    final contentController = TextEditingController(text: initialContent);
    String? selectedImageBase64;
    bool importing = false;
    // While saving, the buttons are off and the dialog stays open: a second
    // tap saved the text twice and popped the library screen too
    bool saving = false;
    // Shown under the empty required fields (a snack bar was hidden behind
    // the dialog)
    bool titleMissing = false;
    bool contentMissing = false;
    // Errors of the import buttons and of saving, shown in the dialog (a
    // snack bar would be behind it)
    String? notice;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.black54),
                const SizedBox(width: 12),
                Text(
                  'Yeni Metin Ekle',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image picker
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 400,
                          maxHeight: 600,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setDialogState(() {
                            selectedImageBase64 = base64Encode(bytes);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: selectedImageBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.memory(
                                  base64Decode(selectedImageBase64!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: Colors.black38,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kapak Resmi Ekle (Opsiyonel)',
                                    style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title field
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: Colors.black87),
                      onChanged: (_) {
                        if (titleMissing) setDialogState(() => titleMissing = false);
                      },
                      decoration: InputDecoration(
                        labelText: 'Başlık *',
                        errorText: titleMissing ? 'Başlık gerekli' : null,
                        labelStyle: TextStyle(color: AppColors.secondaryText),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.black38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Author field
                    TextField(
                      controller: authorController,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Yazar (Opsiyonel)',
                        labelStyle: TextStyle(color: AppColors.secondaryText),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.black38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Import the text from a file
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: importing
                            ? null
                            : () async {
                                setDialogState(() => importing = true);
                                try {
                                  final document = await DocumentImporter.pickAndRead();
                                  if (document != null) {
                                    if (titleController.text.trim().isEmpty) {
                                      titleController.text = document.title;
                                    }
                                    if (authorController.text.trim().isEmpty && document.author != null) {
                                      authorController.text = document.author!;
                                    }
                                    contentController.text = document.content;
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setDialogState(
                                      () => notice = e is DocumentImportException ? e.message : 'Dosya okunamadı: $e',
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setDialogState(() => importing = false);
                                  }
                                }
                              },
                        icon: importing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black45),
                              )
                            : const Icon(Icons.upload_file, size: 18),
                        label: Text(importing ? 'Dosya okunuyor…' : 'Dosyadan Yükle (TXT, PDF, EPUB)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondaryText,
                          side: BorderSide(color: Colors.black12),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Paste the clipboard or read a web article
                    Row(
                      children: [
                        Expanded(
                          child: _dialogButton(
                            icon: Icons.content_paste,
                            label: 'Panodan',
                            onPressed: importing
                                ? null
                                : () async {
                                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                                    final text = data?.text?.trim() ?? '';
                                    if (!context.mounted) return;
                                    if (text.isEmpty) {
                                      setDialogState(() => notice = 'Panoda metin yok');
                                      return;
                                    }
                                    if (ArticleExtractor.isUrl(text)) {
                                      // A copied link: read the page it points to
                                      setDialogState(() => importing = true);
                                      final error = await _fillFromArticle(text, titleController, contentController);
                                      if (context.mounted) {
                                        setDialogState(() {
                                          importing = false;
                                          notice = error;
                                        });
                                      }
                                      return;
                                    }
                                    // Lines of text copied from a PDF are joined into paragraphs
                                    contentController.text = TextCleaner.joinWrappedLines(text, onlyIfWrapped: true);
                                    setDialogState(() {
                                      notice = null;
                                      contentMissing = false;
                                    });
                                    if (titleController.text.trim().isEmpty) {
                                      titleController.text = _titleFromText(text);
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dialogButton(
                            icon: Icons.link,
                            label: 'Web Adresi',
                            onPressed: importing
                                ? null
                                : () async {
                                    final url = await _askUrl(context);
                                    if (url == null || !context.mounted) return;
                                    setDialogState(() => importing = true);
                                    final error = await _fillFromArticle(url, titleController, contentController);
                                    if (context.mounted) {
                                      setDialogState(() {
                                        importing = false;
                                        notice = error;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    if (notice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(notice!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                      ),
                    const SizedBox(height: 12),
                    // Content field
                    TextField(
                      controller: contentController,
                      style: TextStyle(color: Colors.black87),
                      maxLines: 6,
                      onChanged: (_) {
                        if (contentMissing) setDialogState(() => contentMissing = false);
                      },
                      decoration: InputDecoration(
                        labelText: 'Metin İçeriği *',
                        errorText: contentMissing ? 'Metin gerekli' : null,
                        alignLabelWithHint: true,
                        labelStyle: TextStyle(color: AppColors.secondaryText),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.black38),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'İptal',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () {
                        final content = contentController.text.trim();
                        if (content.isEmpty) {
                          setDialogState(() => contentMissing = true);
                          return;
                        }
                        final title = titleController.text.trim();
                        Navigator.of(context).pop();
                        _readWithoutSaving(title.isEmpty ? _titleFromText(content) : title, content);
                      },
                child: const Text('Kaydetmeden Oku', style: TextStyle(color: AppColors.secondaryText)),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (saving) return; // a second tap before the next frame
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                          setDialogState(() {
                            titleMissing = titleController.text.trim().isEmpty;
                            contentMissing = contentController.text.trim().isEmpty;
                          });
                          return;
                        }

                        setDialogState(() => saving = true);
                        try {
                          await CustomBookService.saveCustomBook(
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                            author: authorController.text.trim().isNotEmpty ? authorController.text.trim() : null,
                            imageBase64: selectedImageBase64,
                          );
                        } catch (e) {
                          // e.g. the device's storage is full
                          if (context.mounted) {
                            setDialogState(() {
                              saving = false;
                              notice = 'Metin kaydedilemedi. Cihazın depolama alanı için çok büyük olabilir.';
                            });
                          }
                          return;
                        }

                        if (!context.mounted) return;
                        navigator.pop();
                        if (mounted) _loadBooks(); // Refresh the list
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Metin başarıyla eklendi!'),
                            backgroundColor: Colors.black54,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogButton({required IconData icon, required String label, VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondaryText,
        side: BorderSide(color: Colors.black12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  /// A title for a text without one: its first line, shortened
  static String _titleFromText(String text) {
    final firstLine = text.trim().split('\n').first.trim();
    return firstLine.length <= 60 ? firstLine : '${firstLine.substring(0, 57)}…';
  }

  Future<String?> _askUrl(BuildContext context) async {
    final clipboard = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!context.mounted) return null;
    final controller = TextEditingController(text: ArticleExtractor.isUrl(clipboard) ? clipboard : '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Web makalesi', style: TextStyle(fontWeight: FontWeight.w400)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://...'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal', style: TextStyle(color: AppColors.secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Getir'),
          ),
        ],
      ),
    );
  }

  /// Download [url] and put its article into the add dialog; the error
  /// message if the page could not be read
  Future<String?> _fillFromArticle(
    String url,
    TextEditingController titleController,
    TextEditingController contentController,
  ) async {
    try {
      final article = await ArticleExtractor.fetch(url);
      contentController.text = article.text;
      if (titleController.text.trim().isEmpty) {
        titleController.text = article.title.isNotEmpty ? article.title : _titleFromText(article.text);
      }
      return null;
    } catch (e) {
      return e is ArticleException ? e.message : 'Sayfa okunamadı: $e';
    }
  }

  /// Open a text in the reader without adding it to the library
  void _readWithoutSaving(String title, String content) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => ReaderScreen(
        content: content,
        title: title,
        settings: _settings,
        onSettingsChanged: _saveSettings,
      ),
    ));
  }

  void _deleteCustomBook(Book book) {
    // Off while deleting: a second tap popped the library screen too
    var deleting = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: !deleting,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(
              'Metni Sil',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
            ),
            content: Text(
              '"${book.title}" metnini silmek istediğinize emin misiniz?',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'İptal',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ),
              ElevatedButton(
                onPressed: deleting
                    ? null
                    : () async {
                        if (deleting) return; // a second tap before the next frame
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => deleting = true);
                        await CustomBookService.deleteCustomBook(book.id);
                        if (!context.mounted) return;
                        navigator.pop();
                        if (mounted) _loadBooks();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Metin silindi'),
                            backgroundColor: Colors.black54,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomBookOptions(Book book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red[400]),
            title: Text('Metni Sil', style: TextStyle(color: Colors.black87)),
            onTap: () {
              Navigator.pop(context);
              _deleteCustomBook(book);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Format total reading time based on word count and user's WPM settings
  String _formatTotalTime(int totalWords) {
    if (totalWords == 0) return '0 dk';

    // Use user's WPM setting
    final wpm = _settings.wordsPerMinute;

    // Calculate total minutes based on word count and WPM
    final totalMinutes = (totalWords / wpm).ceil();

    if (totalMinutes < 60) {
      return '$totalMinutes dk';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '$hours sa';
      }
      return '$hours sa $minutes dk';
    }
  }
}
