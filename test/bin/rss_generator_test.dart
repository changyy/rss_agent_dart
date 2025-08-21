import 'dart:io';
import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'test_utils.dart';

void main() {
  group('RSS Generator Tool', () {
    late String workingDir;

    setUpAll(() {
      workingDir = Directory.current.path;
    });

    test('should show help message', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        ['--help'],
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('RSS Generator'));
      expect(result.stdout, contains('Usage:'));
      expect(result.stdout, contains('Examples:'));
      expect(result.stdout, contains('Input JSON Format:'));
    });

    test('should generate RSS from stdin config', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        [],
        stdin: BinTestUtils.sampleGeneratorConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));

      // Parse the XML output
      final xmlDoc = XmlDocument.parse(result.stdout);
      final rssElement = xmlDoc.findElements('rss').first;
      final channelElement = rssElement.findElements('channel').first;

      expect(rssElement.getAttribute('version'), equals('2.0'));
      expect(channelElement.findElements('title').first.innerText,
          equals('Test Generated Feed'));
      expect(channelElement.findElements('description').first.innerText,
          equals('A test generated RSS feed'));
      expect(channelElement.findElements('link').first.innerText,
          equals('https://test-generator.example.com'));
      expect(channelElement.findElements('language').first.innerText,
          equals('en-us'));
      expect(channelElement.findElements('managingEditor').first.innerText,
          equals('test@example.com'));

      // Check categories
      final categories = channelElement.findElements('category').toList();
      expect(categories, hasLength(2));
      expect(categories[0].innerText, equals('test'));
      expect(categories[1].innerText, equals('example'));

      // Check items
      final items = channelElement.findElements('item').toList();
      expect(items, hasLength(2));

      // Check first item (simple URL)
      final item1 = items[0];
      expect(item1.findElements('title').first.innerText, equals('Link 1'));
      expect(item1.findElements('description').first.innerText.trim(),
          equals('Generated link item'));
      expect(item1.findElements('link').first.innerText,
          equals('https://test.example.com/page1'));
      expect(item1.findElements('guid').first.innerText,
          equals('https://test.example.com/page1'));

      // Check second item (with custom data)
      final item2 = items[1];
      expect(item2.findElements('title').first.innerText,
          equals('Custom Page Title'));
      expect(item2.findElements('description').first.innerText.trim(),
          equals('Custom page description'));
      expect(item2.findElements('link').first.innerText,
          equals('https://test.example.com/page2'));
      expect(item2.findElements('category').first.innerText, equals('custom'));
    });

    test('should generate RSS from config file', () async {
      final tempFile = await BinTestUtils.createTempFile(
        BinTestUtils.sampleGeneratorConfig,
        suffix: '.json',
      );

      try {
        final result = await BinTestUtils.runDartScript(
          'bin/rss_generator.dart',
          ['--input', tempFile.path],
          workingDirectory: workingDir,
        );

        expect(result.exitCode, equals(0));

        // Should produce valid XML
        final xmlDoc = XmlDocument.parse(result.stdout);
        expect(xmlDoc.findElements('rss'), hasLength(1));
      } finally {
        await BinTestUtils.cleanupTempFile(tempFile);
      }
    });

    test('should generate RSS to output file', () async {
      final configFile = await BinTestUtils.createTempFile(
        BinTestUtils.sampleGeneratorConfig,
        suffix: '.json',
      );

      final outputFile = File('${configFile.parent.path}/output.xml');

      try {
        final result = await BinTestUtils.runDartScript(
          'bin/rss_generator.dart',
          ['--input', configFile.path, '--output', outputFile.path],
          workingDirectory: workingDir,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, isEmpty); // Output goes to file, not stdout

        expect(await outputFile.exists(), isTrue);
        final xmlContent = await outputFile.readAsString();
        final xmlDoc = XmlDocument.parse(xmlContent);
        expect(xmlDoc.findElements('rss'), hasLength(1));
      } finally {
        await BinTestUtils.cleanupTempFile(configFile);
      }
    });

    test('should show verbose output', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        ['--verbose'],
        stdin: BinTestUtils.sampleGeneratorConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('RSS Generator'));
      expect(result.stdout, contains('Input source: stdin'));
      expect(result.stdout, contains('Output target: stdout'));
      expect(result.stdout, contains('Creating RSS feed: Test Generated Feed'));
      expect(result.stdout, contains('Processing 2 URLs...'));
      expect(result.stdout, contains('RSS feed generated successfully!'));
    });

    test('should handle file not found error', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        ['--input', '/nonexistent/config.json'],
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('Input file not found'));
    });

    test('should handle invalid JSON config', () async {
      const invalidJson = '{ invalid json content }';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        [],
        stdin: invalidJson,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('Invalid JSON format'));
    });

    test('should handle empty input', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        [],
        stdin: '',
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('Input is empty'));
    });

    test('should handle config missing URLs', () async {
      const configWithoutUrls = '{"title": "Test Feed", "description": "Test"}';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        [],
        stdin: configWithoutUrls,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('Missing required "urls" array'));
    });

    test('should handle minimal config with defaults', () async {
      const minimalConfig = '{"urls": ["https://example.com/page1"]}';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        [],
        stdin: minimalConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));

      final xmlDoc = XmlDocument.parse(result.stdout);
      final channelElement =
          xmlDoc.findElements('rss').first.findElements('channel').first;

      // Check defaults are applied
      expect(channelElement.findElements('title').first.innerText,
          equals('Generated RSS Feed'));
      expect(channelElement.findElements('description').first.innerText,
          equals('RSS feed generated from URLs'));
      expect(channelElement.findElements('link').first.innerText,
          equals('https://example.com'));
    });

    test('should handle mixed URL formats', () async {
      const mixedConfig = '''{
        "title": "Mixed URLs Test",
        "urls": [
          "https://example.com/simple",
          {
            "url": "https://example.com/complex",
            "title": "Complex Item"
          }
        ]
      }''';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        [],
        stdin: mixedConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));

      final xmlDoc = XmlDocument.parse(result.stdout);
      final items = xmlDoc
          .findElements('rss')
          .first
          .findElements('channel')
          .first
          .findElements('item')
          .toList();

      expect(items, hasLength(2));
      expect(items[0].findElements('title').first.innerText, equals('Link 1'));
      expect(items[1].findElements('title').first.innerText,
          equals('Complex Item'));
    });

    test('should handle URL item missing URL field', () async {
      const invalidConfig = '''{
        "title": "Invalid Config",
        "urls": [
          {"title": "No URL field"}
        ]
      }''';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        [],
        stdin: invalidConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('missing required "url" field'));
    });

    test('should generate RSS with all optional fields', () async {
      const fullConfig = '''{
        "title": "Full Config Test",
        "description": "Complete RSS feed with all fields",
        "link": "https://full-test.example.com",
        "language": "en-gb",
        "author": "author@example.com",
        "copyright": "Copyright 2025 Test",
        "imageUrl": "https://example.com/image.png",
        "categories": ["test", "full"],
        "urls": [
          {
            "url": "https://example.com/article",
            "title": "Test Article",
            "description": "Article description",
            "author": "article-author@example.com",
            "categories": ["article", "test"]
          }
        ]
      }''';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_generator.dart',
        [],
        stdin: fullConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));

      final xmlDoc = XmlDocument.parse(result.stdout);
      final channelElement =
          xmlDoc.findElements('rss').first.findElements('channel').first;

      // Check all fields are present
      expect(channelElement.findElements('title').first.innerText,
          equals('Full Config Test'));
      expect(channelElement.findElements('language').first.innerText,
          equals('en-gb'));
      expect(channelElement.findElements('managingEditor').first.innerText,
          equals('author@example.com'));
      expect(channelElement.findElements('copyright').first.innerText,
          equals('Copyright 2025 Test'));
      expect(channelElement.findElements('category'), hasLength(2));

      // Check image
      final imageElement = channelElement.findElements('image').first;
      expect(imageElement.findElements('url').first.innerText,
          equals('https://example.com/image.png'));

      // Check item with all fields
      final item = channelElement.findElements('item').first;
      expect(
          item.findElements('title').first.innerText, equals('Test Article'));
      expect(item.findElements('description').first.innerText.trim(),
          equals('Article description'));
      expect(item.findElements('author').first.innerText,
          equals('article-author@example.com'));
      expect(item.findElements('category'), hasLength(2));
    });
  });
}
