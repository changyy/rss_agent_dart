import 'dart:convert';
import 'package:test/test.dart';
import 'package:rss_agent/src/cli/base_cli_tool.dart';
import 'package:rss_agent/src/models/feed.dart';
import 'package:rss_agent/src/models/feed_item.dart';
import 'package:rss_agent/src/models/feed_format.dart';

void main() {
  group('BaseCLITool', () {
    test('should build base arg parser with common options', () {
      final parser = BaseCLITool.buildBaseArgParser();

      expect(parser.options.containsKey('help'), isTrue);
      expect(parser.options.containsKey('version'), isTrue);
      expect(parser.options.containsKey('format'), isTrue);
      expect(parser.options.containsKey('cache'), isTrue);
      expect(parser.options.containsKey('cache-expired-time'), isTrue);
      expect(parser.options.containsKey('no-cache'), isTrue);
      expect(parser.options.containsKey('verbose'), isTrue);

      // Check default values
      expect(parser.options['format']!.defaultsTo, equals('json'));
      expect(parser.options['cache-expired-time']!.defaultsTo, equals('180'));
    });

    test('should parse cache config from arguments - default', () {
      final parser = BaseCLITool.buildBaseArgParser();
      final results = parser.parse([]);

      final config = BaseCLITool.parseCacheConfig(results);

      expect(config, isNotNull);
      expect(config!.enabled, isTrue);
      expect(config.cacheDir, isNull); // Should use system default
      expect(config.expirationSeconds, equals(180));
    });

    test('should parse cache config from arguments - disabled', () {
      final parser = BaseCLITool.buildBaseArgParser();
      final results = parser.parse(['--no-cache']);

      final config = BaseCLITool.parseCacheConfig(results);

      expect(config, isNull); // Should return null for disabled cache
    });

    test('should parse cache config from arguments - custom', () {
      final parser = BaseCLITool.buildBaseArgParser();
      final results = parser.parse([
        '--cache',
        './custom-cache',
        '--cache-expired-time',
        '600',
      ]);

      final config = BaseCLITool.parseCacheConfig(results);

      expect(config, isNotNull);
      expect(config!.enabled, isTrue);
      expect(config.cacheDir, equals('./custom-cache'));
      expect(config.expirationSeconds, equals(600));
    });

    test('should parse cache config from arguments - only cache dir', () {
      final parser = BaseCLITool.buildBaseArgParser();
      final results = parser.parse(['--cache', './my-cache']);

      final config = BaseCLITool.parseCacheConfig(results);

      expect(config, isNotNull);
      expect(config!.enabled, isTrue);
      expect(config.cacheDir, equals('./my-cache'));
      expect(config.expirationSeconds, equals(180)); // Default
    });

    test('should parse cache config from arguments - only expiration time', () {
      final parser = BaseCLITool.buildBaseArgParser();
      final results = parser.parse(['--cache-expired-time', '300']);

      final config = BaseCLITool.parseCacheConfig(results);

      expect(config, isNotNull);
      expect(config!.enabled, isTrue);
      expect(config.cacheDir, isNull); // Default
      expect(config.expirationSeconds, equals(300));
    });

    test('should handle invalid cache expiration time', () {
      final parser = BaseCLITool.buildBaseArgParser();
      final results = parser.parse(['--cache-expired-time', 'invalid']);

      expect(
        () => BaseCLITool.parseCacheConfig(results),
        throwsA(isA<FormatException>()),
      );
    });

    test('should format feed as JSON', () {
      final feed = Feed(
        title: 'Test Feed',
        description: 'A test feed',
        link: 'https://example.com',
        items: [
          FeedItem(
            title: 'Item 1',
            link: 'https://example.com/1',
            description: 'First item',
            pubDate: DateTime.parse('2025-08-28T10:00:00Z'),
          ),
          FeedItem(
            title: 'Item 2',
            link: 'https://example.com/2',
            description: 'Second item',
            pubDate: DateTime.parse('2025-08-28T11:00:00Z'),
          ),
        ],
        format: FeedFormat.rss2,
      );

      final jsonString = BaseCLITool.formatFeedAsJson(feed);
      final jsonData = json.decode(jsonString);

      expect(jsonData['title'], equals('Test Feed'));
      expect(jsonData['description'], equals('A test feed'));
      expect(jsonData['link'], equals('https://example.com'));
      expect(jsonData['format'], equals('RSS 2.0'));
      expect(jsonData['items_count'], equals(2));
      expect(jsonData['items'], hasLength(2));

      final firstItem = jsonData['items'][0];
      expect(firstItem['title'], equals('Item 1'));
      expect(firstItem['link'], equals('https://example.com/1'));
      expect(firstItem['description'], equals('First item'));
      expect(firstItem['pub_date'], equals('2025-08-28T10:00:00.000Z'));
    });

    test('should format feed as JSON with null values', () {
      final feed = Feed(
        items: [],
        format: FeedFormat.atom,
      );

      final jsonString = BaseCLITool.formatFeedAsJson(feed);
      final jsonData = json.decode(jsonString);

      expect(jsonData['title'], isNull);
      expect(jsonData['description'], isNull);
      expect(jsonData['link'], isNull);
      expect(jsonData['format'], equals('Atom 1.0'));
      expect(jsonData['items_count'], equals(0));
      expect(jsonData['items'], isEmpty);
    });

    test('should format feed items with all properties', () {
      final feed = Feed(
        items: [
          FeedItem(
            title: 'Full Item',
            link: 'https://example.com/full',
            description: 'Full description',
            pubDate: DateTime.parse('2025-08-28T12:00:00Z'),
            guid: 'unique-id-123',
            author: 'John Doe',
            categories: ['tech', 'news'],
          ),
        ],
        format: FeedFormat.jsonFeed,
      );

      final jsonString = BaseCLITool.formatFeedAsJson(feed);
      final jsonData = json.decode(jsonString);

      final item = jsonData['items'][0];
      expect(item['title'], equals('Full Item'));
      expect(item['link'], equals('https://example.com/full'));
      expect(item['description'], equals('Full description'));
      expect(item['pub_date'], equals('2025-08-28T12:00:00.000Z'));
      expect(item['guid'], equals('unique-id-123'));
      expect(item['author'], equals('John Doe'));
      expect(item['categories'], equals(['tech', 'news']));
    });

    test('should format feed with metadata', () {
      final pubDate = DateTime.parse('2025-08-28T08:00:00Z');
      final lastBuildDate = DateTime.parse('2025-08-28T09:00:00Z');

      final feed = Feed(
        title: 'Metadata Feed',
        description: 'Feed with metadata',
        link: 'https://example.com/meta',
        language: 'en-US',
        copyright: 'Copyright 2025',
        author: 'Feed Author',
        imageUrl: 'https://example.com/image.jpg',
        pubDate: pubDate,
        lastBuildDate: lastBuildDate,
        categories: ['category1', 'category2'],
        items: [],
        format: FeedFormat.rss2,
      );

      final jsonString = BaseCLITool.formatFeedAsJson(feed);
      final jsonData = json.decode(jsonString);

      expect(jsonData['title'], equals('Metadata Feed'));
      expect(jsonData['description'], equals('Feed with metadata'));
      expect(jsonData['link'], equals('https://example.com/meta'));
      expect(jsonData['language'], equals('en-US'));
      expect(jsonData['copyright'], equals('Copyright 2025'));
      expect(jsonData['author'], equals('Feed Author'));
      expect(jsonData['image_url'], equals('https://example.com/image.jpg'));
      expect(jsonData['pub_date'], equals('2025-08-28T08:00:00.000Z'));
      expect(jsonData['last_build_date'], equals('2025-08-28T09:00:00.000Z'));
      expect(jsonData['categories'], equals(['category1', 'category2']));
    });

    test('should create result object with version info', () {
      final feed = Feed(
        title: 'Version Test',
        items: [],
        format: FeedFormat.rss2,
      );

      final result = BaseCLITool.createResult(
        feed: feed,
        useCache: true,
        additionalMeta: {'custom': 'value'},
      );

      expect(result['status'], isTrue);
      expect(result['data'], isNotNull);
      expect(result['meta'], isNotNull);
      expect(result['meta']['rss_agent'], isNotNull);
      expect(result['meta']['custom'], equals('value'));
      expect(result['use_cache'], isTrue);
      expect(result['timestamp'], isNotNull);

      final data = result['data'];
      expect(data['title'], equals('Version Test'));
    });

    test('should create error result', () {
      const errorMessage = 'Test error message';

      final result = BaseCLITool.createErrorResult(
        errorMessage,
        additionalMeta: {'error_code': 'TEST_ERROR'},
      );

      expect(result['status'], isFalse);
      expect(result['error'], equals(errorMessage));
      expect(result['meta'], isNotNull);
      expect(result['meta']['rss_agent'], isNotNull);
      expect(result['meta']['error_code'], equals('TEST_ERROR'));
      expect(result['use_cache'], isFalse);
      expect(result['timestamp'], isNotNull);
      expect(result.containsKey('data'), isFalse);
    });
  });
}
