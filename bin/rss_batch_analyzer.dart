#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:rss_agent/src/utils/http_client.dart';
import 'package:rss_agent/src/parsers/rss2_parser.dart';
import 'package:rss_agent/src/version.dart';

void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final concurrent = _parseConcurrent(args);
  final format = _parseFormat(args);
  final verbose = args.contains('--verbose') || args.contains('-v');
  final inputFile = _parseInputFile(args);

  if (verbose) {
    print('RSS Agent Batch Analyzer ${RssAgentVersion.fullVersion}');
    print('Concurrent requests: $concurrent');
    print('Output format: $format');
    print('Input source: ${inputFile ?? 'stdin'}');
    print('=' * 50);
  }

  try {
    final urls = await _readUrls(inputFile);
    if (urls.isEmpty) {
      stderr.writeln('Error: No URLs found in input');
      exit(1);
    }

    if (verbose) {
      print('Processing ${urls.length} RSS feeds...');
    }

    final results = await _batchAnalyze(urls, concurrent, verbose);
    final output = _formatResults(results, format);
    print(output);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<List<UrlConfig>> _readUrls(String? inputFile) async {
  String jsonContent;

  if (inputFile != null) {
    final file = File(inputFile);
    if (!file.existsSync()) {
      throw Exception('Input file not found: $inputFile');
    }
    jsonContent = await file.readAsString();
  } else {
    // Read from stdin
    final lines = <String>[];
    String? line;
    while ((line = stdin.readLineSync()) != null) {
      lines.add(line!);
    }
    jsonContent = lines.join('\n');
  }

  jsonContent = jsonContent.trim();
  if (jsonContent.isEmpty) {
    return [];
  }

  try {
    final dynamic parsed = jsonDecode(jsonContent);

    if (parsed is! List) {
      throw Exception('Input must be a JSON array');
    }

    final urls = <UrlConfig>[];
    for (var i = 0; i < parsed.length; i++) {
      final item = parsed[i];

      if (item is String) {
        // Simple URL string
        urls.add(UrlConfig(url: item));
      } else if (item is Map<String, dynamic>) {
        // URL object with metadata
        final url = item['url'] as String?;
        if (url == null || url.isEmpty) {
          throw Exception('Item at index $i missing required "url" field');
        }

        urls.add(UrlConfig(
          url: url,
          name: item['name'] as String?,
          category: item['category'] as String?,
          description: item['description'] as String?,
          metadata: Map<String, dynamic>.from(item)..remove('url'),
        ));
      } else {
        throw Exception(
            'Item at index $i must be a string URL or object with "url" field');
      }
    }

    return urls;
  } catch (e) {
    throw Exception('Invalid JSON format: $e');
  }
}

Future<List<AnalysisResult>> _batchAnalyze(
    List<UrlConfig> urls, int concurrent, bool verbose) async {
  final results = <AnalysisResult>[];
  final httpClient = RssHttpClient();
  final parser = Rss2Parser();

  try {
    // Process in batches to control concurrency
    for (var i = 0; i < urls.length; i += concurrent) {
      final batch = urls.skip(i).take(concurrent).toList();

      if (verbose) {
        print(
            'Processing batch ${(i ~/ concurrent) + 1}/${(urls.length / concurrent).ceil()}: ${batch.length} feeds');
      }

      final futures = batch.map((urlConfig) async {
        try {
          if (verbose) {
            print('Fetching: ${urlConfig.url}');
          }

          final xmlContent = await httpClient.fetchString(urlConfig.url);
          final feed = parser.parse(xmlContent);

          return AnalysisResult(
            urlConfig: urlConfig,
            feed: feed,
            success: true,
          );
        } catch (e) {
          if (verbose) {
            print('Error processing ${urlConfig.url}: $e');
          }

          return AnalysisResult(
            urlConfig: urlConfig,
            error: e.toString(),
            success: false,
          );
        }
      });

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);
    }
  } finally {
    httpClient.dispose();
  }

  return results;
}

String _formatResults(List<AnalysisResult> results, String format) {
  if (format == 'json') {
    return _formatAsJson(results);
  } else {
    return _formatAsPretty(results);
  }
}

String _formatAsJson(List<AnalysisResult> results) {
  final jsonData = {
    'status': 'completed',
    'total_feeds': results.length,
    'successful': results.where((r) => r.success).length,
    'failed': results.where((r) => !r.success).length,
    'results': results.map((result) {
      if (result.success && result.feed != null) {
        return {
          'status': 'success',
          'url': result.urlConfig.url,
          'name': result.urlConfig.name,
          'category': result.urlConfig.category,
          'description': result.urlConfig.description,
          'metadata': result.urlConfig.metadata,
          'feed_format': result.feed!.format.displayName,
          'feed_info': {
            'title': result.feed!.title,
            'description': result.feed!.description,
            'link': result.feed!.link,
            'language': result.feed!.language,
            'copyright': result.feed!.copyright,
            'author': result.feed!.author,
            'image_url': result.feed!.imageUrl,
            'pub_date': result.feed!.pubDate?.toIso8601String(),
            'last_build_date': result.feed!.lastBuildDate?.toIso8601String(),
            'categories': result.feed!.categories,
            'items_count': result.feed!.items.length,
          },
          'items': result.feed!.items
              .take(5)
              .map((item) => {
                    'title': item.title,
                    'description': item.description,
                    'link': item.link,
                    'pub_date': item.pubDate?.toIso8601String(),
                    'categories': item.categories,
                  })
              .toList(),
        };
      } else {
        return {
          'status': 'error',
          'url': result.urlConfig.url,
          'name': result.urlConfig.name,
          'error': result.error,
        };
      }
    }).toList(),
    'analysis_time': DateTime.now().toIso8601String(),
    'version': RssAgentVersion.version,
  };

  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(jsonData);
}

