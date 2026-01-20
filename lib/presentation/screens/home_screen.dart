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

import '../../core/models/rsvp_settings.dart';
import '../../core/services/epub_extractor.dart';
import '../../core/services/pdf_extractor.dart';
import '../../core/services/text_cleaner.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

/// Home screen with library and import options
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  RSVPSettings _settings = const RSVPSettings();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _importFile() async {
    setState(() => _isLoading = true);

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

        switch (extension) {
          case 'txt':
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
        content = TextCleaner.clean(content);

        _startReading(content, title: title);
      }
    } catch (e) {
      _showError('Dosya okunurken hata oluştu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _startReading(String content, {String? title}) {
    if (content.trim().isEmpty) {
      _showError('Lütfen okumak için metin girin');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReaderScreen(
          content: content,
          title: title,
          settings: _settings,
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
      setState(() => _settings = newSettings);
    }
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
              _startReading(_textController.text, title: 'Manuel Metin');
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
                    onTap: () => _startReading(_sampleText, title: 'Örnek Metin'),
                  ),
                ],
              ),
            ),
    );
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
