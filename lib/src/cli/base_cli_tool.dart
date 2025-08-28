import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import '../utils/cache_manager.dart';
import '../models/feed.dart';
import '../version.dart';

/// Base class for CLI tools providing common argument parsing and output formatting
///
/// This class provides:
/// - Standard CLI arguments (help, version, format, cache, verbose)
/// - Cache configuration parsing
/// - JSON output formatting
/// - Error handling patterns
///
/// Subclasses should extend this to implement specific CLI tools
class BaseCLITool {
  /// Build base argument parser with common CLI options
  ///
  /// Returns an [ArgParser] with standard options that most RSS CLI tools need:
  /// - help/version flags
  /// - output format selection
  /// - cache configuration options
  /// - verbose output control
  static ArgParser buildBaseArgParser() {
    return ArgParser()
      ..addFlag('help',
          abbr: 'h', help: 'Show this help message', negatable: false)
      ..addFlag('version',
          abbr: 'v', help: 'Show version information', negatable: false)
      ..addOption('format',
          abbr: 'f',
          defaultsTo: 'json',
          allowed: ['json', 'xml'],
          help: 'Output format: json or xml')
      ..addOption('cache',
          abbr: 'c', help: 'Cache directory path (default: system temp)')
      ..addOption('cache-expired-time',
          defaultsTo: '180',
          help: 'Cache expiration time in seconds (default: 180)')
      ..addFlag('no-cache', help: 'Disable caching', negatable: false)
      ..addFlag('verbose', help: 'Verbose output', negatable: false);
  }

  /// Parse cache configuration from command line arguments
  ///
  /// [results] - Parsed command line arguments
  ///
  /// Returns [CacheConfig] object or null if caching is disabled
  /// Throws [FormatException] if cache-expired-time is not a valid integer
  static CacheConfig? parseCacheConfig(ArgResults results) {
    // Check if cache is explicitly disabled
    if (results['no-cache'] as bool) {
      return null;
    }

    // Parse cache expiration time
    final expirationStr = results['cache-expired-time'] as String;
    final expirationSeconds =
        int.parse(expirationStr); // Throws FormatException if invalid

    // Get cache directory (null means use system default)
    final cacheDir = results['cache'] as String?;

    return CacheConfig.custom(
      enabled: true,
      cacheDir: cacheDir,
      expirationSeconds: expirationSeconds,
    );
  }

  /// Format RSS feed as JSON string
  ///
  /// [feed] - The RSS feed to format
  ///
  /// Returns a formatted JSON string representing the feed
  static String formatFeedAsJson(Feed feed) {
    final data = _feedToMap(feed);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// Convert Feed object to Map for JSON serialization
  static Map<String, dynamic> _feedToMap(Feed feed) {
    return {
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
      'format': feed.format.displayName,
      'items_count': feed.items.length,
      'items': feed.items.map((item) => _feedItemToMap(item)).toList(),
    };
  }

  /// Convert FeedItem object to Map for JSON serialization
  static Map<String, dynamic> _feedItemToMap(dynamic item) {
    return {
      'title': item.title,
      'link': item.link,
      'description': item.description,
      'pub_date': item.pubDate?.toIso8601String(),
      'guid': item.guid,
      'author': item.author,
      'categories': item.categories ?? [],
      // Note: media property might not be available in all FeedItem implementations
      // We'll handle this safely
      if (item.media != null)
        'media': item.media
            ?.map((media) => {
                  'url': media.url,
                  'type': media.type,
                  'length': media.length,
                  'is_image': media.isImage,
                  'is_video': media.isVideo,
                  'is_audio': media.isAudio,
                })
            .toList(),
    };
  }

  /// Create standardized success result object
  ///
  /// [feed] - The RSS feed data
  /// [useCache] - Whether cached data was used
  /// [additionalMeta] - Additional metadata to include
  ///
  /// Returns a Map ready for JSON serialization
  static Map<String, dynamic> createResult({
    required Feed feed,
    required bool useCache,
    Map<String, dynamic>? additionalMeta,
  }) {
    final meta = <String, dynamic>{
      'rss_agent': RssAgentVersion.version,
      ...?additionalMeta,
    };

    return {
      'status': true,
      'data': _feedToMap(feed),
      'meta': meta,
      'use_cache': useCache,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create standardized error result object
  ///
  /// [errorMessage] - The error message to include
  /// [additionalMeta] - Additional metadata to include
  ///
  /// Returns a Map ready for JSON serialization
  static Map<String, dynamic> createErrorResult(
    String errorMessage, {
    Map<String, dynamic>? additionalMeta,
  }) {
    final meta = <String, dynamic>{
      'rss_agent': RssAgentVersion.version,
      ...?additionalMeta,
    };

    return {
      'status': false,
      'error': errorMessage,
      'meta': meta,
      'use_cache': false,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Output result as JSON to stdout
  ///
  /// [result] - The result Map to output
  static void outputJson(Map<String, dynamic> result) {
    const encoder = JsonEncoder.withIndent('  ');
    print(encoder.convert(result));
  }

  /// Log verbose message to stderr if verbose mode is enabled
  ///
  /// [message] - The message to log
  /// [verbose] - Whether verbose mode is enabled
  static void logVerbose(String message, bool verbose) {
    if (verbose) {
      stderr.writeln('[VERBOSE] $message');
    }
  }

  /// Print standardized version information
  ///
  /// [toolName] - Name of the CLI tool
  /// [additionalInfo] - Additional version information
  static void printVersion(String toolName,
      {Map<String, String>? additionalInfo}) {
    print(toolName);
    print(RssAgentVersion.fullVersion);

    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      print('Dependencies:');
      additionalInfo.forEach((name, version) {
        print('  $name: $version');
      });
    }

    print('');
    print('Repository: https://github.com/changyy/rss_agent_dart');
  }

  /// Print error message to stderr in a consistent format
  ///
  /// [message] - The error message
  static void printError(String message) {
    stderr.writeln('Error: $message');
  }

  /// Check if a result represents an error
  ///
  /// [results] - Parsed command line arguments
  ///
  /// Returns true if help or version flags are present
  static bool shouldShowHelpOrVersion(ArgResults results) {
    return (results['help'] as bool) || (results['version'] as bool);
  }

  /// Get verbose flag from results
  ///
  /// [results] - Parsed command line arguments
  ///
  /// Returns true if verbose mode is enabled
  static bool isVerbose(ArgResults results) {
    return results['verbose'] as bool;
  }

  /// Get format from results
  ///
  /// [results] - Parsed command line arguments
  ///
  /// Returns the requested output format
  static String getFormat(ArgResults results) {
    return results['format'] as String;
  }
}
