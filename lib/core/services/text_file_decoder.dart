/// Text File Decoder
///
/// Decodes plain-text files that are not necessarily UTF-8. Turkish .txt
/// files saved by Windows editors are often Windows-1254 ("ANSI") or
/// UTF-16, and UTF-8 files may start with a byte order mark.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Decoder for imported .txt files
class TextFileDecoder {
  /// Decode [bytes] detecting the encoding:
  /// - UTF-8 / UTF-16 LE / UTF-16 BE with a byte order mark (BOM removed)
  /// - UTF-8 without BOM when the bytes are valid UTF-8
  /// - Windows-1254 (Turkish) otherwise
  static String decode(Uint8List bytes) {
    if (_startsWith(bytes, const [0xEF, 0xBB, 0xBF])) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }
    if (_startsWith(bytes, const [0xFF, 0xFE])) {
      return _decodeUtf16(bytes, Endian.little);
    }
    if (_startsWith(bytes, const [0xFE, 0xFF])) {
      return _decodeUtf16(bytes, Endian.big);
    }

    try {
      return utf8.decode(bytes);
    } on FormatException {
      return decodeWindows1254(bytes);
    }
  }

  /// Decode Windows-1254 (a superset of ISO-8859-9 / Latin-5)
  static String decodeWindows1254(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte < 0x80) {
        buffer.writeCharCode(byte);
      } else if (byte < 0xA0) {
        buffer.writeCharCode(_cp1254High[byte - 0x80]);
      } else {
        buffer.writeCharCode(_latin5[byte] ?? byte);
      }
    }
    return buffer.toString();
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }

  /// Decode UTF-16 after a 2-byte BOM (a trailing odd byte is ignored)
  static String _decodeUtf16(Uint8List bytes, Endian endian) {
    final data = ByteData.sublistView(bytes);
    final codeUnits = <int>[
      for (var i = 2; i + 1 < bytes.length; i += 2) data.getUint16(i, endian),
    ];
    return String.fromCharCodes(codeUnits);
  }

  /// Windows-1254 bytes 0x80-0x9F (U+FFFD for unassigned bytes)
  static const _cp1254High = [
    0x20AC, 0xFFFD, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, // 80-87
    0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0xFFFD, 0xFFFD, 0xFFFD, // 88-8F
    0xFFFD, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, // 90-97
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0xFFFD, 0xFFFD, 0x0178, // 98-9F
  ];

  /// Bytes 0xA0-0xFF that differ from Latin-1 (the Turkish letters)
  static const _latin5 = {
    0xD0: 0x011E, // Ğ
    0xDD: 0x0130, // İ
    0xDE: 0x015E, // Ş
    0xF0: 0x011F, // ğ
    0xFD: 0x0131, // ı
    0xFE: 0x015F, // ş
  };
}
