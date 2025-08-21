import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:rss_agent/src/generators/rss2_generator.dart';
import 'package:rss_agent/src/models/feed.dart';
import 'package:rss_agent/src/models/feed_item.dart';
import 'package:rss_agent/src/models/feed_format.dart';
import 'package:rss_agent/src/models/media_content.dart';

void main() {
  group('Rss2Generator', () {
    late Rss2Generator generator;

    setUp(() {
      generator = Rss2Generator();
    });

    test('should generate basic RSS 2.0 XML', () {
      final feed = Feed(
        title: 'Test Feed',
        description: 'Test Description',
        link: 'https://example.com',
        language: 'en-us',
        copyright: null,
        author: null,
        imageUrl: null,
        pubDate: DateTime.parse('2025-01-01T12:00:00Z'),
        lastBuildDate: DateTime.parse('2025-01-01T12:00:00Z'),
        categories: [],
        items: [],
        format: FeedFormat.rss2,
      );

      final xmlString = generator.generate(feed);
      final document = XmlDocument.parse(xmlString);

      // Check XML structure
      final rssElement = document.findElements('rss').first;
      expect(rssElement.getAttribute('version'), equals('2.0'));
      expect(rssElement.getAttribute('xmlns:atom'),
          equals('http://www.w3.org/2005/Atom'));

      final channelElement = rssElement.findElements('channel').first;
      expect(channelElement.findElements('title').first.innerText,
          equals('Test Feed'));
      expect(channelElement.findElements('description').first.innerText,
          equals('Test Description'));
      expect(channelElement.findElements('link').first.innerText,
          equals('https://example.com'));
      expect(channelElement.findElements('language').first.innerText,
          equals('en-us'));
      expect(channelElement.findElements('generator').first.innerText,
          equals('RSS Agent Generator'));
    });

    test('should generate RSS with feed items', () {
      final items = [
        FeedItem(
          title: 'Item 1',
          description: 'Description 1',
          link: 'https://example.com/item1',
          guid: 'guid1',
          author: 'author@example.com',
          pubDate: DateTime.parse('2025-01-01T10:00:00Z'),
          categories: ['category1', 'category2'],
          media: [],
          contentHash: 'hash1',
        ),
        FeedItem(
          title: 'Item 2',
          description: 'Description 2',
          link: 'https://example.com/item2',
          guid: null,
          author: null,
          pubDate: null,
          categories: [],
          media: [],
          contentHash: 'hash2',
        ),
      ];

      final feed = Feed(
        title: 'Test Feed',
        description: 'Test Description',
        link: 'https://example.com',
        language: null,
        copyright: null,
        author: null,
        imageUrl: null,
        pubDate: null,
        lastBuildDate: null,
        categories: [],
        items: items,
        format: FeedFormat.rss2,
      );

      final xmlString = generator.generate(feed);
      final document = XmlDocument.parse(xmlString);

      final channelElement =
          document.findElements('rss').first.findElements('channel').first;
      final itemElements = channelElement.findElements('item').toList();

      expect(itemElements, hasLength(2));

      // Check first item
      final item1 = itemElements[0];
      expect(item1.findElements('title').first.innerText, equals('Item 1'));
      expect(item1.findElements('description').first.innerText.trim(),
          equals('Description 1'));
      expect(item1.findElements('link').first.innerText,
          equals('https://example.com/item1'));
      expect(item1.findElements('guid').first.innerText, equals('guid1'));
      expect(item1.findElements('author').first.innerText,
          equals('author@example.com'));
      expect(item1.findElements('pubDate').first.innerText,
          equals('Wed, 01 Jan 2025 10:00:00 GMT'));
      expect(item1.findElements('category'), hasLength(2));

      // Check second item (minimal data)
      final item2 = itemElements[1];
      expect(item2.findElements('title').first.innerText, equals('Item 2'));
      expect(item2.findElements('description').first.innerText.trim(),
          equals('Description 2'));
      expect(item2.findElements('link').first.innerText,
          equals('https://example.com/item2'));
      expect(item2.findElements('guid'), isEmpty);
      expect(item2.findElements('author'), isEmpty);
      expect(item2.findElements('pubDate'), isEmpty);
      expect(item2.findElements('category'), isEmpty);
    });

    test('should generate RSS with media enclosures', () {
      final media = [
        MediaContent(
          url: 'https://example.com/audio.mp3',
          type: 'audio/mpeg',
          length: 12345,
        ),
        MediaContent(
          url: 'https://example.com/image.jpg',
          type: 'image/jpeg',
          length: null,
        ),
      ];

      final item = FeedItem(
        title: 'Item with Media',
        description: 'Item Description',
        link: 'https://example.com/item',
        guid: null,
        author: null,
        pubDate: null,
        categories: [],
        media: media,
        contentHash: 'hash',
      );

      final feed = Feed(
        title: 'Test Feed',
        description: 'Test Description',
        link: 'https://example.com',
        language: null,
        copyright: null,
        author: null,
        imageUrl: null,
        pubDate: null,
        lastBuildDate: null,
        categories: [],
        items: [item],
        format: FeedFormat.rss2,
      );

      final xmlString = generator.generate(feed);
      final document = XmlDocument.parse(xmlString);

      final itemElement = document
          .findElements('rss')
          .first
          .findElements('channel')
          .first
          .findElements('item')
          .first;

      final enclosureElements = itemElement.findElements('enclosure').toList();
      expect(enclosureElements, hasLength(2));

      // Check first enclosure
      final enclosure1 = enclosureElements[0];
      expect(enclosure1.getAttribute('url'),
          equals('https://example.com/audio.mp3'));
      expect(enclosure1.getAttribute('type'), equals('audio/mpeg'));
      expect(enclosure1.getAttribute('length'), equals('12345'));

      // Check second enclosure (no length)
      final enclosure2 = enclosureElements[1];
      expect(enclosure2.getAttribute('url'),
          equals('https://example.com/image.jpg'));
      expect(enclosure2.getAttribute('type'), equals('image/jpeg'));
      expect(enclosure2.getAttribute('length'), isNull);
    });

    test('should generate RSS with image and categories', () {
      final feed = Feed(
        title: 'Test Feed',
        description: 'Test Description',
        link: 'https://example.com',
        language: 'en-us',
        copyright: 'Copyright 2025',
        author: 'editor@example.com',
        imageUrl: 'https://example.com/logo.png',
        pubDate: DateTime.parse('2025-01-01T12:00:00Z'),
        lastBuildDate: DateTime.parse('2025-01-01T13:00:00Z'),
        categories: ['news', 'technology'],
        items: [],
        format: FeedFormat.rss2,
      );

      final xmlString = generator.generate(feed);
      final document = XmlDocument.parse(xmlString);

      final channelElement =
          document.findElements('rss').first.findElements('channel').first;

      // Check image
      final imageElement = channelElement.findElements('image').first;
      expect(imageElement.findElements('url').first.innerText,
          equals('https://example.com/logo.png'));
      expect(imageElement.findElements('title').first.innerText,
          equals('Test Feed'));
      expect(imageElement.findElements('link').first.innerText,
          equals('https://example.com'));

      // Check categories
      final categoryElements = channelElement.findElements('category').toList();
      expect(categoryElements, hasLength(2));
      expect(categoryElements[0].innerText, equals('news'));
      expect(categoryElements[1].innerText, equals('technology'));

      // Check other fields
      expect(channelElement.findElements('copyright').first.innerText,
          equals('Copyright 2025'));
      expect(channelElement.findElements('managingEditor').first.innerText,
          equals('editor@example.com'));
    });

    test('should handle minimal feed data', () {
      final feed = Feed(
        title: null,
        description: null,
        link: null,
        language: null,
        copyright: null,
        author: null,
        imageUrl: null,
        pubDate: null,
        lastBuildDate: null,
        categories: [],
        items: [],
        format: FeedFormat.rss2,
      );

      final xmlString = generator.generate(feed);
      final document = XmlDocument.parse(xmlString);

      final channelElement =
          document.findElements('rss').first.findElements('channel').first;

      // Check defaults
      expect(channelElement.findElements('title').first.innerText,
          equals('Untitled Feed'));
      expect(channelElement.findElements('description').first.innerText,
          equals('Generated RSS Feed'));
      expect(channelElement.findElements('link').first.innerText,
          equals('https://example.com'));

      // Check optional fields are not present
      expect(channelElement.findElements('language'), isEmpty);
      expect(channelElement.findElements('copyright'), isEmpty);
      expect(channelElement.findElements('managingEditor'), isEmpty);
      expect(channelElement.findElements('pubDate'), isEmpty);
      expect(channelElement.findElements('lastBuildDate'), isEmpty);
      expect(channelElement.findElements('image'), isEmpty);
      expect(channelElement.findElements('category'), isEmpty);
    });

    test('should format RFC 822 dates correctly', () {
      final testDate = DateTime.utc(2025, 8, 21, 14, 30, 45);

      final feed = Feed(
        title: 'Test Feed',
        description: 'Test Description',
        link: 'https://example.com',
        language: null,
        copyright: null,
        author: null,
        imageUrl: null,
        pubDate: testDate,
        lastBuildDate: testDate,
        categories: [],
        items: [],
        format: FeedFormat.rss2,
      );

      final xmlString = generator.generate(feed);
      final document = XmlDocument.parse(xmlString);

      final channelElement =
          document.findElements('rss').first.findElements('channel').first;

      expect(channelElement.findElements('pubDate').first.innerText,
          equals('Thu, 21 Aug 2025 14:30:45 GMT'));
      expect(channelElement.findElements('lastBuildDate').first.innerText,
          equals('Thu, 21 Aug 2025 14:30:45 GMT'));
    });

    test('should use CDATA for item descriptions', () {
      final item = FeedItem(
        title: 'Test Item',
        description: 'Description with <b>HTML</b> & special chars',
        link: 'https://example.com/item',
        guid: null,
        author: null,
        pubDate: null,
        categories: [],
        media: [],
        contentHash: 'hash',
      );

      final feed = Feed(
        title: 'Test Feed',
        description: 'Test Description',
        link: 'https://example.com',
        language: null,
        copyright: null,
        author: null,
        imageUrl: null,
        pubDate: null,
        lastBuildDate: null,
        categories: [],
        items: [item],
        format: FeedFormat.rss2,
      );

      final xmlString = generator.generate(feed);

      // Check that CDATA is used in description
      expect(xmlString,
          contains('<![CDATA[Description with <b>HTML</b> & special chars]]>'));
    });
  });
}
