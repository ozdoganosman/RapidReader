/// Settings Screen
///
/// Configure RSVP reading preferences:
/// - Reading speed (WPM)
/// - Chunk size
/// - Font settings
/// - Theme/colors
/// - Micro-pause settings
/// - Read-aloud
library;

import 'package:flutter/material.dart';

import '../../core/models/rsvp_settings.dart';
import '../../core/services/narrator.dart';
import '../theme/app_colors.dart';

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
  late RSVPSettings _initialSettings;
  late RSVPSettings _currentSettings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initialSettings = widget.settings;
    _currentSettings = widget.settings;
  }

  void _updateSettings(RSVPSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
      _hasChanges = !_settingsEqual(_initialSettings, newSettings);
    });
  }

  bool _settingsEqual(RSVPSettings a, RSVPSettings b) => a == b;

  Future<void> _handleBackPress() async {
    if (!_hasChanges) {
      Navigator.of(context).pop(_currentSettings);
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Kaydedilmemiş Değişiklikler',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
        ),
        content: Text(
          'Ayarlarda yaptığınız değişiklikler kaydedilmedi. Ne yapmak istersiniz?',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text('İptal', style: TextStyle(color: AppColors.secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: Text('Çıkış (Kaydetme)', style: TextStyle(color: Colors.red[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Kaydet ve Çık'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      Navigator.of(context).pop(_currentSettings);
    } else if (result == 'discard') {
      Navigator.of(context).pop(_initialSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Ayarlar',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: _handleBackPress,
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: () => Navigator.pop(context, _currentSettings),
                child: Text(
                  'Kaydet',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 0.5, color: Colors.black12),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Reading Speed Section
            _buildSettingCard(
              title: 'Okuma Hızı',
              children: [
                _buildSliderSetting(
                  label: 'Kelime/Dakika (WPM)',
                  value: _currentSettings.wordsPerMinute.toDouble(),
                  min: RSVPSettings.minWordsPerMinute.toDouble(),
                  max: RSVPSettings.maxWordsPerMinute.toDouble(),
                  divisions: (RSVPSettings.maxWordsPerMinute - RSVPSettings.minWordsPerMinute) ~/
                      RSVPSettings.wordsPerMinuteStep,
                  displayValue: '${_currentSettings.wordsPerMinute} WPM',
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(wordsPerMinute: value.round()));
                  },
                ),
                const SizedBox(height: 20),
                _buildSwitchSetting(
                  title: 'Adaptif Hız',
                  subtitle: 'Kısa kelimeler hızlı, uzun kelimeler yavaş',
                  value: _currentSettings.adaptiveSpeed,
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(adaptiveSpeed: value));
                  },
                ),
                const SizedBox(height: 12),
                _buildSwitchSetting(
                  title: 'Hız Isınması',
                  subtitle: 'Yavaş başla, birkaç saniyede seçilen hıza çık',
                  value: _currentSettings.speedWarmUp,
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(speedWarmUp: value));
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Read-aloud
            _buildSettingCard(
              title: 'Sesli Okuma',
              children: [
                _buildSwitchSetting(
                  title: 'Sesli Oku',
                  subtitle: 'Metni cihazın Türkçe sesiyle okur; kelimeler sesle birlikte ilerler',
                  value: _currentSettings.readAloud,
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(readAloud: value));
                  },
                ),
                const SizedBox(height: 20),
                _buildSliderSetting(
                  label: 'Konuşma Hızı',
                  value: _currentSettings.speechRate,
                  min: RSVPSettings.minSpeechRate,
                  max: RSVPSettings.maxSpeechRate,
                  divisions: (RSVPSettings.maxSpeechRate - RSVPSettings.minSpeechRate) ~/ RSVPSettings.speechRateStep,
                  displayValue: speechRateLabel(_currentSettings.speechRate),
                  onChanged: (value) {
                    final rate = (value / RSVPSettings.speechRateStep).round() * RSVPSettings.speechRateStep;
                    _updateSettings(_currentSettings.copyWith(speechRate: rate));
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Chunk Settings
            _buildSettingCard(
              title: 'Kelime Gruplama',
              children: [
                _buildSliderSetting(
                  label: 'Chunk Boyutu',
                  value: _currentSettings.chunkSize.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  displayValue: '${_currentSettings.chunkSize} kelime',
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(chunkSize: value.round()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Display Settings
            _buildSettingCard(
              title: 'Görünüm',
              children: [
                _buildSliderSetting(
                  label: 'Font Boyutu',
                  value: _currentSettings.fontSize,
                  min: 20,
                  max: 60,
                  divisions: 8,
                  displayValue: '${_currentSettings.fontSize.round()} pt',
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(fontSize: value));
                  },
                ),
                const SizedBox(height: 20),
                _buildSwitchSetting(
                  title: 'ORP Vurgulama',
                  subtitle: 'Odak noktasını kırmızı ile vurgula',
                  value: _currentSettings.showORPHighlight,
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(showORPHighlight: value));
                  },
                ),
                const SizedBox(height: 12),
                _buildSwitchSetting(
                  title: 'Odak Çizgileri',
                  subtitle: 'Dikey hizalama çizgilerini göster',
                  value: _currentSettings.showFocusGuides,
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(showFocusGuides: value));
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Font Family Settings
            _buildSettingCard(
              title: 'Font Ailesi',
              children: [
                _buildFontOption('Roboto Mono', 'Monospace - Sabit genişlik'),
                const SizedBox(height: 8),
                _buildFontOption('Roboto', 'Sans-serif - Modern'),
                const SizedBox(height: 8),
                _buildFontOption('Open Sans', 'Sans-serif - Okunabilir'),
                const SizedBox(height: 8),
                _buildFontOption('Noto Sans', 'Sans-serif - Çok dilli'),
                const SizedBox(height: 8),
                _buildFontOption('Lato', 'Sans-serif - Zarif'),
                const SizedBox(height: 8),
                _buildFontOption('Montserrat', 'Sans-serif - Cesur'),
                const SizedBox(height: 8),
                _buildFontOption('Merriweather', 'Serif - Klasik'),
                const SizedBox(height: 8),
                _buildFontOption('Roboto Slab', 'Slab Serif - Güçlü'),
                const SizedBox(height: 8),
                _buildFontOption('OpenDyslexic', 'Disleksi dostu - Harfler karışmaz'),
              ],
            ),

            const SizedBox(height: 16),

            // Theme Settings
            _buildSettingCard(
              title: 'Tema',
              children: [
                _buildThemeOption('Karanlık', RSVPSettings.darkTheme),
                const SizedBox(height: 8),
                _buildThemeOption('Aydınlık', RSVPSettings.lightTheme),
                const SizedBox(height: 8),
                _buildThemeOption('Sepia', RSVPSettings.sepiaTheme),
                const SizedBox(height: 8),
                _buildThemeOption('Yüksek Kontrast', RSVPSettings.highContrastTheme),
              ],
            ),

            const SizedBox(height: 16),

            // Micro-pause Settings
            _buildSettingCard(
              title: 'Bilişsel Duraklama',
              children: [
                _buildSwitchSetting(
                  title: 'Mikro-Duraklama',
                  subtitle: _currentSettings.microPauseInterval > 0
                      ? 'Her ${_currentSettings.microPauseInterval} cümlede bir duraklama'
                      : 'Devre dışı',
                  value: _currentSettings.microPauseInterval > 0,
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(
                      microPauseInterval: value ? 7 : 0,
                    ));
                  },
                ),
                if (_currentSettings.microPauseInterval > 0) ...[
                  const SizedBox(height: 20),
                  _buildSliderSetting(
                    label: 'Duraklama Aralığı',
                    value: _currentSettings.microPauseInterval.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    displayValue: '${_currentSettings.microPauseInterval} cümle',
                    onChanged: (value) {
                      _updateSettings(_currentSettings.copyWith(microPauseInterval: value.round()));
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Reset button
            Center(
              child: GestureDetector(
                onTap: () {
                  _updateSettings(const RSVPSettings());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18, color: Colors.black45),
                      const SizedBox(width: 8),
                      Text(
                        'Varsayılanlara Sıfırla',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 0.5, width: 40, color: Colors.black12),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.black54,
            inactiveTrackColor: Colors.black12,
            thumbColor: Colors.black87,
            overlayColor: Colors.black.withValues(alpha: 0.1),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.black87,
          activeTrackColor: Colors.black54,
          inactiveThumbColor: Colors.black26,
          inactiveTrackColor: Colors.black12,
        ),
      ],
    );
  }

  Widget _buildThemeOption(String title, RSVPSettings preset) {
    final isSelected = _currentSettings.darkMode == preset.darkMode &&
        _currentSettings.backgroundColor == preset.backgroundColor &&
        _currentSettings.orpHighlightColor == preset.orpHighlightColor;

    return GestureDetector(
      onTap: () {
        _updateSettings(_currentSettings.copyWith(
          darkMode: preset.darkMode,
          textColor: preset.textColor,
          backgroundColor: preset.backgroundColor,
          orpHighlightColor: preset.orpHighlightColor,
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.black38 : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(preset.backgroundColor),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black12),
              ),
              child: Center(
                child: Text(
                  'Aa',
                  style: TextStyle(
                    color: Color(preset.textColor),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : AppColors.secondaryText,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFontOption(String fontFamily, String description) {
    final isSelected = _currentSettings.fontFamily == fontFamily;

    return GestureDetector(
      onTap: () {
        _updateSettings(_currentSettings.copyWith(fontFamily: fontFamily));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.black38 : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'Ag',
                  style: TextStyle(
                    color: Colors.black87,
                    fontFamily: fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fontFamily,
                    style: TextStyle(
                      color: isSelected ? Colors.black87 : AppColors.secondaryText,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }
}
