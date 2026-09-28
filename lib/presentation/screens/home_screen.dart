/// Home Screen - Library and text input
///
/// Main entry point for the app with:
/// - Manual text input
/// - File import options
/// - Reading history
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/models/book.dart';
import '../../core/models/rsvp_settings.dart';
import '../../core/services/epub_extractor.dart';
import '../../core/services/library_storage.dart';
import '../../core/services/pdf_extractor.dart';
import '../../core/services/text_cleaner.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

/// Home screen with library and import options
class HomeScreen extends StatefulWidget {
  /// Settings and reading history storage
  final LibraryStorage storage;

  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  late RSVPSettings _settings;
  late List<Book> _books;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.storage.loadSettings();
    _books = widget.storage.recentBooks();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _importFile() async {
    setState(() => _isLoading = true);
    ({String content, String title, BookFormat format})? picked;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'epub'],
        withData: true, // Web için bytes yükle
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final extension = file.extension?.toLowerCase();

        String content;
        String title = file.name;
        final BookFormat format;

        switch (extension) {
          case 'txt':
            format = BookFormat.txt;
            // Web'de her zaman bytes kullan
            if (kIsWeb) {
              if (file.bytes != null) {
                content = utf8.decode(file.bytes!);
              } else {
                _showError('Dosya okunamadı');
                return;
              }
            } else {
              // Mobilde path veya bytes kullan
              if (file.path != null) {
                final ioFile = File(file.path!);
                content = await ioFile.readAsString();
              } else if (file.bytes != null) {
                content = utf8.decode(file.bytes!);
              } else {
                _showError('Dosya okunamadı');
                return;
              }
            }
            break;
          case 'pdf':
            format = BookFormat.pdf;
            // PDF metin çıkarma (web ve mobilde çalışır)
            if (file.bytes != null) {
              try {
                content = PdfExtractor.extractText(file.bytes!);
                if (content.trim().isEmpty) {
                  _showError('PDF dosyasından metin çıkarılamadı');
                  return;
                }
              } catch (e) {
                _showError('PDF okuma hatası: $e');
                return;
              }
            } else {
              _showError('PDF dosyası okunamadı');
              return;
            }
            break;
          case 'epub':
            format = BookFormat.epub;
            // EPUB metin çıkarma (web ve mobilde çalışır)
            if (file.bytes != null) {
              try {
                content = await EpubExtractor.extractText(file.bytes!);
                if (content.trim().isEmpty) {
                  _showError('EPUB dosyasından metin çıkarılamadı');
                  return;
                }
                // EPUB başlığını dosya adı yerine kullan
                final metadata = await EpubExtractor.getMetadata(file.bytes!);
                if (metadata.title.isNotEmpty && metadata.title != 'Bilinmeyen') {
                  title = metadata.title;
                }
              } catch (e) {
                _showError('EPUB okuma hatası: $e');
                return;
              }
            } else {
              _showError('EPUB dosyası okunamadı');
              return;
            }
            break;
          default:
            _showError('Desteklenmeyen dosya formatı');
            return;
        }

        if (content.trim().isEmpty) {
          _showError('Dosya boş veya okunamıyor');
          return;
        }

        // Otomatik metin temizleme (sayfa numaraları, ISBN, vb.)
        // EPUB zaten yapılandırılmış metin içerir; sayfa numarası/üstbilgi yoktur
        if (extension != 'epub') {
          content = TextCleaner.clean(content);
        }

