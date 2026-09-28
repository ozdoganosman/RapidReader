import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/presentation/screens/exam_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<ExamQuestion> _bundled(String setId) {
  final data = jsonDecode(File('assets/content/exam_$setId.json').readAsStringSync()) as Map<String, dynamic>;
  return [for (final item in data['items'] as List<dynamic>) ExamQuestion.fromJson(item as Map<String, dynamic>)];
}

ExamQuestion _question(String id, int answer) => ExamQuestion(
      id: id,
      type: 'ana fikir',
      text: 'Paragraf $id',
      question: 'Soru $id?',
      options: const ['bir', 'iki', 'üç', 'dört'],
      answer: answer,
      explanation: 'Açıklama $id',
    );

void main() {
  test('bundled exam sets are well formed', () {
    for (final set in ExamSet.all) {
      final questions = _bundled(set.id);
      expect(questions, hasLength(40), reason: set.id);
      expect(questions.map((q) => q.id).toSet(), hasLength(40));
      final optionCount = set.id == 'lgs' ? 4 : 5;
      for (final q in questions) {
        expect(q.options, hasLength(optionCount), reason: q.id);
        expect(q.answer, inInclusiveRange(0, optionCount - 1), reason: q.id);
        expect(q.text, isNotEmpty);
        expect(q.explanation, isNotEmpty);
      }
    }
  });

  test('sessions show unseen questions first and then start a new round', () async {
    SharedPreferences.setMockInitialValues({});
    final all = [for (var i = 0; i < 25; i++) _question('q$i', 0)];

    final first = await ExamPicker.pick('lgs', all, 10, random: Random(1));
    final second = await ExamPicker.pick('lgs', all, 10, random: Random(2));
    expect(first.toSet().intersection(second.toSet()), isEmpty);

    // Only 5 unseen left: a new round starts from all questions
    final third = await ExamPicker.pick('lgs', all, 10, random: Random(3));
    expect(third, hasLength(10));
  });

  testWidgets('answering, time running out and the summary', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final questions = [_question('a', 1), _question('b', 2)];
    await tester.pumpWidget(MaterialApp(home: ExamScreen(loadQuestions: (_) async => questions)));

    await tester.tap(find.text('LGS'));
    await tester.pumpAndSettle();

    // First question (order is shuffled): answer it correctly
    final firstId = find.textContaining('Paragraf a').evaluate().isNotEmpty ? 'a' : 'b';
    final first = questions.firstWhere((q) => q.id == firstId);
    await tester.tap(find.text(first.options[first.answer]));
    await tester.pump();
    expect(find.text('Doğru!'), findsOneWidget);
    expect(find.text(first.explanation), findsOneWidget);

    await tester.tap(find.text('Sonraki Soru'));
    await tester.pump();

    // Second question: let the time run out
    await tester.pump(const Duration(seconds: 76));
    expect(find.textContaining('Süre doldu'), findsOneWidget);

    await tester.tap(find.text('Sonuçları Gör'));
    await tester.pump();
    expect(find.text('1 / 2 doğru'), findsOneWidget);
    expect(find.textContaining('ana fikir: 1'), findsOneWidget);
  });
}
