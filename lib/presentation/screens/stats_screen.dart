/// Stats Screen
///
/// Today's reading against the daily goal, the streak, the last 7 days,
/// totals and the speed test results.
library;

import 'package:flutter/material.dart';

import '../../core/models/rsvp_settings.dart';
import '../../core/services/reading_stats.dart';
import 'speed_test_screen.dart';

class StatsScreen extends StatefulWidget {
  final RSVPSettings settings;
  final ValueChanged<RSVPSettings>? onSettingsChanged;

  const StatsScreen({super.key, required this.settings, this.onSettingsChanged});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsSummary? _stats;
  late RSVPSettings _settings = widget.settings;

  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await ReadingStats.load();
    if (mounted) setState(() => _stats = stats);
  }

  Future<void> _setGoal(int minutes) async {
    await ReadingStats.setGoalMinutes(minutes);
    await _load();
  }

  Future<void> _openSpeedTest() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => SpeedTestScreen(
        settings: _settings,
        onSettingsChanged: (settings) {
          _settings = settings;
          widget.onSettingsChanged?.call(settings);
        },
      ),
    ));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'İstatistikler',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w300, letterSpacing: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: stats == null
          ? const Center(child: CircularProgressIndicator(color: Colors.black26))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildToday(stats),
                const SizedBox(height: 16),
                _buildWeek(stats),
                const SizedBox(height: 16),
                _buildTotals(stats),
                const SizedBox(height: 16),
                _buildSpeedTests(stats),
                const SizedBox(height: 16),
                _buildGoal(stats),
              ],
            ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black45, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToday(StatsSummary stats) {
    final minutes = stats.today.minutes;
    final progress = (stats.today.seconds / (stats.goalMinutes * 60)).clamp(0.0, 1.0);
    return _card(
      title: 'BUGÜN',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$minutes', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w200)),
            Text(' / ${stats.goalMinutes} dk', style: const TextStyle(fontSize: 14, color: Colors.black45)),
            const Spacer(),
            const Icon(Icons.local_fire_department_outlined, size: 20, color: Colors.deepOrange),
            const SizedBox(width: 4),
            Text('${stats.streak} gün seri', style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.black12,
            color: stats.goalMetToday ? Colors.green : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stats.goalMetToday
              ? 'Günlük hedefe ulaştın.'
              : 'Hedefe ${stats.goalMinutes - minutes} dk kaldı · bugün ${stats.today.words} kelime',
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildWeek(StatsSummary stats) {
    final maxSeconds = stats.lastWeek.fold<int>(stats.goalMinutes * 60, (m, d) => d.seconds > m ? d.seconds : m);
    return _card(
      title: 'SON 7 GÜN',
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in stats.lastWeek)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${day.minutes}', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                      const SizedBox(height: 4),
                      Container(
                        height: 80 * day.seconds / maxSeconds,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: day.seconds >= stats.goalMinutes * 60 ? Colors.green : Colors.black54,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_weekdays[day.day.weekday - 1], style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotals(StatsSummary stats) {
    final hours = stats.totalSeconds ~/ 3600;
    final minutes = (stats.totalSeconds % 3600) ~/ 60;
    return _card(
      title: 'TOPLAM',
      children: [
        _row('Okunan kelime', '${stats.totalWords}'),
        _row('Okuma süresi', hours > 0 ? '$hours sa $minutes dk' : '$minutes dk'),
        _row('Ortalama hız', stats.averageWordsPerMinute > 0 ? '${stats.averageWordsPerMinute} kelime/dk' : '-'),
      ],
    );
  }

  Widget _buildSpeedTests(StatsSummary stats) {
    return _card(
      title: 'OKUMA HIZI TESTİ',
      children: [
        if (stats.speedTests.isEmpty)
          const Text(
            'Henüz test yapmadın. Normal okuma hızını ve anlamanı ölç, sana uygun hızı öğren.',
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          )
        else
          for (final result in stats.speedTests.take(5))
            _row(
              '${result.date.day}.${result.date.month}.${result.date.year}',
              '${result.wordsPerMinute} kelime/dk · %${result.comprehension} anlama',
            ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _openSpeedTest,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Colors.black26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Testi Başlat'),
          ),
        ),
      ],
    );
  }

  Widget _buildGoal(StatsSummary stats) {
    return _card(
      title: 'GÜNLÜK HEDEF',
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final minutes in ReadingStats.goalChoices)
              ChoiceChip(
                label: Text('$minutes dk'),
                selected: stats.goalMinutes == minutes,
                onSelected: (_) => _setGoal(minutes),
              ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54))),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}
