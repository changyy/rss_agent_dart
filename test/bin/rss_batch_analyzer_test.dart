import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  group('RSS Batch Analyzer Tool', () {
    late String workingDir;

    setUpAll(() {
      workingDir = Directory.current.path;
    });

    test('should show help message', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        ['--help'],
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('RSS Agent Batch Analyzer'));
      expect(result.stdout, contains('Usage:'));
      expect(result.stdout, contains('Examples:'));
      expect(result.stdout, contains('Input Format:'));
    });

    test('should analyze feeds from stdin config', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        [],
        stdin: BinTestUtils.sampleBatchConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('RSS Batch Analysis Results'));
      expect(result.stdout, contains('Total feeds: 2'));
      expect(result.stdout, contains('1. https://test1.example.com/rss.xml'));
      expect(result.stdout, contains('2. https://test2.example.com/feed.xml'));
      expect(result.stdout, contains('Name: Test Feed 2'));
      expect(result.stdout, contains('Category: test'));
    });

    test('should analyze feeds from config file', () async {
      final tempFile = await BinTestUtils.createTempFile(
        BinTestUtils.sampleBatchConfig,
        suffix: '.json',
      );

      try {
        final result = await BinTestUtils.runDartScript(
          'bin/rss_batch_analyzer.dart',
          ['--input', tempFile.path],
          workingDirectory: workingDir,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('RSS Batch Analysis Results'));
        expect(result.stdout, contains('Total feeds: 2'));
      } finally {
        await BinTestUtils.cleanupTempFile(tempFile);
      }
    });

    test('should output JSON format', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        ['--format', 'json'],
        stdin: BinTestUtils.sampleBatchConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));

      final jsonOutput = jsonDecode(result.stdout);
      expect(jsonOutput['status'], equals('completed'));
      expect(jsonOutput['total_feeds'], equals(2));
      expect(jsonOutput['results'], hasLength(2));

      // Check first result
      final result1 = jsonOutput['results'][0];
      expect(result1['status'], equals('error')); // Will fail due to fake URL
      expect(result1['url'], equals('https://test1.example.com/rss.xml'));

      // Check second result
      final result2 = jsonOutput['results'][1];
      expect(result2['status'], equals('error')); // Will fail due to fake URL
      expect(result2['url'], equals('https://test2.example.com/feed.xml'));
      expect(result2['name'], equals('Test Feed 2'));
    });

    test('should show verbose output', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        ['--verbose'],
        stdin: BinTestUtils.sampleBatchConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('RSS Agent Batch Analyzer'));
      expect(result.stdout, contains('Concurrent requests: 3'));
      expect(result.stdout, contains('Output format: pretty'));
      expect(result.stdout, contains('Input source: stdin'));
      expect(result.stdout, contains('Processing 2 RSS feeds...'));
      expect(result.stdout, contains('Processing batch 1/1: 2 feeds'));
    });

    test('should handle different concurrency settings', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        ['--concurrent', '1', '--verbose'],
        stdin: BinTestUtils.sampleBatchConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Concurrent requests: 1'));
      expect(
          result.stdout,
          contains(
              'Processing batch 1/2: 1 feeds')); // More batches due to lower concurrency
      expect(result.stdout, contains('Processing batch 2/2: 1 feeds'));
    });

    test('should handle file not found error', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
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
        'bin/rss_batch_analyzer.dart',
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
        'bin/rss_batch_analyzer.dart',
        [],
        stdin: '',
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('No URLs found in input'));
    });

    test('should handle non-array JSON', () async {
      const notArrayJson = '{"title": "Not an array"}';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        [],
        stdin: notArrayJson,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('Input must be a JSON array'));
    });

    test('should handle simple URL array', () async {
      const simpleUrls =
          '["https://test1.example.com/rss.xml", "https://test2.example.com/feed.xml"]';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        [],
        stdin: simpleUrls,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Total feeds: 2'));
      expect(result.stdout, contains('1. https://test1.example.com/rss.xml'));
      expect(result.stdout, contains('2. https://test2.example.com/feed.xml'));
      // Simple URLs won't have names or categories
      expect(result.stdout, isNot(contains('Name:')));
      expect(result.stdout, isNot(contains('Category:')));
    });

    test('should handle mixed URL formats', () async {
      const mixedUrls = '''[
        "https://simple.example.com/rss.xml",
        {
          "url": "https://complex.example.com/feed.xml",
          "name": "Complex Feed",
          "category": "test",
          "description": "A complex feed with metadata"
        }
      ]''';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        [],
        stdin: mixedUrls,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Total feeds: 2'));
      expect(result.stdout, contains('1. https://simple.example.com/rss.xml'));
      expect(
          result.stdout, contains('2. https://complex.example.com/feed.xml'));
      expect(result.stdout, contains('Name: Complex Feed'));
      expect(result.stdout, contains('Category: test'));
    });

    test('should handle URL object missing url field', () async {
      const invalidUrls = '[{"name": "No URL field"}]';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        [],
        stdin: invalidUrls,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('missing required "url" field'));
    });

    test('should handle invalid URL item type', () async {
      const invalidUrls = '[123]'; // Number instead of string or object

      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        [],
        stdin: invalidUrls,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('must be a string URL or object'));
    });

    test('should validate concurrent parameter bounds', () async {
      // Test with concurrent = 0 (should default or error)
      final result1 = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        ['--concurrent', '0'],
        stdin: BinTestUtils.sampleBatchConfig,
        workingDirectory: workingDir,
      );

      expect(result1.exitCode, equals(0)); // Should default to 3

      // Test with concurrent = 15 (should cap to 10)
      final result2 = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        ['--concurrent', '15', '--verbose'],
        stdin: BinTestUtils.sampleBatchConfig,
        workingDirectory: workingDir,
      );

      expect(result2.exitCode, equals(0));
      expect(result2.stdout,
          contains('Concurrent requests: 3')); // Should default to 3
    });

    test('should handle valid concurrent parameter', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_batch_analyzer.dart',
        ['--concurrent', '5', '--verbose'],
        stdin: BinTestUtils.sampleBatchConfig,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Concurrent requests: 5'));
    });
  });
}
