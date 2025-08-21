import 'package:test/test.dart';
import 'package:rss_agent/src/models/feed.dart';
import 'package:rss_agent/src/models/feed_item.dart';
import 'package:rss_agent/src/models/feed_format.dart';

void main() {
  group('Feed', () {
    test('should create a feed with required fields', () {
      final items = <FeedItem>[];
      final feed = Feed(
        items: items,
        format: FeedFormat.rss2,
      );

      expect(feed.items, equals(items));
      expect(feed.format, equals(FeedFormat.rss2));
      expect(feed.title, isNull);
      expect(feed.description, isNull);
    });

    test('should create a feed with all fields', () {
      final pubDate = DateTime(2025, 8, 21);
      final lastBuildDate = DateTime(2025, 8, 21, 12);
      final items = <FeedItem>[];
      final categories = ['tech', 'news'];
      final metadata = {'custom': 'value'};

      final feed = Feed(
        title: 'Test Feed',
        description: 'A test RSS feed',
        link: 'https://example.com',
        language: 'en-US',
        copyright: 'Copyright 2025',
        pubDate: pubDate,
        lastBuildDate: lastBuildDate,
        items: items,
        format: FeedFormat.atom,
        imageUrl: 'https://example.com/image.jpg',
        author: 'Test Author',
        categories: categories,
        metadata: metadata,
      );

      expect(feed.title, equals('Test Feed'));
      expect(feed.description, equals('A test RSS feed'));
      expect(feed.link, equals('https://example.com'));
      expect(feed.language, equals('en-US'));
      expect(feed.copyright, equals('Copyright 2025'));
      expect(feed.pubDate, equals(pubDate));
      expect(feed.lastBuildDate, equals(lastBuildDate));
      expect(feed.items, equals(items));
      expect(feed.format, equals(FeedFormat.atom));
      expect(feed.imageUrl, equals('https://example.com/image.jpg'));
      expect(feed.author, equals('Test Author'));
      expect(feed.categories, equals(categories));
      expect(feed.metadata, equals(metadata));
    });

    test('should create a copy with updated fields', () {
      final originalFeed = Feed(
        title: 'Original Title',
        items: [],
        format: FeedFormat.rss2,
      );

      final copiedFeed = originalFeed.copyWith(
        title: 'Updated Title',
        format: FeedFormat.atom,
      );

      expect(copiedFeed.title, equals('Updated Title'));
      expect(copiedFeed.format, equals(FeedFormat.atom));
      expect(originalFeed.title, equals('Original Title'));
      expect(originalFeed.format, equals(FeedFormat.rss2));
    });

    test('should have meaningful toString', () {
      final feed = Feed(
        title: 'Test Feed',
        items: [FeedItem(), FeedItem()],
        format: FeedFormat.jsonFeed,
      );

      final result = feed.toString();

      expect(result, contains('Test Feed'));
      expect(result, contains('2'));
      expect(result, contains('JSON Feed'));
    });
  });
}
