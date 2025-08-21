#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:rss_agent/src/generators/rss2_generator.dart';
import 'package:rss_agent/src/models/feed.dart';
import 'package:rss_agent/src/models/feed_item.dart';
import 'package:rss_agent/src/models/feed_format.dart';
import 'package:rss_agent/src/version.dart';

void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final inputFile = _parseInputFile(args);
  final outputFile = _parseOutputFile(args);
  final verbose = args.contains('--verbose') || args.contains('-v');

  if (verbose) {
    print('RSS Generator ${RssAgentVersion.fullVersion}');
    print('Input source: ${inputFile ?? 'stdin'}');
    print('Output target: ${outputFile ?? 'stdout'}');
    print('=' * 50);
  }

  try {
    final config = await _readConfig(inputFile);
    final feed = await _createFeed(config, verbose);
    final generator = Rss2Generator();
    final rssXml = generator.generate(feed);

    await _writeOutput(rssXml, outputFile);

    if (verbose) {
      print('RSS feed generated successfully!');
      print('Feed title: ${feed.title}');
      print('Items count: ${feed.items.length}');
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<FeedConfig> _readConfig(String? inputFile) async {
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
    throw Exception('Input is empty');
  }

  try {
    final dynamic parsed = jsonDecode(jsonContent);

    if (parsed is! Map<String, dynamic>) {
      throw Exception('Input must be a JSON object');
    }

    return FeedConfig.fromJson(parsed);
  } catch (e) {
    throw Exception('Invalid JSON format: $e');
  }
}

Future<Feed> _createFeed(FeedConfig config, bool verbose) async {
  if (verbose) {
    print('Creating RSS feed: ${config.title}');
    print('Processing ${config.urls.length} URLs...');
  }

  final items = <FeedItem>[];

  for (var i = 0; i < config.urls.length; i++) {
    final urlConfig = config.urls[i];

    if (verbose) {
      print('Processing URL ${i + 1}/${config.urls.length}: ${urlConfig.url}');
    }

    final item = FeedItem(
      title: urlConfig.title ?? 'Link ${i + 1}',
      description: urlConfig.description ?? 'Generated link item',
      link: urlConfig.url,
      guid: urlConfig.url, // Use URL as GUID
      author: urlConfig.author,
      pubDate: urlConfig.pubDate ?? DateTime.now(),
      categories: urlConfig.categories,
      media: [], // No media for URL-based items
      contentHash: '', // Will be generated automatically
    );

    items.add(item);
  }

  return Feed(
    title: config.title,
    description: config.description,
    link: config.link,
    language: config.language,
    copyright: config.copyright,
    author: config.author,
    imageUrl: config.imageUrl,
    pubDate: config.pubDate ?? DateTime.now(),
    lastBuildDate: DateTime.now(),
    categories: config.categories,
    items: items,
    format: FeedFormat.rss2,
  );
}

Future<void> _writeOutput(String rssXml, String? outputFile) async {
  if (outputFile != null) {
    final file = File(outputFile);
    await file.writeAsString(rssXml);
  } else {
    print(rssXml);
  }
}

String? _parseInputFile(List<String> args) {
  final index = args.indexOf('--input');
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null; // read from stdin
}

String? _parseOutputFile(List<String> args) {
  final index = args.indexOf('--output');
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null; // write to stdout
}

void _printUsage() {
  print('''
RSS Generator ${RssAgentVersion.fullVersion}

Usage: dart run bin/rss_generator.dart [OPTIONS]

Options:
  --input FILE        Input JSON config file (default: read from stdin)
  --output FILE       Output RSS XML file (default: write to stdout)
  --verbose, -v       Verbose output
  --help, -h          Show this help message

Input JSON Format:
{
  "title": "My Custom RSS Feed",
  "description": "A generated RSS feed from URLs",
  "link": "https://example.com",
  "language": "en-us",
  "author": "author@example.com",
  "copyright": "Copyright 2025",
  "categories": ["news", "technology"],
  "urls": [
    "https://example.com/page1",
    {
      "url": "https://example.com/page2",
      "title": "Custom Page Title",
      "description": "Custom description for this link",
      "author": "specific-author@example.com",
      "categories": ["important"]
    }
  ]
}

Examples:

1. From file to file:
   dart run bin/rss_generator.dart --input config.json --output feed.xml

2. From stdin to stdout:
   echo '{"title":"Test Feed","urls":["https://example.com"]}' | dart run bin/rss_generator.dart

3. With verbose output:
   dart run bin/rss_generator.dart --input config.json --verbose

4. Generate and preview:
   dart run bin/rss_generator.dart --input config.json | head -20

The tool converts a list of URLs into a properly formatted RSS 2.0 XML feed.
Each URL becomes an RSS item with customizable title, description, and metadata.
''');
}

class FeedConfig {
  final String title;
  final String description;
  final String link;
  final String? language;
  final String? author;
  final String? copyright;
  final String? imageUrl;
  final DateTime? pubDate;
  final List<String> categories;
  final List<UrlItem> urls;

  FeedConfig({
    required this.title,
    required this.description,
    required this.link,
    this.language,
    this.author,
    this.copyright,
    this.imageUrl,
    this.pubDate,
    this.categories = const [],
    required this.urls,
  });

  factory FeedConfig.fromJson(Map<String, dynamic> json) {
    final urlsJson = json['urls'] as List<dynamic>?;
    if (urlsJson == null || urlsJson.isEmpty) {
      throw Exception('Missing required "urls" array');
    }

    final urls = <UrlItem>[];
    for (var i = 0; i < urlsJson.length; i++) {
      final item = urlsJson[i];

      if (item is String) {
        urls.add(UrlItem(url: item));
      } else if (item is Map<String, dynamic>) {
        final url = item['url'] as String?;
        if (url == null || url.isEmpty) {
          throw Exception('URL item at index $i missing required "url" field');
        }

        urls.add(UrlItem.fromJson(item));
      } else {
        throw Exception('URL item at index $i must be a string or object');
      }
    }

    return FeedConfig(
      title: json['title'] as String? ?? 'Generated RSS Feed',
      description:
          json['description'] as String? ?? 'RSS feed generated from URLs',
      link: json['link'] as String? ?? 'https://example.com',
      language: json['language'] as String?,
      author: json['author'] as String?,
      copyright: json['copyright'] as String?,
      imageUrl: json['imageUrl'] as String?,
      pubDate: json['pubDate'] != null
          ? DateTime.tryParse(json['pubDate'] as String)
          : null,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      urls: urls,
    );
  }
}

class UrlItem {
  final String url;
  final String? title;
  final String? description;
  final String? author;
  final DateTime? pubDate;
  final List<String> categories;

  UrlItem({
    required this.url,
    this.title,
    this.description,
    this.author,
    this.pubDate,
    this.categories = const [],
  });

  factory UrlItem.fromJson(Map<String, dynamic> json) {
    return UrlItem(
      url: json['url'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      author: json['author'] as String?,
      pubDate: json['pubDate'] != null
          ? DateTime.tryParse(json['pubDate'] as String)
          : null,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
