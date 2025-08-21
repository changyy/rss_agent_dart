import 'package:test/test.dart';
import 'package:rss_agent/src/parsers/rss2_parser.dart';
import 'package:rss_agent/src/models/feed_format.dart';

void main() {
  group('Rss2Parser', () {
    late Rss2Parser parser;

    setUp(() {
      parser = Rss2Parser();
    });

    test('should parse basic RSS 2.0 feed', () {
      const rssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>A test RSS feed</description>
    <language>en-us</language>
    <pubDate>Wed, 21 Aug 2025 12:00:00 GMT</pubDate>
    <lastBuildDate>Wed, 21 Aug 2025 13:00:00 GMT</lastBuildDate>
    <item>
      <title>Test Article 1</title>
      <link>https://example.com/article1</link>
      <description>First test article</description>
      <pubDate>Wed, 21 Aug 2025 10:00:00 GMT</pubDate>
      <guid>https://example.com/article1</guid>
    </item>
    <item>
      <title>Test Article 2</title>
      <link>https://example.com/article2</link>
      <description>Second test article</description>
      <pubDate>Wed, 21 Aug 2025 11:00:00 GMT</pubDate>
      <guid>https://example.com/article2</guid>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);

      expect(feed.format, equals(FeedFormat.rss2));
      expect(feed.title, equals('Test Feed'));
      expect(feed.link, equals('https://example.com'));
      expect(feed.description, equals('A test RSS feed'));
      expect(feed.language, equals('en-us'));
      expect(feed.pubDate, isNotNull);
      expect(feed.lastBuildDate, isNotNull);
      expect(feed.items, hasLength(2));

      // Test first item
      final item1 = feed.items[0];
      expect(item1.title, equals('Test Article 1'));
      expect(item1.link, equals('https://example.com/article1'));
      expect(item1.description, equals('First test article'));
      expect(item1.guid, equals('https://example.com/article1'));
      expect(item1.pubDate, isNotNull);

      // Test second item
      final item2 = feed.items[1];
      expect(item2.title, equals('Test Article 2'));
      expect(item2.link, equals('https://example.com/article2'));
      expect(item2.description, equals('Second test article'));
      expect(item2.guid, equals('https://example.com/article2'));
      expect(item2.pubDate, isNotNull);
    });

    test('should parse minimal RSS 2.0 feed', () {
      const rssXml = '''<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <title>Minimal Feed</title>
    <link>https://minimal.com</link>
    <description>Minimal description</description>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);

      expect(feed.format, equals(FeedFormat.rss2));
      expect(feed.title, equals('Minimal Feed'));
      expect(feed.link, equals('https://minimal.com'));
      expect(feed.description, equals('Minimal description'));
      expect(feed.items, isEmpty);
      expect(feed.pubDate, isNull);
      expect(feed.lastBuildDate, isNull);
    });

    test('should handle RSS with enclosures', () {
      const rssXml = '''<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <title>Media Feed</title>
    <link>https://media.com</link>
    <description>A feed with media</description>
    <item>
      <title>Article with Media</title>
      <link>https://media.com/article</link>
      <description>Article description</description>
      <enclosure url="https://media.com/audio.mp3" length="1024" type="audio/mpeg"/>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);
      final item = feed.items.first;

      expect(item.media, hasLength(1));
      expect(item.media.first.url, equals('https://media.com/audio.mp3'));
      expect(item.media.first.type, equals('audio/mpeg'));
      expect(item.media.first.length, equals(1024));
    });

    test('should handle RSS with categories', () {
      const rssXml = '''<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <title>Categorized Feed</title>
    <link>https://cat.com</link>
    <description>Feed with categories</description>
    <category>Technology</category>
    <category>Science</category>
    <item>
      <title>Categorized Article</title>
      <link>https://cat.com/article</link>
      <description>Article with categories</description>
      <category>Tech</category>
      <category>News</category>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);

      expect(feed.categories, containsAll(['Technology', 'Science']));
      expect(feed.items.first.categories, containsAll(['Tech', 'News']));
    });

    test('should throw exception for invalid XML', () {
      const invalidXml = 'This is not XML';

      expect(
        () => parser.parse(invalidXml),
        throwsA(isA<RssParseException>()),
      );
    });

    test('should throw exception for non-RSS XML', () {
      const nonRssXml = '''<?xml version="1.0"?>
<html>
  <head><title>Not RSS</title></head>
</html>''';

      expect(
        () => parser.parse(nonRssXml),
        throwsA(isA<RssParseException>()),
      );
    });

    test('should handle RSS with author information', () {
      const rssXml = '''<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <title>Author Feed</title>
    <link>https://author.com</link>
    <description>Feed with author info</description>
    <managingEditor>editor@author.com (Editor Name)</managingEditor>
    <item>
      <title>Authored Article</title>
      <link>https://author.com/article</link>
      <description>Article description</description>
      <author>writer@author.com (Writer Name)</author>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);

      expect(feed.author, contains('editor@author.com'));
      expect(feed.items.first.author, contains('writer@author.com'));
    });

    test('should handle malformed dates gracefully', () {
      const rssXml = '''<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <title>Bad Date Feed</title>
    <link>https://bad.com</link>
    <description>Feed with bad dates</description>
    <pubDate>invalid date</pubDate>
    <item>
      <title>Bad Date Article</title>
      <link>https://bad.com/article</link>
      <description>Article with bad date</description>
      <pubDate>also invalid</pubDate>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);

      // Should not throw, but dates should be null
      expect(feed.pubDate, isNull);
      expect(feed.items.first.pubDate, isNull);
    });
  });
}
