/// Exam Screen
///
/// Timed paragraph practice for LGS, TYT and KPSS (Türkçe paragraph
/// questions). The questions are original (assets/content/exam_*.json).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One exam's question set
class ExamSet {
  final String id;
  final String name;
  final String description;

  /// Time per question
  final int seconds;

  const ExamSet(this.id, this.name, this.description, this.seconds);

  static const all = [
    ExamSet('lgs', 'LGS', '8. sınıf Türkçe paragraf soruları', 75),
    ExamSet('tyt', 'TYT', 'Üniversite sınavı Türkçe paragraf soruları', 90),
    ExamSet('kpss', 'KPSS', 'Kamu personeli sınavı Türkçe paragraf soruları', 90),
  ];
}

class ExamQuestion {
  final String id;
  final String type;
  final String text;
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;

  const ExamQuestion({
    required this.id,
    required this.type,
    required this.text,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
        id: json['id'] as String,
        type: json['type'] as String,
        text: json['text'] as String,
        question: json['question'] as String,
        options: [for (final o in json['options'] as List<dynamic>) o as String],
        answer: json['answer'] as int,
        explanation: json['explanation'] as String,
      );

  static Future<List<ExamQuestion>> load(String setId) async {
    final data = jsonDecode(await rootBundle.loadString('assets/content/exam_$setId.json')) as Map<String, dynamic>;
    return [for (final item in data['items'] as List<dynamic>) ExamQuestion.fromJson(item as Map<String, dynamic>)];
  }
}

/// Picks the questions of a session, unseen ones first
class ExamPicker {
  static String _seenKey(String setId) => 'exam_seen_$setId';

  static Future<List<ExamQuestion>> pick(String setId, List<ExamQuestion> all, int count, {Random? random}) async {
    final prefs = await SharedPreferences.getInstance();
    var seen = (prefs.getStringList(_seenKey(setId)) ?? []).toSet();
    var unseen = all.where((q) => !seen.contains(q.id)).toList();
    if (unseen.length < count) {
      // Everything was shown: start a new round
      seen = {};
      unseen = List.of(all);
    }
    unseen.shuffle(random);
    final picked = unseen.take(count).toList();
    await prefs.setStringList(_seenKey(setId), [...seen, ...picked.map((q) => q.id)]);
    return picked;
  }
}

class ExamScreen extends StatefulWidget {
  /// Questions per session
  static const questionsPerSession = 10;

  /// Loads a set's questions; tests replace it
  final Future<List<ExamQuestion>> Function(String setId) loadQuestions;

  const ExamScreen({super.key, this.loadQuestions = ExamQuestion.load});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  ExamSet? _set;
  List<ExamQuestion> _questions = [];
  int _index = 0;
  int? _selected;
  bool _revealed = false;
  int _remaining = 0;
  Timer? _timer;
  final List<bool> _results = [];
  final List<int> _secondsUsed = [];

  static const _letters = ['A', 'B', 'C', 'D', 'E'];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start(ExamSet set) async {
    final all = await widget.loadQuestions(set.id);
    final questions = await ExamPicker.pick(set.id, all, min(ExamScreen.questionsPerSession, all.length));
    if (!mounted) return;
    setState(() {
      _set = set;
      _questions = questions;
      _index = 0;
      _results.clear();
      _secondsUsed.clear();
    });
    _startQuestion();
  }

