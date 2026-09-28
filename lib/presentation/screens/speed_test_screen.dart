/// Speed Test Screen
///
/// Reading speed test: the user reads a passage normally (timed), answers
/// comprehension questions and gets words per minute, comprehension and a
/// suggested RSVP speed.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/book.dart';
import '../../core/models/rsvp_settings.dart';
import '../../core/services/reading_stats.dart';
import '../theme/app_colors.dart';

/// One passage with its questions (assets/content/speed_tests.json)
class SpeedTest {
  final String id;
  final String title;
  final String text;
  final List<SpeedTestQuestion> questions;

  const SpeedTest({required this.id, required this.title, required this.text, required this.questions});

  int get wordCount => Book.countWords(text);

  factory SpeedTest.fromJson(Map<String, dynamic> json) => SpeedTest(
        id: json['id'] as String,
        title: json['title'] as String,
        text: json['text'] as String,
        questions: [
          for (final q in json['questions'] as List<dynamic>) SpeedTestQuestion.fromJson(q as Map<String, dynamic>),
        ],
      );

  static Future<List<SpeedTest>> loadAll() async {
    final data = jsonDecode(await rootBundle.loadString('assets/content/speed_tests.json')) as Map<String, dynamic>;
    return [for (final t in data['tests'] as List<dynamic>) SpeedTest.fromJson(t as Map<String, dynamic>)];
  }
}

class SpeedTestQuestion {
  final String question;
  final List<String> options;
  final int answer;

  const SpeedTestQuestion({required this.question, required this.options, required this.answer});

  factory SpeedTestQuestion.fromJson(Map<String, dynamic> json) => SpeedTestQuestion(
        question: json['q'] as String,
        options: [for (final o in json['options'] as List<dynamic>) o as String],
        answer: json['answer'] as int,
      );
}

/// Suggested RSVP starting speed: the normal reading speed, a bit lower if
/// comprehension was weak, rounded to the speed step
int suggestedWordsPerMinute(int readingWpm, int comprehension) {
  final factor = comprehension >= 75 ? 1.0 : (comprehension >= 50 ? 0.85 : 0.7);
  final step = RSVPSettings.wordsPerMinuteStep;
  final wpm = ((readingWpm * factor) / step).round() * step;
  return wpm.clamp(RSVPSettings.minWordsPerMinute, RSVPSettings.maxWordsPerMinute);
}

enum _Phase { intro, reading, questions, result }

class SpeedTestScreen extends StatefulWidget {
  /// Current settings (the suggested speed can be applied to them)
  final RSVPSettings settings;

  /// Called when the user applies the suggested speed
  final ValueChanged<RSVPSettings>? onSettingsChanged;

  /// Tests to use (tests pass them in; the app reads the bundled file)
  final List<SpeedTest>? tests;

