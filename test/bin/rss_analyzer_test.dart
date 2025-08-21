import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  group('RSS Analyzer Tool', () {
    late String workingDir;

    setUpAll(() {
      workingDir = Directory.current.path;
    });

    test('should show help message', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_analyzer.dart',
        ['--help'],
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('RSS Agent Analyzer'));
      expect(result.stdout, contains('Usage:'));
      expect(result.stdout, contains('Examples:'));
    });

    test('should analyze RSS from stdin', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_analyzer.dart',
        [],
        stdin: BinTestUtils.sampleRssXml,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('RSS Feed Analysis'));
      expect(result.stdout, contains('Source: stdin'));
      expect(result.stdout, contains('Format: RSS 2.0'));
      expect(result.stdout, contains('Title: Test RSS Feed'));
      expect(result.stdout, contains('Total Items: 2'));
    });

    test('should analyze RSS from stdin with JSON format', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_analyzer.dart',
        ['--format', 'json'],
        stdin: BinTestUtils.sampleRssXml,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(0));

      final jsonOutput = jsonDecode(result.stdout);
      expect(jsonOutput['status'], equals('success'));
      expect(jsonOutput['analyzed_source'], equals('stdin'));
      expect(jsonOutput['feed_format'], equals('RSS 2.0'));
      expect(jsonOutput['feed_info']['title'], equals('Test RSS Feed'));
      expect(jsonOutput['feed_info']['items_count'], equals(2));
      expect(jsonOutput['items'], hasLength(2));
    });

    test('should analyze RSS from file', () async {
      final tempFile = await BinTestUtils.createTempFile(
        BinTestUtils.sampleRssXml,
        suffix: '.xml',
      );

      try {
        final result = await BinTestUtils.runDartScript(
          'bin/rss_analyzer.dart',
          ['--input', tempFile.path],
          workingDirectory: workingDir,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('RSS Feed Analysis'));
        expect(result.stdout, contains('Source: ${tempFile.path}'));
        expect(result.stdout, contains('Format: RSS 2.0'));
        expect(result.stdout, contains('Title: Test RSS Feed'));
      } finally {
        await BinTestUtils.cleanupTempFile(tempFile);
      }
    });

    test('should analyze RSS from file with verbose output', () async {
      final tempFile = await BinTestUtils.createTempFile(
        BinTestUtils.sampleRssXml,
        suffix: '.xml',
      );

      try {
        final result = await BinTestUtils.runDartScript(
          'bin/rss_analyzer.dart',
          ['--input', tempFile.path, '--verbose'],
          workingDirectory: workingDir,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('RSS Agent'));
        expect(result.stdout, contains('Analyzing: file: ${tempFile.path}'));
        expect(result.stdout, contains('Output format: pretty'));
        expect(result.stdout, contains('Reading RSS content from file...'));
        expect(result.stdout, contains('Parsing RSS content...'));
      } finally {
        await BinTestUtils.cleanupTempFile(tempFile);
      }
    });

    test('should handle file not found error', () async {
      final result = await BinTestUtils.runDartScript(
        'bin/rss_analyzer.dart',
        ['--input', '/nonexistent/file.xml'],
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('Input file not found'));
    });

    test('should handle invalid XML error', () async {
      const invalidXml = 'This is not valid XML content';

      final result = await BinTestUtils.runDartScript(
        'bin/rss_analyzer.dart',
        [],
        stdin: invalidXml,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
    });

    test('should handle empty stdin', () async {
      const emptyContent = '';
      final result = await BinTestUtils.runDartScript(
        'bin/rss_analyzer.dart',
        [],
        stdin: emptyContent,
        workingDirectory: workingDir,
      );

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('No content provided via stdin'));
    });

    test('should require input when no arguments provided and no stdin',
        () async {
      // This test simulates running without arguments in a terminal
      // We'll test this by using an empty stdin
      final result = await BinTestUtils.runDartScript(
        'bin/rss_analyzer.dart',
        [],
        stdin: '', // Provide empty stdin to avoid hanging
        workingDirectory: workingDir,
      );

      // Without stdin input, it should show error
      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('No content provided via stdin'));
    });

    group('URL parsing', () {
      test('should recognize HTTP URLs', () async {
        // Note: This will fail due to network, but should recognize URL format
        final result = await BinTestUtils.runDartScript(
          'bin/rss_analyzer.dart',
          ['http://test.example.com/feed.xml'],
          workingDirectory: workingDir,
        );

        // Should attempt to fetch URL (and fail due to fake domain)
        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('Error:'));
      });

      test('should recognize HTTPS URLs', () async {
        // Note: This will fail due to network, but should recognize URL format
        final result = await BinTestUtils.runDartScript(
          'bin/rss_analyzer.dart',
          ['https://test.example.com/feed.xml'],
          workingDirectory: workingDir,
        );

        // Should attempt to fetch URL (and fail due to fake domain)
        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('Error:'));
      });
    });

    group('format validation', () {
      test('should accept json format', () async {
        final result = await BinTestUtils.runDartScript(
          'bin/rss_analyzer.dart',
          ['--format', 'json'],
          stdin: BinTestUtils.sampleRssXml,
          workingDirectory: workingDir,
        );

        expect(result.exitCode, equals(0));
        expect(() => jsonDecode(result.stdout), returnsNormally);
      });

      test('should accept pretty format', () async {
        final result = await BinTestUtils.runDartScript(
          'bin/rss_analyzer.dart',
          ['--format', 'pretty'],
          stdin: BinTestUtils.sampleRssXml,
          workingDirectory: workingDir,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('RSS Feed Analysis'));
      });

      test('should default to pretty format', () async {
        final result = await BinTestUtils.runDartScript(
          'bin/rss_analyzer.dart',
          [],
          stdin: BinTestUtils.sampleRssXml,
          workingDirectory: workingDir,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('RSS Feed Analysis'));
        expect(result.stdout, isNot(startsWith('{')));
      });
    });
  });
}
