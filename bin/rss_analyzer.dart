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

  final inputFile = _parseInputFile(args);
  final url = _parseUrl(args);
  final format = _parseFormat(args);
  final verbose = args.contains('--verbose') || args.contains('-v');

  // Validate input: must have either URL, file, or stdin
  if (url == null && inputFile == null && stdin.hasTerminal) {
    stderr.writeln(
        'Error: Must specify either a URL, --input file, or provide content via stdin');
    _printUsage();
    exit(1);
  }

  String source;
  if (inputFile != null) {
    source = 'file: $inputFile';
  } else if (url != null) {
    source = 'url: $url';
  } else {
    source = 'stdin';
  }

  if (verbose) {
    print('RSS Agent ${RssAgentVersion.fullVersion}');
    print('Analyzing: $source');
    print('Output format: $format');
    print('=' * 50);
  }

  try {
    final result = await _analyzeFeed(url, inputFile, format, verbose);
    print(result);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<String> _analyzeFeed(
    String? url, String? inputFile, String format, bool verbose) async {
  final parser = Rss2Parser();
  String xmlContent;
  String source;

  if (inputFile != null) {
    // Read from file
    if (verbose) {
      print('Reading RSS content from file...');
    }

    final file = File(inputFile);
    if (!file.existsSync()) {
      throw Exception('Input file not found: $inputFile');
    }

    xmlContent = await file.readAsString();
    source = inputFile;
  } else if (url != null) {
    // Read from URL
    final httpClient = RssHttpClient();
    try {
      if (verbose) {
        print('Fetching RSS feed from URL...');
      }

      xmlContent = await httpClient.fetchString(url);
      source = url;
    } finally {
      httpClient.dispose();
    }
  } else {
    // Read from stdin
    if (verbose) {
      print('Reading RSS content from stdin...');
    }

    final lines = <String>[];
    String? line;
    while ((line = stdin.readLineSync()) != null) {
      lines.add(line!);
    }

    xmlContent = lines.join('\n');
    source = 'stdin';

    if (xmlContent.trim().isEmpty) {
      throw Exception('No content provided via stdin');
    }
  }

  if (verbose) {
    print('Parsing RSS content...');
  }

  final feed = parser.parse(xmlContent);

  if (format == 'json') {
    return _formatAsJson(feed, source);
  } else {
    return _formatAsPretty(feed, source);
  }
}

String _formatAsJson(dynamic feed, String source) {
  final jsonData = {
    'status': 'success',
    'analyzed_source': source,
    'feed_format': feed.format.displayName,
    'feed_info': {
      'title': feed.title,
      'description': feed.description,
      'link': feed.link,
      'language': feed.language,
      'copyright': feed.copyright,
      'author': feed.author,
      'image_url': feed.imageUrl,
      'pub_date': feed.pubDate?.toIso8601String(),
      'last_build_date': feed.lastBuildDate?.toIso8601String(),
      'categories': feed.categories,
      'items_count': feed.items.length,
    },
    'items': feed.items
        .map((item) => {
              'title': item.title,
              'description': item.description,
              'link': item.link,
              'guid': item.guid,
              'author': item.author,
              'pub_date': item.pubDate?.toIso8601String(),
              'categories': item.categories,
              'media': item.media
                  .map((media) => {
                        'url': media.url,
                        'type': media.type,
                        'length': media.length,
                        'is_image': media.isImage,
                        'is_video': media.isVideo,
                        'is_audio': media.isAudio,
                      })
                  .toList(),
              'content_hash': item.contentHash,
            })
        .toList(),
    'analysis_time': DateTime.now().toIso8601String(),
    'version': RssAgentVersion.version,
  };

  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(jsonData);
}

String _formatAsPretty(dynamic feed, String source) {
  final buffer = StringBuffer()
    ..writeln('RSS Feed Analysis')
    ..writeln('=' * 50)
    ..writeln('Source: $source')
    ..writeln('Format: ${feed.format.displayName}')
    ..writeln()
    ..writeln('Feed Information:')
    ..writeln('  Title: ${feed.title ?? "N/A"}')
    ..writeln('  Description: ${feed.description ?? "N/A"}')
    ..writeln('  Link: ${feed.link ?? "N/A"}')
    ..writeln('  Language: ${feed.language ?? "N/A"}')
    ..writeln('  Author: ${feed.author ?? "N/A"}');

  if (feed.pubDate != null) {
    buffer.writeln('  Publication Date: ${feed.pubDate}');
  }
  if (feed.lastBuildDate != null) {
    buffer.writeln('  Last Build Date: ${feed.lastBuildDate}');
  }

  if (feed.categories.isNotEmpty) {
    buffer.writeln('  Categories: ${feed.categories.join(", ")}');
  }

  buffer
    ..writeln('  Total Items: ${feed.items.length}')
    ..writeln();

  if (feed.items.isNotEmpty) {
    buffer.writeln('Articles:');
    for (var i = 0; i < feed.items.length; i++) {
      final item = feed.items[i];
      buffer.writeln('  ${i + 1}. ${item.title ?? "Untitled"}');
      if (item.link != null) {
        buffer.writeln('     Link: ${item.link}');
      }
      if (item.pubDate != null) {
        buffer.writeln('     Date: ${item.pubDate}');
      }
      if (item.description != null && item.description!.isNotEmpty) {
        final desc = item.description!.length > 100
            ? '${item.description!.substring(0, 100)}...'
            : item.description!;
        buffer.writeln('     Description: $desc');
      }
      if (item.categories.isNotEmpty) {
        buffer.writeln('     Categories: ${item.categories.join(", ")}');
      }
      if (item.media.isNotEmpty) {
        buffer.writeln('     Media: ${item.media.length} attachments');
      }
      buffer.writeln();
    }
  }

  buffer
    ..writeln('Analysis completed at: ${DateTime.now()}')
    ..writeln('RSS Agent ${RssAgentVersion.fullVersion}');

  return buffer.toString();
}

String? _parseUrl(List<String> args) {
  // URL is the first positional argument (not starting with --)
  for (final arg in args) {
    if (!arg.startsWith('--') && !arg.startsWith('-')) {
      // Simple check for URL format
      if (arg.startsWith('http://') || arg.startsWith('https://')) {
        return arg;
      }
    }
  }
  return null;
}

String? _parseInputFile(List<String> args) {
  final index = args.indexOf('--input');
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null;
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

void _printUsage() {
  print('''
RSS Agent Analyzer ${RssAgentVersion.fullVersion}

Usage: dart run bin/rss_analyzer.dart [URL] [OPTIONS]

Input Sources (choose one):
  URL             RSS feed URL to analyze
  --input FILE    Read RSS content from file
  (stdin)         Read RSS content from stdin if no URL or --input provided

Options:
  --format FORMAT Output format (json|pretty, default: pretty)
  --verbose, -v   Verbose output
  --help, -h      Show this help message

Examples:

1. From URL:
   dart run bin/rss_analyzer.dart https://feeds.bbci.co.uk/news/rss.xml
   dart run bin/rss_analyzer.dart https://news.google.com/rss --format json --verbose

2. From file:
   dart run bin/rss_analyzer.dart --input feed.xml
   dart run bin/rss_analyzer.dart --input feed.xml --format json

3. From stdin:
   cat feed.xml | dart run bin/rss_analyzer.dart
   curl -s https://feeds.bbci.co.uk/news/rss.xml | dart run bin/rss_analyzer.dart --format json

4. Generate RSS and analyze:
   dart run bin/rss_generator.dart --input config.json | dart run bin/rss_analyzer.dart

Note: When using URL input, the tool automatically follows HTTP redirects (like curl -L)
''');
}
