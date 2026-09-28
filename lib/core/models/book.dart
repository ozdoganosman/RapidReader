/// Book Model
///
/// Represents a book in the pre-loaded library.
library;

/// A book with its content and metadata
class Book {
  /// Unique identifier
  final String id;

  /// Book title
  final String title;

  /// Author name
  final String author;

  /// Category (e.g., "Hikaye", "Bilim")
  final String category;

  /// Cover color as hex string (e.g., "#FF5722")
  final String coverColor;

  /// Full text content (empty for bundled texts until they are loaded,
  /// see [contentAsset] and BookService.loadContent)
  final String content;

  /// Asset path of the text for bundled books, loaded when the book is opened
  final String? contentAsset;

  /// Word count known without the text (bundled books, from the index)
  final int? knownWordCount;

  /// Optional cover image as base64 string (for custom books)
  final String? imageBase64;

  /// Cover image asset path (for bundled books)
  final String? coverAsset;

  /// Series name (e.g., "Dönüşüm" for "Dönüşüm 1", "Dönüşüm 2", etc.)
  final String? seriesName;

  /// Chapter number (e.g., 1, 2, 3)
  final int? chapterNumber;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.coverColor,
    this.content = '',
    this.contentAsset,
    this.knownWordCount,
    this.imageBase64,
    this.coverAsset,
    this.seriesName,
    this.chapterNumber,
  });

  /// Create a Book from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      category: json['category'] as String,
      coverColor: json['coverColor'] as String,
      content: json['content'] as String,
      imageBase64: json['imageBase64'] as String?,
      seriesName: json['seriesName'] as String?,
      chapterNumber: json['chapterNumber'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'coverColor': coverColor,
      'content': content,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (seriesName != null) 'seriesName': seriesName,
      if (chapterNumber != null) 'chapterNumber': chapterNumber,
    };
  }

  /// Check if this is a custom book (has custom_ prefix)
  bool get isCustomBook => id.startsWith('custom_');

  /// Check if this book is part of a series
  bool get isSeries => seriesName != null && chapterNumber != null;

  /// Word counts are computed once per book (the screens ask for them on
  /// every build, and splitting the whole text each time is expensive)
  static final _wordCounts = Expando<int>();

  /// Get word count
  int get wordCount => knownWordCount ?? (_wordCounts[this] ??= countWords(content));

  /// Words in [text], separated by whitespace
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Get estimated reading time in minutes (based on 200 WPM)
  int get estimatedMinutes {
    return (wordCount / 200).ceil();
  }

  /// Parse cover color to int for Color constructor
  int get coverColorValue {
    final hex = coverColor.replaceAll('#', '');
    return int.parse('FF$hex', radix: 16);
  }
}
