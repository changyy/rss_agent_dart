import 'package:xml/xml.dart';
import '../models/feed.dart';
import '../models/feed_item.dart';

/// RSS 2.0 XML generator
class Rss2Generator {
  /// Generate RSS 2.0 XML string from Feed object
  String generate(Feed feed) {
    final builder = XmlBuilder()
      ..declaration(encoding: 'UTF-8'); // XML declaration

    // RSS root element
    builder.element('rss', attributes: {
      'version': '2.0',
      'xmlns:atom': 'http://www.w3.org/2005/Atom',
    }, nest: () {
      // Channel element
      builder.element('channel', nest: () {
        // Required elements
        _addTextElement(builder, 'title', feed.title ?? 'Untitled Feed');
        _addTextElement(
            builder, 'description', feed.description ?? 'Generated RSS Feed');
        _addTextElement(builder, 'link', feed.link ?? 'https://example.com');

        // Optional channel elements
        if (feed.language != null) {
          _addTextElement(builder, 'language', feed.language!);
        }

        if (feed.copyright != null) {
          _addTextElement(builder, 'copyright', feed.copyright!);
        }

        if (feed.author != null) {
          _addTextElement(builder, 'managingEditor', feed.author!);
        }

        if (feed.pubDate != null) {
          _addTextElement(builder, 'pubDate', _formatRfc822Date(feed.pubDate!));
        }

        if (feed.lastBuildDate != null) {
          _addTextElement(
              builder, 'lastBuildDate', _formatRfc822Date(feed.lastBuildDate!));
        }

        // Categories
        for (final category in feed.categories) {
          _addTextElement(builder, 'category', category);
        }

        // Image
        if (feed.imageUrl != null) {
          builder.element('image', nest: () {
            _addTextElement(builder, 'url', feed.imageUrl!);
            _addTextElement(builder, 'title', feed.title ?? 'Feed Image');
            _addTextElement(
                builder, 'link', feed.link ?? 'https://example.com');
          });
        }

        // Generator
        _addTextElement(builder, 'generator', 'RSS Agent Generator');

        // Items
        for (final item in feed.items) {
          _generateItem(builder, item);
        }
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }

  void _generateItem(XmlBuilder builder, FeedItem item) {
    builder.element('item', nest: () {
      if (item.title != null) {
        _addTextElement(builder, 'title', item.title!);
      }

      if (item.description != null) {
        builder.element('description', nest: () {
          builder.cdata(item.description!);
        });
      }

      if (item.link != null) {
        _addTextElement(builder, 'link', item.link!);
      }

      if (item.guid != null) {
        _addTextElement(builder, 'guid', item.guid!);
      }

      if (item.author != null) {
        _addTextElement(builder, 'author', item.author!);
      }

      if (item.pubDate != null) {
        _addTextElement(builder, 'pubDate', _formatRfc822Date(item.pubDate!));
      }

      // Categories
      for (final category in item.categories) {
        _addTextElement(builder, 'category', category);
      }

      // Media/Enclosures
      for (final media in item.media) {
        builder.element('enclosure', attributes: {
          'url': media.url,
          if (media.type != null) 'type': media.type!,
          if (media.length != null) 'length': media.length.toString(),
        });
      }
    });
  }

  void _addTextElement(XmlBuilder builder, String name, String text) {
    builder.element(name, nest: () {
      builder.text(text);
    });
  }

  String _formatRfc822Date(DateTime dateTime) {
    // Convert to RFC 822 format: "Wed, 21 Aug 2025 12:00:00 GMT"
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final utc = dateTime.toUtc();
    final weekday = weekdays[utc.weekday - 1];
    final month = months[utc.month - 1];

    return '$weekday, ${utc.day.toString().padLeft(2, '0')} $month ${utc.year} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')} GMT';
  }
}
