/// Settings Screen
///
/// Configure RSVP reading preferences:
/// - Reading speed (WPM)
/// - Chunk size
/// - Font settings
/// - Theme/colors
/// - Micro-pause settings
library;

import 'package:flutter/material.dart';

import '../../core/models/rsvp_settings.dart';

/// Settings screen for RSVP configuration
class SettingsScreen extends StatefulWidget {
  /// Current settings
  final RSVPSettings settings;

  const SettingsScreen({
    super.key,
    required this.settings,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late RSVPSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSettings(RSVPSettings newSettings) {
    setState(() => _settings = newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _settings),
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Reading Speed Section
          _buildSectionHeader('Okuma Hizi'),
          _buildSliderTile(
            title: 'Kelime/Dakika (WPM)',
            value: _settings.wordsPerMinute.toDouble(),
            min: 100,
            max: 800,
            divisions: 14,
            label: '${_settings.wordsPerMinute} WPM',
            onChanged: (value) {
              _updateSettings(_settings.copyWith(wordsPerMinute: value.round()));
            },
          ),
          SwitchListTile(
            title: const Text('Adaptif Hiz'),
            subtitle: const Text('Kisa kelimeler hizli, uzun kelimeler yavas'),
            value: _settings.adaptiveSpeed,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(adaptiveSpeed: value));
            },
          ),

          const Divider(),

          // Chunk Settings
          _buildSectionHeader('Kelime Gruplama'),
          _buildSliderTile(
            title: 'Chunk Boyutu',
            value: _settings.chunkSize.toDouble(),
            min: 1,
            max: 3,
            divisions: 2,
            label: '${_settings.chunkSize} kelime',
            onChanged: (value) {
              _updateSettings(_settings.copyWith(chunkSize: value.round()));
            },
          ),

          const Divider(),

          // Display Settings
          _buildSectionHeader('Gorunum'),
          _buildSliderTile(
            title: 'Font Boyutu',
            value: _settings.fontSize,
            min: 20,
            max: 60,
            divisions: 8,
            label: '${_settings.fontSize.round()} pt',
            onChanged: (value) {
              _updateSettings(_settings.copyWith(fontSize: value));
            },
          ),
          SwitchListTile(
            title: const Text('ORP Vurgulama'),
            subtitle: const Text('Odak noktasini kirmizi ile vurgula'),
            value: _settings.showORPHighlight,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(showORPHighlight: value));
            },
          ),
          SwitchListTile(
            title: const Text('Odak Cizgileri'),
            subtitle: const Text('Dikey hizalama cizgilerini goster'),
            value: _settings.showFocusGuides,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(showFocusGuides: value));
            },
          ),

          const Divider(),

          // Theme Settings
          _buildSectionHeader('Tema'),
          _buildThemeOption('Karanlik', RSVPSettings.darkTheme),
          _buildThemeOption('Aydinlik', RSVPSettings.lightTheme),
          _buildThemeOption('Sepia', RSVPSettings.sepiaTheme),

          const Divider(),

          // Micro-pause Settings
          _buildSectionHeader('Bilisssel Duraklama'),
          SwitchListTile(
            title: const Text('Mikro-Duraklama'),
            subtitle: Text(
              _settings.microPauseInterval > 0
                  ? 'Her ${_settings.microPauseInterval} cumlede bir duraklama'
                  : 'Devre disi',
            ),
            value: _settings.microPauseInterval > 0,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(
                microPauseInterval: value ? 7 : 0,
              ));
            },
          ),
          if (_settings.microPauseInterval > 0)
            _buildSliderTile(
              title: 'Duraklama Araligi',
              value: _settings.microPauseInterval.toDouble(),
              min: 3,
              max: 15,
              divisions: 12,
              label: '${_settings.microPauseInterval} cumle',
              onChanged: (value) {
                _updateSettings(_settings.copyWith(microPauseInterval: value.round()));
              },
            ),

          const SizedBox(height: 32),

          // Reset button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () {
                _updateSettings(const RSVPSettings());
              },
              child: const Text('Varsayilanlara Sifirla'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
      trailing: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThemeOption(String title, RSVPSettings preset) {
    final isSelected = _settings.darkMode == preset.darkMode &&
        _settings.backgroundColor == preset.backgroundColor;

    return ListTile(
      title: Text(title),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(preset.backgroundColor),
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Aa',
            style: TextStyle(
              color: Color(preset.textColor),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        _updateSettings(_settings.copyWith(
          darkMode: preset.darkMode,
          textColor: preset.textColor,
          backgroundColor: preset.backgroundColor,
          orpHighlightColor: preset.orpHighlightColor,
        ));
      },
    );
  }
}
