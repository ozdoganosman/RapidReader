/// Home Screen - Library and text input
///
/// Main entry point for the app with:
/// - Manual text input
/// - File import options
/// - Reading history
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/models/rsvp_settings.dart';
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
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase();

        String content;
        String title = result.files.single.name;

        switch (extension) {
          case 'txt':
            content = await file.readAsString();
            break;
          case 'pdf':
            // TODO: Implement PDF parsing
            _showError('PDF destegi yakinda eklenecek');
            return;
          case 'epub':
            // TODO: Implement EPUB parsing
            _showError('EPUB destegi yakinda eklenecek');
            return;
          default:
            _showError('Desteklenmeyen dosya formati');
            return;
        }

        if (content.trim().isEmpty) {
          _showError('Dosya bos veya okunamiyor');
          return;
        }

        _startReading(content, title: title);
      }
    } catch (e) {
      _showError('Dosya okunurken hata olustu: $e');
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
      _showError('Lutfen okumak icin metin girin');
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
            hintText: 'Okumak istediginiz metni buraya yapistin...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startReading(_textController.text, title: 'Manuel Metin');
            },
            child: const Text('Okumaya Basla'),
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
                            'RSVP Hizli Okuma',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kelime kelime odaklanarak daha hizli okuyun',
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
                      title: const Text('Okuma Hizi'),
                      subtitle: Text('${_settings.wordsPerMinute} kelime/dakika'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openSettings,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Import options
                  const Text(
                    'Okumaya Basla',
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
                    subtitle: 'Metni manuel olarak yapistin',
                    onTap: _showTextInputDialog,
                  ),

                  // Import file
                  _buildOptionCard(
                    icon: Icons.file_open,
                    title: 'Dosya Yukle',
                    subtitle: 'TXT, PDF veya EPUB dosyasi sec',
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
                    title: 'Ornek Metni Oku',
                    subtitle: 'RSVP\'yi denemek icin ornek metin',
                    onTap: () => _startReading(_sampleText, title: 'Ornek Metin'),
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
Turkiye'nin en guzel sehirlerinden biri olan Istanbul, iki kitanin bulusma noktasinda yer aliyor. Bogazici, sehrin tam ortasindan gecen ve Avrupa ile Asya'yi ayiran dogal bir su yolu. Her gun binlerce gemi bu bogazdan gecerek dunya ticaretine katki sagliyor.

Istanbul'un tarihi yarimadasi, UNESCO Dunya Mirasi listesinde yer aliyor. Ayasofya, Sultanahmet Camii ve Topkapi Sarayi gibi yapilar, sehrin zengin tarihini gozler onune seriyor. Bu yapilar, Bizans ve Osmanli donemlerinin mirasini gunumuze tasiyor.

Sehir ayni zamanda modern bir metropol. Yuksek binalar, alisveris merkezleri ve teknoloji sirketleri, Istanbul'u bir is merkezi haline getiriyor. Ancak bu modernlesme, sehrin geleneksel dokusunu bozmadan devam ediyor.

Istanbul'da yasam hizli akar. Sabah erkenden baslayan trafik, gece geç saatlere kadar devam eder. Insanlar metro, metrobus, vapur ve taksi gibi farkli ulasim araclariyla sehir icinde hareket ediyor.

Turk mutfagi da Istanbul'un onemli bir parcasi. Kebaplar, mezeler, baliklar ve tatlilar, sehrin gastronomi zenginligini olusturuyor. Balik ekmek ve simit gibi sokak lezzetleri, yerli ve yabanci turistlerin favorileri arasinda.

Sonuc olarak Istanbul, tarihi ve moderni, doguyu ve batiyi bir arada barindiran essiz bir sehir. Buraya gelen herkes, bu buyulu atmosferi hissediyor ve unutamiyorlar.
''';
