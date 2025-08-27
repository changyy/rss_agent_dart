import 'package:test/test.dart';
import 'package:rss_agent/src/parsers/rss2_parser.dart';

void main() {
  group('RFC 2822 日期時區解析測試', () {
    late Rss2Parser parser;

    setUp(() {
      parser = Rss2Parser();
    });

    test('應該正確解析 +0800 時區 (台北時間)', () {
      const rssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>Testing +0800 timezone</description>
    <item>
      <title>Test Article</title>
      <link>https://example.com/article</link>
      <description>Test article</description>
      <pubDate>Thu, 28 Aug 2025 00:46:04 +0800</pubDate>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);
      final item = feed.items.first;

      // +0800 意味著比 UTC 快 8 小時
      // 所以 00:46:04 +0800 應該等於 16:46:04 UTC (前一天)
      final expectedUtc = DateTime.utc(2025, 8, 27, 16, 46, 4);

      expect(item.pubDate, isNotNull);
      expect(item.pubDate!.isUtc, isTrue);
      expect(item.pubDate, equals(expectedUtc),
          reason: '解析結果: ${item.pubDate}, 預期: $expectedUtc');
    });

    test('應該正確解析 -0500 時區 (美東時間)', () {
      const rssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>Testing -0500 timezone</description>
    <item>
      <title>Test Article</title>
      <link>https://example.com/article</link>
      <description>Test article</description>
      <pubDate>Wed, 27 Aug 2025 12:00:00 -0500</pubDate>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);
      final item = feed.items.first;

      // -0500 意味著比 UTC 慢 5 小時
      // 所以 12:00:00 -0500 應該等於 17:00:00 UTC
      final expectedUtc = DateTime.utc(2025, 8, 27, 17, 0, 0);

      expect(item.pubDate, isNotNull);
      expect(item.pubDate!.isUtc, isTrue);
      expect(item.pubDate, equals(expectedUtc),
          reason: '解析結果: ${item.pubDate}, 預期: $expectedUtc');
    });

    test('應該正確解析 +0930 時區 (澳洲阿德雷德時間)', () {
      const rssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>Testing +0930 timezone</description>
    <item>
      <title>Test Article</title>
      <link>https://example.com/article</link>
      <description>Test article</description>
      <pubDate>Thu, 28 Aug 2025 10:30:00 +0930</pubDate>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);
      final item = feed.items.first;

      // +0930 意味著比 UTC 快 9.5 小時
      // 所以 10:30:00 +0930 應該等於 01:00:00 UTC
      final expectedUtc = DateTime.utc(2025, 8, 28, 1, 0, 0);

      expect(item.pubDate, isNotNull);
      expect(item.pubDate!.isUtc, isTrue);
      expect(item.pubDate, equals(expectedUtc),
          reason: '解析結果: ${item.pubDate}, 預期: $expectedUtc');
    });

    test('應該正確解析 GMT 時區', () {
      const rssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>Testing GMT timezone</description>
    <item>
      <title>Test Article</title>
      <link>https://example.com/article</link>
      <description>Test article</description>
      <pubDate>Wed, 27 Aug 2025 15:30:00 GMT</pubDate>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);
      final item = feed.items.first;

      // GMT = UTC，所以時間應該一樣
      final expectedUtc = DateTime.utc(2025, 8, 27, 15, 30, 0);

      expect(item.pubDate, isNotNull);
      expect(item.pubDate!.isUtc, isTrue);
      expect(item.pubDate, equals(expectedUtc),
          reason: '解析結果: ${item.pubDate}, 預期: $expectedUtc');
    });

    test('應該正確解析 UTC 時區', () {
      const rssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>Testing UTC timezone</description>
    <item>
      <title>Test Article</title>
      <link>https://example.com/article</link>
      <description>Test article</description>
      <pubDate>Wed, 27 Aug 2025 20:15:00 UTC</pubDate>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);
      final item = feed.items.first;

      // UTC = UTC，所以時間應該一樣
      final expectedUtc = DateTime.utc(2025, 8, 27, 20, 15, 0);

      expect(item.pubDate, isNotNull);
      expect(item.pubDate!.isUtc, isTrue);
      expect(item.pubDate, equals(expectedUtc),
          reason: '解析結果: ${item.pubDate}, 預期: $expectedUtc');
    });

    test('修復後的行為 - 正確處理時區轉換', () {
      const rssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>Fixed behavior test</description>
    <item>
      <title>Test Article</title>
      <link>https://example.com/article</link>
      <description>Test article</description>
      <pubDate>Thu, 28 Aug 2025 00:46:04 +0800</pubDate>
    </item>
  </channel>
</rss>''';

      final feed = parser.parse(rssXml);
      final item = feed.items.first;

      // 修復後應該正確處理時區轉換
      final correctBehavior = DateTime.utc(2025, 8, 27, 16, 46, 4);

      print('原始字串: Thu, 28 Aug 2025 00:46:04 +0800');
      print('解析結果: ${item.pubDate}');
      print('正確結果: $correctBehavior');
      print('時區偏移量: 8 小時 (已正確處理)');

      // 修復後，這個測試應該 pass
      expect(item.pubDate, equals(correctBehavior), reason: '修復後應該正確處理時區轉換');
    });
  });
}
