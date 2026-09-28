import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/text_file_decoder.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

void main() {
  const turkish = 'Işık ğüşöç İĞÜŞÖÇ';

  test('decodes UTF-8 without BOM', () {
    expect(TextFileDecoder.decode(_bytes(utf8.encode(turkish))), turkish);
  });

  test('strips the UTF-8 BOM', () {
    final bytes = _bytes([0xEF, 0xBB, 0xBF, ...utf8.encode(turkish)]);
    expect(TextFileDecoder.decode(bytes), turkish);
  });

  test('decodes UTF-16 LE and BE with BOM', () {
    final le = <int>[0xFF, 0xFE];
    final be = <int>[0xFE, 0xFF];
    for (final unit in turkish.codeUnits) {
      le.addAll([unit & 0xFF, unit >> 8]);
      be.addAll([unit >> 8, unit & 0xFF]);
    }
    expect(TextFileDecoder.decode(_bytes(le)), turkish);
    expect(TextFileDecoder.decode(_bytes(be)), turkish);
  });

  test('falls back to Windows-1254 for Turkish ANSI files', () {
    // "Işık ğüşöç İĞÜŞÖÇ" encoded as Windows-1254
    final bytes = _bytes([
      0x49, 0xFE, 0xFD, 0x6B, 0x20, //
      0xF0, 0xFC, 0xFE, 0xF6, 0xE7, 0x20, //
      0xDD, 0xD0, 0xDC, 0xDE, 0xD6, 0xC7,
    ]);
    expect(TextFileDecoder.decode(bytes), turkish);
  });

  test('Windows-1254 typographic characters', () {
    expect(
      TextFileDecoder.decodeWindows1254(_bytes([0x93, 0x41, 0x94, 0x20, 0x96, 0x20, 0x80, 0x85])),
      '“A” – €…',
    );
  });
}