        picked = (content: content, title: title, format: format);
      }
    } catch (e) {
      _showError('Dosya okunurken hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (picked != null) {
      await _startReading(picked.content, title: picked.title, format: picked.format);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Add the text to the reading history (or find it there) and open it
  Future<void> _startReading(
    String content, {
    required String title,
    required BookFormat format,
  }) async {
    if (content.trim().isEmpty) {
      _showError('Lütfen okumak için metin girin');
      return;
    }

    final book = await widget.storage.openBook(
      content: content,
      title: title,
      format: format,
    );
    await _openReader(book, content);
  }

  /// Continue a book from the reading history
  Future<void> _resumeBook(Book book) async {
    final content = await widget.storage.loadText(book.id);
    if (content == null) {
      _showError('Kitap metni bulunamadı');
      await _deleteBook(book);
      return;
    }

    final opened = await widget.storage.openBook(
      content: content,
      title: book.title,
      format: book.format,
    );
    await _openReader(opened, content);
  }

  Future<void> _openReader(Book book, String content) async {
    if (!mounted) return;

    // A finished book starts again from the beginning
    final resume = !book.isComplete && book.currentWordIndex > 0;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReaderScreen(
          content: content,
          title: book.title,
          settings: _settings,
          startIndex: resume ? book.currentWordIndex : 0,
          startIndexTotal: resume ? book.totalWords : null,
          onProgressChanged: (index, total) => widget.storage.saveProgress(
            book.id,
            wordIndex: index,
            totalWords: total,
          ),
          onSettingsChanged: _saveSettings,
        ),
      ),
    );

    if (mounted) setState(() => _books = widget.storage.recentBooks());
  }

  Future<void> _deleteBook(Book book) async {
    await widget.storage.deleteBook(book.id);
    if (mounted) setState(() => _books = widget.storage.recentBooks());
  }

  void _saveSettings(RSVPSettings settings) {
    setState(() => _settings = settings);
    widget.storage.saveSettings(settings);
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

  /// Short history title for pasted text: its first words
  static String _manualTitle(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    final title = words.take(6).join(' ');
    return words.length > 6 ? '$title…' : title;
  }

  void _showTextInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metin Gir'),
        content: TextField(
          controller: _textController,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Okumak istediğiniz metni buraya yapıştırın...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startReading(
                _textController.text,
                title: _manualTitle(_textController.text),
                format: BookFormat.manual,
              );
            },
            child: const Text('Okumaya Başla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RapidReader'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'RSVP Hızlı Okuma',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kelime kelime odaklanarak daha hızlı okuyun',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Speed indicator
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.speed),
                      title: const Text('Okuma Hızı'),
                      subtitle: Text('${_settings.wordsPerMinute} kelime/dakika'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openSettings,
                    ),
                  ),

                  // Reading history
                  if (_books.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Son Okunanlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final book in _books) _buildBookCard(book),
                  ],

                  const SizedBox(height: 24),

                  // Import options
                  const Text(
                    'Okumaya Başla',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Manual text input
                  _buildOptionCard(
                    icon: Icons.edit_note,
                    title: 'Metin Gir',
                    subtitle: 'Metni manuel olarak yapıştırın',
                    onTap: _showTextInputDialog,
                  ),

                  // Import file
                  _buildOptionCard(
                    icon: Icons.file_open,
                    title: 'Dosya Yükle',
                    subtitle: 'TXT, PDF veya EPUB dosyası seç',
                    onTap: _importFile,
                  ),

                  const SizedBox(height: 24),

                  // Demo text
                  const Text(
                    'Demo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildOptionCard(
                    icon: Icons.play_circle_outline,
                    title: 'Örnek Metni Oku',
                    subtitle: 'RSVP\'yi denemek için örnek metin',
                    onTap: () => _startReading(
                      _sampleText,
                      title: 'Örnek Metin',
                      format: BookFormat.manual,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBookCard(Book book) {
    final String status;
    if (book.isComplete) {
      status = 'Tamamlandı';
    } else if (book.totalWords == 0 || book.currentWordIndex == 0) {
      status = 'Henüz başlanmadı';
    } else {
      status = '%${(book.progress * 100).floor()} okundu';
    }

    return Card(
      child: ListTile(
        leading: Icon(_formatIcon(book.format), size: 32),
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            LinearProgressIndicator(value: book.progress.clamp(0.0, 1.0)),
            const SizedBox(height: 4),
            Text(status),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Geçmişten kaldır',
          onPressed: () => _deleteBook(book),
        ),
        onTap: () => _resumeBook(book),
      ),
    );
  }

  static IconData _formatIcon(BookFormat format) {
    switch (format) {
      case BookFormat.txt:
        return Icons.description;
      case BookFormat.pdf:
        return Icons.picture_as_pdf;
      case BookFormat.epub:
        return Icons.menu_book;
      case BookFormat.manual:
        return Icons.edit_note;
    }
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

/// Sample Turkish text for demo
const _sampleText = '''
Türkiye'nin en güzel şehirlerinden biri olan İstanbul, iki kıtanın buluşma noktasında yer alıyor. Boğaziçi, şehrin tam ortasından geçen ve Avrupa ile Asya'yı ayıran doğal bir su yolu. Her gün binlerce gemi bu boğazdan geçerek dünya ticaretine katkı sağlıyor.

İstanbul'un tarihi yarımadası, UNESCO Dünya Mirası listesinde yer alıyor. Ayasofya, Sultanahmet Camii ve Topkapı Sarayı gibi yapılar, şehrin zengin tarihini gözler önüne seriyor. Bu yapılar, Bizans ve Osmanlı dönemlerinin mirasını günümüze taşıyor.

Şehir aynı zamanda modern bir metropol. Yüksek binalar, alışveriş merkezleri ve teknoloji şirketleri, İstanbul'u bir iş merkezi haline getiriyor. Ancak bu modernleşme, şehrin geleneksel dokusunu bozmadan devam ediyor.

İstanbul'da yaşam hızlı akar. Sabah erkenden başlayan trafik, gece geç saatlere kadar devam eder. İnsanlar metro, metrobüs, vapur ve taksi gibi farklı ulaşım araçlarıyla şehir içinde hareket ediyor.

Türk mutfağı da İstanbul'un önemli bir parçası. Kebaplar, mezeler, balıklar ve tatlılar, şehrin gastronomi zenginliğini oluşturuyor. Balık ekmek ve simit gibi sokak lezzetleri, yerli ve yabancı turistlerin favorileri arasında.

Sonuç olarak İstanbul, tarihi ve moderni, doğuyu ve batıyı bir arada barındıran eşsiz bir şehir. Buraya gelen herkes, bu büyülü atmosferi hissediyor ve unutamıyorlar.
''';
