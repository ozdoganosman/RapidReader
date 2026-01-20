/// Book model for storing imported books
library;

import 'package:equatable/equatable.dart';

/// Supported book formats
enum BookFormat {
  txt,
  pdf,
  epub,
  manual, // Manually entered text
}

/// Book entity for library management
class Book extends Equatable {
  /// Unique identifier
  final String id;

  /// Book title
  final String title;

  /// Author name (optional)
  final String? author;

  /// File path (null for manual text)
  final String? filePath;

  /// Book format
  final BookFormat format;

  /// When the book was imported
  final DateTime importedAt;

  /// Total word count
  final int totalWords;

  /// Current reading position (word index)
  final int currentWordIndex;

  /// Last read timestamp
  final DateTime? lastReadAt;

  /// Cover image path (optional)
  final String? coverImagePath;

  /// Raw text content (for manual entries or cached content)
  final String? textContent;

  const Book({
    required this.id,
    required this.title,
    this.author,
    this.filePath,
    required this.format,
    required this.importedAt,
    this.totalWords = 0,
    this.currentWordIndex = 0,
    this.lastReadAt,
    this.coverImagePath,
    this.textContent,
  });

  /// Reading progress as percentage (0.0 to 1.0)
  double get progress {
    if (totalWords == 0) return 0.0;
    return currentWordIndex / totalWords;
  }

  /// Whether reading has started
  bool get hasStarted => currentWordIndex > 0;

  /// Whether reading is complete
  bool get isComplete => totalWords > 0 && currentWordIndex >= totalWords;

  /// Create a copy with modified fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    BookFormat? format,
    DateTime? importedAt,
    int? totalWords,
    int? currentWordIndex,
    DateTime? lastReadAt,
    String? coverImagePath,
    String? textContent,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      importedAt: importedAt ?? this.importedAt,
      totalWords: totalWords ?? this.totalWords,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      textContent: textContent ?? this.textContent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        filePath,
        format,
        importedAt,
        totalWords,
        currentWordIndex,
        lastReadAt,
        coverImagePath,
        textContent,
      ];
}
