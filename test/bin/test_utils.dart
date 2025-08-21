import 'dart:io';
import 'dart:convert';

/// Utilities for testing command line tools
class BinTestUtils {
  /// Run a Dart script and capture output
  static Future<ProcessResult> runDartScript(
    String scriptPath,
    List<String> arguments, {
    String? stdin,
    String? workingDirectory,
  }) async {
    final allArgs = ['run', scriptPath, ...arguments];

    final process = await Process.start(
      'dart',
      allArgs,
      workingDirectory: workingDirectory,
    );

    if (stdin != null) {
      process.stdin.write(stdin);
      await process.stdin.close();
    }

    final stdout = await process.stdout.transform(utf8.decoder).join();
    final stderr = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;

    return ProcessResult(process.pid, exitCode, stdout, stderr);
  }

  /// Create a temporary file with content
  static Future<File> createTempFile(String content, {String? suffix}) async {
    final tempDir = await Directory.systemTemp.createTemp('rss_agent_test');
    final file = File('${tempDir.path}/temp${suffix ?? '.txt'}');
    await file.writeAsString(content);
    return file;
  }

  /// Clean up temporary files
  static Future<void> cleanupTempFile(File file) async {
    if (await file.exists()) {
      await file.parent.delete(recursive: true);
    }
  }

  /// Sample RSS XML for testing
  static const String sampleRssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test RSS Feed</title>
    <description>A test RSS feed for unit testing</description>
    <link>https://test.example.com</link>
    <language>en-us</language>
    <pubDate>Wed, 21 Aug 2025 12:00:00 GMT</pubDate>
    <lastBuildDate>Wed, 21 Aug 2025 13:00:00 GMT</lastBuildDate>
    <item>
      <title>Test Article 1</title>
      <description><![CDATA[First test article description]]></description>
      <link>https://test.example.com/article1</link>
      <guid>test-article-1</guid>
      <pubDate>Wed, 21 Aug 2025 10:00:00 GMT</pubDate>
      <category>test</category>
    </item>
    <item>
      <title>Test Article 2</title>
      <description><![CDATA[Second test article description]]></description>
      <link>https://test.example.com/article2</link>
      <guid>test-article-2</guid>
      <pubDate>Wed, 21 Aug 2025 11:00:00 GMT</pubDate>
      <category>example</category>
    </item>
  </channel>
</rss>''';

  /// Sample RSS generator config
  static const String sampleGeneratorConfig = '''{
  "title": "Test Generated Feed",
  "description": "A test generated RSS feed",
  "link": "https://test-generator.example.com",
  "language": "en-us",
  "author": "test@example.com",
  "categories": ["test", "example"],
  "urls": [
    "https://test.example.com/page1",
    {
      "url": "https://test.example.com/page2",
      "title": "Custom Page Title",
      "description": "Custom page description",
      "categories": ["custom"]
    }
  ]
}''';

  /// Sample batch analyzer config
  static const String sampleBatchConfig = '''[
  "https://test1.example.com/rss.xml",
  {
    "url": "https://test2.example.com/feed.xml",
    "name": "Test Feed 2",
    "category": "test"
  }
]''';
}
