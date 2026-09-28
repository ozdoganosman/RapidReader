/// Document Importer
///
/// Reads a TXT, PDF or EPUB file into plain text for a custom book.
/// Works on web and mobile (the file is read as bytes).
library;

import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'epub_extractor.dart';
import 'pdf_extractor.dart';
import 'text_cleaner.dart';
import 'text_file_decoder.dart';

/// Text read from a document
class ImportedDocument {
  /// Suggested title (EPUB title, otherwise the file name)
  final String title;

  /// Author, when the file names one (EPUB)
  final String? author;

  /// Plain text content
  final String content;

  const ImportedDocument({required this.title, this.author, required this.content});
}

/// A file that could not be read; [message] is shown to the user
class DocumentImportException implements Exception {
  final String message;

  const DocumentImportException(this.message);

  @override
  String toString() => message;
}

/// Service for importing documents as custom books
class DocumentImporter {
  /// Supported file extensions
  static const extensions = ['txt', 'pdf', 'epub'];

  /// Let the user pick a file and read it; null when the picker is cancelled
  static Future<ImportedDocument?> pickAndRead() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true, // bytes on every platform (web has no file path)
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes ??
        (!kIsWeb && file.path != null ? await File(file.path!).readAsBytes() : null);
    if (bytes == null) {
      throw const DocumentImportException('Dosya okunamadı');
    }

    return read(file.name, bytes);
  }

  /// Convert a file's bytes to text, based on its extension
  ///
  /// PDF and EPUB are parsed in a background isolate.
  static Future<ImportedDocument> read(String fileName, Uint8List bytes) async {
    final dot = fileName.lastIndexOf('.');
    final extension = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : '';
    final baseName = dot > 0 ? fileName.substring(0, dot) : fileName;

    final ImportedDocument document;
    switch (extension) {
      case 'txt':
        document = ImportedDocument(
          title: baseName,
          content: TextCleaner.clean(TextFileDecoder.decode(bytes)),
        );
      case 'pdf':
        final text = await compute(PdfExtractor.extractText, bytes);
        document = ImportedDocument(title: baseName, content: TextCleaner.clean(text));
      case 'epub':
        final epub = await compute(EpubExtractor.extract, bytes);
        final title = epub.metadata.title;
        final author = epub.metadata.author;
        document = ImportedDocument(
          title: title.isNotEmpty && title != 'Bilinmeyen' ? title : baseName,
          author: author.isNotEmpty && author != 'Bilinmeyen Yazar' ? author : null,
          content: epub.text,
        );
      default:
        throw DocumentImportException('Desteklenmeyen dosya türü: .$extension');
    }

    if (document.content.trim().isEmpty) {
      // e.g. a scanned PDF that only contains images
      throw const DocumentImportException('Dosyada okunabilir metin bulunamadı');
    }
    return document;
  }
}
