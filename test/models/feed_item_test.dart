import 'package:test/test.dart';
import 'package:rss_agent/src/models/feed_item.dart';
import 'package:rss_agent/src/models/media_content.dart';

void main() {
  group('FeedItem', () {
    test('should create a feed item with minimal data', () {
      final item = FeedItem();

      expect(item.title, isNull);
      expect(item.description, isNull);
      expect(item.link, isNull);
      expect(item.categories, isEmpty);
      expect(item.media, isEmpty);
      expect(item.metadata, isEmpty);
    });

    test('should create a feed item with all fields', () {
      final pubDate = DateTime(2025, 8, 21, 12, 30);
      final categories = ['tech', 'news'];
      final media = [MediaContent(url: 'https://example.com/image.jpg')];
      final metadata = {'custom': 'value'};

      final item = FeedItem(
        title: 'Test Article',
        description: 'A test article',
        link: 'https://example.com/article',
        guid: 'test-guid-123',
        pubDate: pubDate,
        author: 'Test Author',
        categories: categories,
        media: media,
        sourceFeed: 'Test Feed',
        contentHash: 'hash123',
        metadata: metadata,
      );

      expect(item.title, equals('Test Article'));
      expect(item.description, equals('A test article'));
      expect(item.link, equals('https://example.com/article'));
      expect(item.guid, equals('test-guid-123'));
      expect(item.pubDate, equals(pubDate));
      expect(item.author, equals('Test Author'));
      expect(item.categories, equals(categories));
      expect(item.media, equals(media));
      expect(item.sourceFeed, equals('Test Feed'));
      expect(item.contentHash, equals('hash123'));
      expect(item.metadata, equals(metadata));
    });

    group('isSameAs', () {
      test('should match by GUID when both have it', () {
        final item1 = FeedItem(
          guid: 'same-guid',
          title: 'Different Title',
          link: 'https://different.com',
        );

        final item2 = FeedItem(
          guid: 'same-guid',
          title: 'Another Title',
          link: 'https://another.com',
        );

        expect(item1.isSameAs(item2), isTrue);
      });

      test('should match by content hash when GUIDs differ', () {
        final item1 = FeedItem(
          guid: 'guid1',
          contentHash: 'same-hash',
          link: 'https://different.com',
        );

        final item2 = FeedItem(
          guid: 'guid2',
          contentHash: 'same-hash',
          link: 'https://another.com',
        );

        expect(item1.isSameAs(item2), isTrue);
      });

      test('should match by link when hashes differ', () {
        final item1 = FeedItem(
          contentHash: 'hash1',
          link: 'https://same.com/article',
        );

        final item2 = FeedItem(
          contentHash: 'hash2',
          link: 'https://same.com/article',
        );

        expect(item1.isSameAs(item2), isTrue);
      });

      test('should match by title and date as fallback', () {
        final pubDate = DateTime(2025, 8, 21);
        final item1 = FeedItem(
          title: 'Same Title',
          pubDate: pubDate,
        );

        final item2 = FeedItem(
          title: 'Same Title',
          pubDate: pubDate,
        );

        expect(item1.isSameAs(item2), isTrue);
      });

      test('should not match different items', () {
        final item1 = FeedItem(
          title: 'Title 1',
          link: 'https://example1.com',
        );

        final item2 = FeedItem(
          title: 'Title 2',
          link: 'https://example2.com',
        );

        expect(item1.isSameAs(item2), isFalse);
      });
    });

    test('should create a copy with updated fields', () {
      final originalItem = FeedItem(
        title: 'Original Title',
        link: 'https://original.com',
      );

      final copiedItem = originalItem.copyWith(
        title: 'Updated Title',
        description: 'New description',
      );

      expect(copiedItem.title, equals('Updated Title'));
      expect(copiedItem.description, equals('New description'));
      expect(copiedItem.link, equals('https://original.com'));

      expect(originalItem.title, equals('Original Title'));
      expect(originalItem.description, isNull);
    });

    test('should have meaningful toString', () {
      final pubDate = DateTime(2025, 8, 21);
      final item = FeedItem(
        title: 'Test Article',
        link: 'https://example.com',
        pubDate: pubDate,
      );

      final result = item.toString();

      expect(result, contains('Test Article'));
      expect(result, contains('https://example.com'));
      expect(result, contains(pubDate.toString()));
    });
  });
}