  const SpeedTestScreen({super.key, required this.settings, this.onSettingsChanged, this.tests});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  SpeedTest? _test;
  _Phase _phase = _Phase.intro;
  final _stopwatch = Stopwatch();
  late List<int?> _answers;
  SpeedTestResult? _result;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    _pickTest();
  }

  /// The next test in order, after the ones taken before
  Future<void> _pickTest() async {
    final tests = widget.tests ?? await SpeedTest.loadAll();
    final taken = (await ReadingStats.load()).speedTests.length;
    if (!mounted || tests.isEmpty) return;
    setState(() {
      _test = tests[taken % tests.length];
      _answers = List.filled(_test!.questions.length, null);
    });
  }

  void _startReading() {
    setState(() => _phase = _Phase.reading);
    _stopwatch
      ..reset()
      ..start();
  }

  void _finishReading() {
    _stopwatch.stop();
    setState(() => _phase = _Phase.questions);
  }

  Future<void> _showResult() async {
    final test = _test!;
    final seconds = _stopwatch.elapsedMilliseconds / 1000;
    final wpm = seconds <= 0 ? 0 : (test.wordCount * 60 / seconds).round();
    var correct = 0;
    for (var i = 0; i < test.questions.length; i++) {
      if (_answers[i] == test.questions[i].answer) correct++;
    }
    final result = SpeedTestResult(
      date: DateTime.now(),
      testId: test.id,
      wordsPerMinute: wpm,
      comprehension: (correct * 100 / test.questions.length).round(),
    );
    await ReadingStats.addSpeedTest(result);
    if (!mounted) return;
    setState(() {
      _result = result;
      _phase = _Phase.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Okuma Hızı Testi',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w300, letterSpacing: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _test == null ? const Center(child: CircularProgressIndicator(color: Colors.black26)) : _buildPhase(),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.intro:
        return _buildIntro();
      case _Phase.reading:
        return _buildReading();
      case _Phase.questions:
        return _buildQuestions();
      case _Phase.result:
        return _buildResult();
    }
  }

  Widget _buildIntro() {
    final test = _test!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Kısa bir metni her zamanki gibi, anlayarak oku. Bitirince "Bitirdim"e dokun; '
          'ardından metinle ilgili ${test.questions.length} soru gelecek.',
          style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 16),
        Text(
          'Metin: ${test.title} · ${test.wordCount} kelime',
          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sonuçta dakikadaki kelime sayın, anlama oranın ve hızlı okuma için önerilen başlangıç hızı gösterilir.',
          style: TextStyle(fontSize: 13, color: AppColors.secondaryText, height: 1.4),
        ),
        const SizedBox(height: 32),
        _primaryButton('Başla', _startReading),
      ],
    );
  }

  Widget _buildReading() {
    final test = _test!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text(
                test.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              for (final paragraph in test.text.split('\n\n'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    paragraph,
                    style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _primaryButton('Bitirdim', _finishReading),
        ),
      ],
    );
  }

  Widget _buildQuestions() {
    final test = _test!;
    final allAnswered = !_answers.contains(null);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (var i = 0; i < test.questions.length; i++) ...[
          Text(
            '${i + 1}. ${test.questions[i].question}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: _answers[i],
            onChanged: (value) => setState(() => _answers[i] = value),
            child: Column(
              children: [
                for (var o = 0; o < test.questions[i].options.length; o++)
                  RadioListTile<int>(
                    value: o,
                    title: Text(test.questions[i].options[o], style: const TextStyle(fontSize: 15)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _primaryButton('Sonucu Gör', allAnswered ? _showResult : null),
      ],
    );
  }

  Widget _buildResult() {
    final result = _result!;
    final suggested = suggestedWordsPerMinute(result.wordsPerMinute, result.comprehension);
    final comprehensionNote = result.comprehension >= 75
        ? 'Metni iyi anladın.'
        : result.comprehension >= 50
            ? 'Anlama orta düzeyde; hızlı okurken biraz yavaş başlamak iyi olur.'
            : 'Anlama düşük; önce daha yavaş okuyup anlamaya odaklan.';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _resultTile('Okuma hızı', '${result.wordsPerMinute}', 'kelime/dk'),
        const SizedBox(height: 12),
        _resultTile('Anlama', '%${result.comprehension}', '${_correctCount()} / ${_test!.questions.length} doğru'),
        const SizedBox(height: 12),
        _resultTile('Etkili hız', '${result.effectiveWordsPerMinute}', 'anlaşılan kelime/dk'),
        const SizedBox(height: 20),
        Text(comprehensionNote, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4)),
        const SizedBox(height: 8),
        Text(
          'Hızlı okuma için önerilen başlangıç: $suggested kelime/dk',
          style: const TextStyle(fontSize: 15, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 24),
        _primaryButton(
          _applied ? 'Hız $suggested kelime/dk olarak ayarlandı' : 'Önerilen hızı kullan',
          _applied
              ? null
              : () {
                  widget.onSettingsChanged?.call(widget.settings.copyWith(wordsPerMinute: suggested));
                  setState(() => _applied = true);
                },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat', style: TextStyle(color: AppColors.secondaryText)),
        ),
      ],
    );
  }

  int _correctCount() {
    var correct = 0;
    for (var i = 0; i < _test!.questions.length; i++) {
      if (_answers[i] == _test!.questions[i].answer) correct++;
    }
    return correct;
  }

  Widget _resultTile(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.secondaryText))),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: Colors.black87)),
          const SizedBox(width: 6),
          Text(unit, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }
}
