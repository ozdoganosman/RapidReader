/// Article Extractor
///
/// Downloads a web page and keeps its readable text (title and paragraphs),
/// so an article can be read with RSVP.
library;

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'app_language.dart';
import 'text_cleaner.dart';
import 'text_file_decoder.dart';

/// Text of a web page
class Article {
  final String title;
  final String text;

  const Article({required this.title, required this.text});
}

/// A page that could not be read; [message] is shown to the user
class ArticleException implements Exception {
  final String message;

  const ArticleException(this.message);

  @override
  String toString() => message;
}

class ArticleExtractor {
  /// Page parts that are never article text
  static const _noise = 'script, style, noscript, template, nav, header, footer, aside, form, iframe, svg, '
      'button, figure, [role=navigation], [role=banner], [role=contentinfo], [aria-hidden=true]';

  /// Whether [text] is a single web address
  static bool isUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.contains(RegExp(r'\s'))) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  /// The link in a shared text that is mostly just a link, as apps share
  /// pages ("Title https://..."); null for a longer text
  static String? linkInSharedText(String text) {
    final match = RegExp(r'https?://\S+').firstMatch(text);
    if (match == null) return null;
    final rest = text.replaceRange(match.start, match.end, '').trim();
    return rest.length <= 200 ? match.group(0) : null;
  }

  /// Download [url] and extract its article
  static Future<Article> fetch(String url, {http.Client? client}) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !isUrl(url)) {
      throw ArticleException(AppLanguage.strings.enterValidUrl);
    }

    final http.Response response;
    final httpClient = client ?? http.Client();
    try {
      response = await httpClient.get(uri, headers: const {'Accept': 'text/html,application/xhtml+xml'});
    } catch (_) {
      throw ArticleException(
          kIsWeb ? AppLanguage.strings.siteBlockedInBrowser : AppLanguage.strings.pageDownloadFailed);
    } finally {
      if (client == null) httpClient.close();
    }
    if (response.statusCode != 200) {
      throw ArticleException(AppLanguage.strings.pageOpenFailed(response.statusCode));
    }

    final article = parse(TextFileDecoder.decode(response.bodyBytes));
    if (article.text.trim().isEmpty) {
      throw ArticleException(AppLanguage.strings.noTextOnPage);
    }
    return article;
  }

  /// Extract the title and paragraphs of an HTML page
  static Article parse(String html) {
    final document = html_parser.parse(html);

    final title = _meta(document, 'og:title') ??
        document.querySelector('title')?.text.trim() ??
        document.querySelector('h1')?.text.trim() ??
        '';

    for (final element in document.querySelectorAll(_noise)) {
      element.remove();
    }
    // A <br> separates words (and lines of a poem); .text would drop it and
    // glue them together
    for (final br in document.querySelectorAll('br')) {
      br.replaceWith(Text('\n'));
    }

    final container = _mainContainer(document);
    final paragraphs = <String>[];
    for (final element in container?.querySelectorAll('h1, h2, h3, p, blockquote, li') ?? <Element>[]) {
      // Skip list items that only wrap paragraphs (their text is taken from the <p>)
      if (element.localName == 'li' && element.querySelector('p') != null) continue;
      final text = element.text
          .split('\n')
          .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
          .where((line) => line.isNotEmpty)
          .join('\n');
      if (text.split(RegExp(r'\s')).length < 2 && element.localName != 'h1') continue;
      if (paragraphs.isNotEmpty && paragraphs.last == text) continue;
      paragraphs.add(text);
    }

    return Article(title: _clean(title), text: TextCleaner.clean(paragraphs.join('\n\n')));
  }

  static String? _meta(Document document, String property) {
    final content = document.querySelector('meta[property="$property"]')?.attributes['content']?.trim();
    return content == null || content.isEmpty ? null : content;
  }

  static String _clean(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// The element that holds the article: <article>, <main> or the block
  /// with the most paragraph text
  static Element? _mainContainer(Document document) {
    int paragraphLength(Element element) =>
        element.querySelectorAll('p').fold(0, (sum, p) => sum + p.text.trim().length);

    Element? best;
    var bestLength = 0;
    for (final candidate in [
      ...document.querySelectorAll('article'),
      ...document.querySelectorAll('main, [role=main]'),
    ]) {
      final length = paragraphLength(candidate);
      if (length > bestLength) {
        best = candidate;
        bestLength = length;
      }
    }
    if (best != null && bestLength > 200) return best;

    // No article element: the parent of the most paragraph text
    final scores = <Element, int>{};
    for (final p in document.querySelectorAll('p')) {
      final parent = p.parent;
      if (parent != null) scores[parent] = (scores[parent] ?? 0) + p.text.trim().length;
    }
    if (scores.isNotEmpty) {
      final top = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (top.value > 200) return top.key;
    }
    return document.body;
  }
}