String _formatAsPretty(List<AnalysisResult> results) {
  final buffer = StringBuffer()
    ..writeln('RSS Batch Analysis Results')
    ..writeln('=' * 50)
    ..writeln('Total feeds: ${results.length}')
    ..writeln('Successful: ${results.where((r) => r.success).length}')
    ..writeln('Failed: ${results.where((r) => !r.success).length}')
    ..writeln();

  for (var i = 0; i < results.length; i++) {
    final result = results[i];
    buffer.writeln('${i + 1}. ${result.urlConfig.url}');

    if (result.urlConfig.name != null) {
      buffer.writeln('   Name: ${result.urlConfig.name}');
    }
    if (result.urlConfig.category != null) {
      buffer.writeln('   Category: ${result.urlConfig.category}');
    }

    if (result.success && result.feed != null) {
      buffer
        ..writeln('   ✅ Success - ${result.feed!.format.displayName}')
        ..writeln('   Title: ${result.feed!.title ?? "N/A"}')
        ..writeln('   Items: ${result.feed!.items.length}');

      if (result.feed!.language != null) {
        buffer.writeln('   Language: ${result.feed!.language}');
      }
      if (result.feed!.lastBuildDate != null) {
        buffer.writeln('   Last Updated: ${result.feed!.lastBuildDate}');
      }
    } else {
      buffer
        ..writeln('   ❌ Failed')
        ..writeln('   Error: ${result.error}');
    }

    buffer.writeln();
  }

  buffer
    ..writeln('Analysis completed at: ${DateTime.now()}')
    ..writeln('RSS Agent ${RssAgentVersion.fullVersion}');

  return buffer.toString();
}

int _parseConcurrent(List<String> args) {
  final index = args.indexOf('--concurrent');
  if (index != -1 && index + 1 < args.length) {
    final value = int.tryParse(args[index + 1]);
    if (value != null && value > 0 && value <= 10) {
      return value;
    }
  }
  return 3; // default
}

String _parseFormat(List<String> args) {
  final formatIndex = args.indexOf('--format');
  if (formatIndex != -1 && formatIndex + 1 < args.length) {
    final format = args[formatIndex + 1].toLowerCase();
    if (format == 'json' || format == 'pretty') {
      return format;
    }
  }
  return 'pretty'; // default
}

String? _parseInputFile(List<String> args) {
  final index = args.indexOf('--input');
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null; // read from stdin
}

void _printUsage() {
  print('''
RSS Agent Batch Analyzer ${RssAgentVersion.fullVersion}

Usage: dart run bin/rss_batch_analyzer.dart [OPTIONS]

Options:
  --input FILE        Input JSON file (default: read from stdin)
  --format FORMAT     Output format (json|pretty, default: pretty)
  --concurrent N      Concurrent requests (1-10, default: 3)
  --verbose, -v       Verbose output
  --help, -h          Show this help message

Input Format:
  JSON array where each item is either:
  - A URL string: "https://example.com/feed.xml"
  - An object: {"url": "https://example.com/feed.xml", "name": "Example", "category": "news"}

Examples:

1. From file:
   echo '["https://feeds.bbci.co.uk/news/rss.xml", "https://rss.cnn.com/rss/edition.rss"]' > feeds.json
   dart run bin/rss_batch_analyzer.dart --input feeds.json --format json

2. From stdin:
   echo '["https://feeds.bbci.co.uk/news/rss.xml"]' | dart run bin/rss_batch_analyzer.dart

3. With metadata:
   echo '[{"url": "https://feeds.bbci.co.uk/news/rss.xml", "name": "BBC News", "category": "news"}]' | dart run bin/rss_batch_analyzer.dart --verbose

4. High concurrency:
   dart run bin/rss_batch_analyzer.dart --input feeds.json --concurrent 5

Note: The tool automatically follows HTTP redirects and handles various RSS formats.
''');
}

class UrlConfig {
  final String url;
  final String? name;
  final String? category;
  final String? description;
  final Map<String, dynamic> metadata;

  UrlConfig({
    required this.url,
    this.name,
    this.category,
    this.description,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

class AnalysisResult {
  final UrlConfig urlConfig;
  final dynamic feed;
  final String? error;
  final bool success;

  AnalysisResult({
    required this.urlConfig,
    this.feed,
    this.error,
    required this.success,
  });
}
