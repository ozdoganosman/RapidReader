/// Settings Screen
///
/// Configure RSVP reading preferences:
/// - Reading speed (WPM)
/// - Chunk size
/// - Font settings
/// - Theme/colors
/// - Micro-pause settings
/// - The app's language
library;

import 'package:flutter/material.dart';

import '../../core/models/rsvp_settings.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/orp_text_widget.dart';

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

  /// Whether the ad consent can be changed here (where the law needs it)
  bool _adPrivacyOptions = false;

  @override
  void initState() {
    super.initState();
    _initialSettings = widget.settings;
    _currentSettings = widget.settings;
    AdService().privacyOptionsRequired().then((required) {
      if (required && mounted) setState(() => _adPrivacyOptions = true);
    });
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
          context.l10n.unsavedChanges,
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
        ),
        content: Text(
          context.l10n.unsavedChangesBody,
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text(context.l10n.cancel, style: TextStyle(color: AppColors.secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: Text(context.l10n.discardAndExit, style: TextStyle(color: Colors.red[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(context.l10n.saveAndExit),
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
            context.l10n.settings,
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
                  context.l10n.save,
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
              title: context.l10n.readingSpeed,
              children: [
                _buildSliderSetting(
                  label: context.l10n.wordsPerMinuteLabel,
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
                  title: context.l10n.adaptiveSpeed,
                  subtitle: context.l10n.adaptiveSpeedHint,
                  value: _currentSettings.adaptiveSpeed,
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(adaptiveSpeed: value));
                  },
                ),
                const SizedBox(height: 12),
                _buildSwitchSetting(
                  title: context.l10n.speedWarmUp,
                  subtitle: context.l10n.speedWarmUpHint,
                  value: _currentSettings.speedWarmUp,
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(speedWarmUp: value));
                  },
                ),
                const SizedBox(height: 12),
                _buildSwitchSetting(
                  title: context.l10n.speedRamp,
                  subtitle: context.l10n.speedRampHint(RSVPSettings.speedRampStep),
                  value: _currentSettings.speedRampTarget > 0,
                  onChanged: (value) {
                    final target = (_currentSettings.wordsPerMinute + 100).clamp(
                      RSVPSettings.minWordsPerMinute,
                      RSVPSettings.maxWordsPerMinute,
                    );
                    _updateSettings(_currentSettings.copyWith(speedRampTarget: value ? target : 0));
                  },
                ),
                if (_currentSettings.speedRampTarget > 0) ...[
                  const SizedBox(height: 12),
                  _buildSliderSetting(
                    label: context.l10n.targetSpeed,
                    value: _currentSettings.speedRampTarget.toDouble(),
                    min: RSVPSettings.minWordsPerMinute.toDouble(),
                    max: RSVPSettings.maxWordsPerMinute.toDouble(),
                    divisions: (RSVPSettings.maxWordsPerMinute - RSVPSettings.minWordsPerMinute) ~/
                        RSVPSettings.wordsPerMinuteStep,
                    displayValue: '${_currentSettings.speedRampTarget} WPM',
                    onChanged: (value) {
                      _updateSettings(_currentSettings.copyWith(speedRampTarget: value.round()));
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Chunk Settings
            _buildSettingCard(
              title: context.l10n.wordGrouping,
              children: [
                _buildSliderSetting(
                  label: context.l10n.chunkSize,
                  value: _currentSettings.chunkSize.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  displayValue: context.l10n.wordCount(_currentSettings.chunkSize),
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(chunkSize: value.round()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Display Settings
            _buildSettingCard(
              title: context.l10n.display,
              children: [
                _buildSliderSetting(
                  label: context.l10n.fontSize,
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
                  title: context.l10n.orpHighlight,
                  subtitle: context.l10n.orpHighlightHint,
                  value: _currentSettings.showORPHighlight,
                  onChanged: (value) {
                    _updateSettings(_currentSettings.copyWith(showORPHighlight: value));
                  },
                ),
                const SizedBox(height: 12),
                _buildSwitchSetting(
                  title: context.l10n.focusGuides,
                  subtitle: context.l10n.focusGuidesHint,
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
              title: context.l10n.fontFamily,
              children: [
                _buildFontOption('Roboto Mono', context.l10n.fontMonoHint),
                const SizedBox(height: 8),
                _buildFontOption('Roboto', context.l10n.fontRobotoHint),
                const SizedBox(height: 8),
                _buildFontOption('Open Sans', context.l10n.fontOpenSansHint),
                const SizedBox(height: 8),
                _buildFontOption('Noto Sans', context.l10n.fontNotoSansHint),
                const SizedBox(height: 8),
                _buildFontOption('Lato', context.l10n.fontLatoHint),
                const SizedBox(height: 8),
                _buildFontOption('Montserrat', context.l10n.fontMontserratHint),
                const SizedBox(height: 8),
                _buildFontOption('Merriweather', context.l10n.fontMerriweatherHint),
                const SizedBox(height: 8),
                _buildFontOption('Roboto Slab', context.l10n.fontRobotoSlabHint),
                const SizedBox(height: 8),
                _buildFontOption('OpenDyslexic', context.l10n.fontOpenDyslexicHint),
              ],
            ),

            const SizedBox(height: 16),

            // Theme Settings
            _buildSettingCard(
              title: context.l10n.theme,
              children: [
                _buildThemeOption(context.l10n.themeDark, RSVPSettings.darkTheme),
                const SizedBox(height: 8),
                _buildThemeOption(context.l10n.themeLight, RSVPSettings.lightTheme),
                const SizedBox(height: 8),
                _buildThemeOption(context.l10n.themeSepia, RSVPSettings.sepiaTheme),
                const SizedBox(height: 8),
                _buildThemeOption(context.l10n.themeHighContrast, RSVPSettings.highContrastTheme),
              ],
            ),

            const SizedBox(height: 16),

            // Micro-pause Settings
            _buildSettingCard(
              title: context.l10n.cognitivePause,
              children: [
                _buildSwitchSetting(
                  title: context.l10n.microPause,
                  subtitle: _currentSettings.microPauseInterval > 0
                      ? context.l10n.microPauseEvery(_currentSettings.microPauseInterval)
                      : context.l10n.off,
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
                    label: context.l10n.pauseInterval,
                    value: _currentSettings.microPauseInterval.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    displayValue: context.l10n.sentenceCount(_currentSettings.microPauseInterval),
                    onChanged: (value) {
                      _updateSettings(_currentSettings.copyWith(microPauseInterval: value.round()));
                    },
                  ),
                ],
              ],
            ),

            if (_adPrivacyOptions) ...[
              const SizedBox(height: 16),
              _buildSettingCard(
                title: context.l10n.privacy,
                children: [
                  InkWell(
                    onTap: AdService().showPrivacyOptions,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.adConsent, style: TextStyle(color: Colors.black87, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.adConsentHint,
                                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // The app's language (applied right away, not with the reading
            // settings)
            _buildSettingCard(
              title: context.l10n.language,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: AppLanguage.choice,
                  builder: (context, language, _) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (code, name) in [
                        (null, context.l10n.languageDevice),
                        ('tr', 'Türkçe'),
                        ('en', 'English'),
                      ])
                        ChoiceChip(
                          label: Text(name),
                          selected: language == code,
                          onSelected: (_) => AppLanguage.choose(code),
                        ),
                    ],
                  ),
                ),
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
                        context.l10n.resetDefaults,
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
                  // The reader's own font loading (Google Fonts register
                  // other family names than the plain one)
                  style: ORPTextWidget.readingFontStyle(
                    fontFamily,
                    color: Colors.black87,
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
