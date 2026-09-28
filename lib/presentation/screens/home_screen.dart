/// Home Screen - Library
///
/// Main entry point showing pre-loaded books in a beautiful grid.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/book.dart';
import '../../core/models/rsvp_settings.dart';
import '../../core/services/book_service.dart';
import '../../core/services/custom_book_service.dart';
import '../../core/services/document_importer.dart';
import '../../core/services/reading_storage.dart';
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterListScreen(
          seriesName: seriesName,
          chapters: chapters,
          settings: _settings,
          onSettingsChanged: _saveSettings,
        ),
      ),
    );
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
                        fontWeight: FontWeight.w300,
                        color: Colors.black38,
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
                if (item['type'] == 'series') {
                  return _buildSeriesCard(
                    item['seriesName'] as String,
                    item['chapters'] as List<Book>,
                  );
                } else {
                  return _buildBookCard(item['book'] as Book, index - 1);
                }
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
                      fontWeight: FontWeight.w200,
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
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.speed_outlined,
                  color: Colors.black38,
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
                          fontWeight: FontWeight.w300,
                          color: Colors.black45,
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
                              fontWeight: FontWeight.w200,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'kelime/dk',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Colors.black38,
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
                        color: Colors.black54,
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
          color: Colors.black26,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      child: image,
    );
  }

  Widget _buildSeriesCard(String seriesName, List<Book> chapters) {
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

            // Info area
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                ),
                child: Column(
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
                            fontWeight: FontWeight.w300,
                            color: Colors.black45,
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
                              fontWeight: FontWeight.w300,
                              color: Colors.black38,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.black26,
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

  Widget _buildBookCard(Book book, int index) {
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

                // Info area
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                      ),
                    ),
                    child: Column(
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
                                fontWeight: FontWeight.w300,
                                color: Colors.black45,
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
                                fontWeight: FontWeight.w300,
                                color: Colors.black38,
                              ),
                            ),
                            Icon(
                              Icons.play_arrow,
                              size: 14,
                              color: Colors.black26,
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
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Metin Ekle',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kendi metnini ekle',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBookDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final contentController = TextEditingController();
    String? selectedImageBase64;
    bool importing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                                  color: Colors.black26,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kapak Resmi Ekle (Opsiyonel)',
                                  style: TextStyle(
                                    color: Colors.black38,
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
                    decoration: InputDecoration(
                      labelText: 'Başlık *',
                      labelStyle: TextStyle(color: Colors.black45),
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
                      labelStyle: TextStyle(color: Colors.black45),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e is DocumentImportException ? e.message : 'Dosya okunamadı: $e',
                                      ),
                                      backgroundColor: Colors.red[400],
                                    ),
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
                        foregroundColor: Colors.black54,
                        side: BorderSide(color: Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Content field
                  TextField(
                    controller: contentController,
                    style: TextStyle(color: Colors.black87),
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Metin İçeriği *',
                      alignLabelWithHint: true,
                      labelStyle: TextStyle(color: Colors.black45),
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.black45),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Başlık ve içerik zorunludur'),
                      backgroundColor: Colors.red[400],
                    ),
                  );
                  return;
                }

                try {
                  await CustomBookService.saveCustomBook(
                    title: titleController.text.trim(),
                    content: contentController.text.trim(),
                    author: authorController.text.trim().isNotEmpty
                        ? authorController.text.trim()
                        : null,
                    imageBase64: selectedImageBase64,
                  );
                } catch (e) {
                  // e.g. the browser's storage limit (about 5 MB) was reached
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Metin kaydedilemedi. Cihazın depolama alanı için çok büyük olabilir.'),
                        backgroundColor: Colors.red[400],
                      ),
                    );
                  }
                  return;
                }

                if (mounted) {
                  Navigator.of(context).pop();
                  _loadBooks(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Metin başarıyla eklendi!'),
                      backgroundColor: Colors.black54,
                    ),
                  );
                }
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
    );
  }

  void _deleteCustomBook(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'İptal',
              style: TextStyle(color: Colors.black45),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await CustomBookService.deleteCustomBook(book.id);
              if (mounted) {
                Navigator.of(context).pop();
                _loadBooks();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Metin silindi'),
                    backgroundColor: Colors.black54,
                  ),
                );
              }
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
