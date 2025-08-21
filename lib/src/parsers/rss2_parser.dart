import 'package:xml/xml.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/feed.dart';
import '../models/feed_item.dart';
import '../models/feed_format.dart';
import '../models/media_content.dart';

/// Exception thrown when RSS parsing fails
class RssParseException implements Exception {
  final String message;
  final String? source;

  RssParseException(this.message, {this.source});

  @override
  String toString() {
    final parts = ['RssParseException: $message'];
    if (source != null) {
      parts.add('Source: $source');
    }
    return parts.join(', ');
  }
}

/// Parser for RSS 2.0 feeds
class Rss2Parser {
  /// Parse RSS 2.0 XML string into Feed object
  Feed parse(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final rssElement = document.findElements('rss').firstOrNull;

      if (rssElement == null) {
        throw RssParseException('Invalid RSS: missing <rss> root element');
      }

      final channelElement = rssElement.findElements('channel').firstOrNull;
      if (channelElement == null) {
        throw RssParseException('Invalid RSS: missing <channel> element');
      }

      return _parseChannel(channelElement);
    } on XmlException catch (e) {
      throw RssParseException('XML parsing error: ${e.message}',
          source: xmlString);
    } catch (e) {
      throw RssParseException('Parsing error: $e', source: xmlString);
    }
  }

  Feed _parseChannel(XmlElement channelElement) {
    final title = _getElementText(channelElement, 'title');
    final description = _getElementText(channelElement, 'description');
    final link = _getElementText(channelElement, 'link');
    final language = _getElementText(channelElement, 'language');
    final copyright = _getElementText(channelElement, 'copyright');
    final author = _getElementText(channelElement, 'managingEditor');
    final imageUrl = _getElementText(
      channelElement.findElements('image').firstOrNull,
      'url',
    );

    final pubDate = _parseDate(_getElementText(channelElement, 'pubDate'));
    final lastBuildDate =
        _parseDate(_getElementText(channelElement, 'lastBuildDate'));

    final categories = channelElement
        .findElements('category')
        .map((e) => e.innerText.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final items = channelElement.findElements('item').map(_parseItem).toList();

    return Feed(
      title: title,
      description: description,
      link: link,
      language: language,
      copyright: copyright,
      author: author,
      imageUrl: imageUrl,
      pubDate: pubDate,
      lastBuildDate: lastBuildDate,
      categories: categories,
      items: items,
      format: FeedFormat.rss2,
    );
  }

  FeedItem _parseItem(XmlElement itemElement) {
    final title = _getElementText(itemElement, 'title');
    final description = _getElementText(itemElement, 'description');
    final link = _getElementText(itemElement, 'link');
    final guid = _getElementText(itemElement, 'guid');
    final author = _getElementText(itemElement, 'author');
    final pubDate = _parseDate(_getElementText(itemElement, 'pubDate'));

    final categories = itemElement
        .findElements('category')
        .map((e) => e.innerText.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final media =
        itemElement.findElements('enclosure').map(_parseEnclosure).toList();

    // Generate content hash for duplicate detection
    final contentHash = _generateContentHash(title, description, link);

    return FeedItem(
      title: title,
      description: description,
      link: link,
      guid: guid,
      author: author,
      pubDate: pubDate,
      categories: categories,
      media: media,
      contentHash: contentHash,
    );
  }

  MediaContent _parseEnclosure(XmlElement enclosureElement) {
    final url = enclosureElement.getAttribute('url') ?? '';
    final type = enclosureElement.getAttribute('type');
    final lengthStr = enclosureElement.getAttribute('length');
    final length = lengthStr != null ? int.tryParse(lengthStr) : null;

    return MediaContent(
      url: url,
      type: type,
      length: length,
    );
  }

  String? _getElementText(XmlElement? parent, String elementName) {
    if (parent == null) {
      return null;
    }

    final element = parent.findElements(elementName).firstOrNull;
    return element?.innerText.trim().isEmpty == false
        ? element!.innerText.trim()
        : null;
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      // RFC 822 date format: "Wed, 21 Aug 2025 12:00:00 GMT"
      return _parseRfc822Date(dateString);
    } catch (e) {
      try {
        // Try ISO 8601 format
        return DateTime.parse(dateString);
      } catch (e) {
        // If all parsing fails, return null
        return null;
      }
    }
  }

  DateTime _parseRfc822Date(String dateString) {
    // RFC 822 format: "Wed, 21 Aug 2025 12:00:00 GMT"
    final patterns = [
      RegExp(
          r'^\w+,\s+(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s+(.+)$'),
      RegExp(
          r'^(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s+(.+)$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(dateString);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        final second = int.parse(match.group(6)!);

        final month = _parseMonth(monthStr);
        if (month != null) {
          return DateTime.utc(year, month, day, hour, minute, second);
        }
      }
    }

    throw FormatException('Unable to parse RFC 822 date: $dateString');
  }

  int? _parseMonth(String monthStr) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[monthStr];
  }

  String _generateContentHash(
      String? title, String? description, String? link) {
    final content = [title, description, link]
        .where((s) => s != null && s.isNotEmpty)
        .join('|');

    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