  void _startQuestion() {
    _timer?.cancel();
    setState(() {
      _selected = null;
      _revealed = false;
      _remaining = _set!.seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _reveal(null); // time is up
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _reveal(int? answer) {
    if (_revealed) return;
    _timer?.cancel();
    setState(() {
      _selected = answer;
      _revealed = true;
      _results.add(answer == _questions[_index].answer);
      _secondsUsed.add(_set!.seconds - _remaining + (answer == null ? 1 : 0));
    });
  }

  void _next() {
    if (_index + 1 < _questions.length) {
      setState(() => _index++);
      _startQuestion();
    } else {
      setState(() => _index++); // past the last question: summary
    }
  }

  @override
  Widget build(BuildContext context) {
    final set = _set;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          set == null ? 'Sınav Modu' : '${set.name} Paragraf',
          style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w300, letterSpacing: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (set != null && _index < _questions.length)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  '${_index + 1}/${_questions.length}  ·  ${_remaining}s',
                  style: TextStyle(
                    fontSize: 14,
                    color: _remaining <= 10 && !_revealed ? Colors.red : Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: set == null
          ? _buildSetChoice()
          : _index < _questions.length
              ? _buildQuestion(_questions[_index])
              : _buildSummary(),
    );
  }

  Widget _buildSetChoice() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Her soru için süre sınırı var. Paragrafı oku, soruyu cevapla; cevaptan sonra doğru şık ve açıklaması gösterilir.',
          style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sorular bu uygulama için özgün olarak yazılmıştır; ÖSYM veya MEB sorusu değildir.',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 24),
        for (final set in ExamSet.all) ...[
          Material(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: () => _start(set),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(set.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
                          const SizedBox(height: 4),
                          Text(
                            '${set.description} · ${ExamScreen.questionsPerSession} soru, soru başına ${set.seconds} sn',
                            style: const TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black26),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildQuestion(ExamQuestion question) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        LinearProgressIndicator(
          value: _remaining / _set!.seconds,
          minHeight: 3,
          backgroundColor: Colors.black12,
          color: _remaining <= 10 ? Colors.red : Colors.black54,
        ),
        const SizedBox(height: 16),
        Text(question.text, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
        const SizedBox(height: 16),
        Text(question.question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
        const SizedBox(height: 12),
        for (var i = 0; i < question.options.length; i++) _buildOption(question, i),
        if (_revealed) ...[
          const SizedBox(height: 12),
          Text(
            _selected == null
                ? 'Süre doldu. Doğru cevap: ${_letters[question.answer]}'
                : _selected == question.answer
                    ? 'Doğru!'
                    : 'Yanlış. Doğru cevap: ${_letters[question.answer]}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _selected == question.answer ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(question.explanation, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              child: Text(_index + 1 < _questions.length ? 'Sonraki Soru' : 'Sonuçları Gör'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOption(ExamQuestion question, int i) {
    Color border = Colors.black12;
    Color? fill;
    if (_revealed && i == question.answer) {
      border = Colors.green;
      fill = Colors.green.withValues(alpha: 0.08);
    } else if (_revealed && i == _selected) {
      border = Colors.red;
      fill = Colors.red.withValues(alpha: 0.06);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: fill ?? Colors.white,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: _revealed ? null : () => _reveal(i),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_letters[i]})  ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Expanded(child: Text(question.options[i], style: const TextStyle(fontSize: 15, height: 1.4))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final correct = _results.where((r) => r).length;
    final averageSeconds = _secondsUsed.isEmpty ? 0 : _secondsUsed.reduce((a, b) => a + b) ~/ _secondsUsed.length;

    // Mistakes by question type
    final wrongTypes = <String, int>{};
    for (var i = 0; i < _results.length; i++) {
      if (!_results[i]) wrongTypes.update(_questions[i].type, (n) => n + 1, ifAbsent: () => 1);
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '$correct / ${_results.length} doğru',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w200),
        ),
        const SizedBox(height: 8),
        Text(
          'Soru başına ortalama $averageSeconds sn (süre: ${_set!.seconds} sn)',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        if (wrongTypes.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Yanlış yapılan soru türleri', style: TextStyle(fontSize: 13, color: Colors.black45)),
          const SizedBox(height: 6),
          for (final entry in wrongTypes.entries)
            Text('• ${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 14, height: 1.6)),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _start(_set!),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: const Text('Yeni 10 Soru'),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _set = null),
          child: const Text('Başka sınav seç', style: TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }
}
