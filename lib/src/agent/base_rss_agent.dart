import '../utils/http_client.dart';
import '../parsers/rss2_parser.dart';
import '../utils/cache_manager.dart';
import '../models/feed.dart';

/// Base RSS agent exception
class RssAgentException implements Exception {
  final String message;
  final Exception? originalException;

  const RssAgentException(this.message, [this.originalException]);

  @override
  String toString() => 'RssAgentException: $message';
}

/// Base class for RSS agents providing common functionality
///
/// This abstract class provides:
/// - HTTP client management
/// - RSS parsing
/// - Optional caching mechanism
/// - Error handling
///
/// Subclasses should extend this to implement specific RSS services
/// (e.g., Google News, Reddit, Medium, etc.)
abstract class BaseRssAgent {
  final RssHttpClient _httpClient;
  final Rss2Parser _parser;
  final CacheManager? _cacheManager;

  /// Create a new RSS agent with optional cache configuration
  ///
  /// [cacheConfig] - Optional cache configuration. If null or disabled, no caching will be used.
  BaseRssAgent({CacheConfig? cacheConfig})
      : _httpClient = RssHttpClient(),
        _parser = Rss2Parser(),
        _cacheManager =
            cacheConfig?.enabled == true ? CacheManager(cacheConfig!) : null;

  /// Get the cache manager (if caching is enabled)
  CacheManager? get cacheManager => _cacheManager;

  /// Get the HTTP client
  RssHttpClient get httpClient => _httpClient;

  /// Get the RSS parser
  Rss2Parser get parser => _parser;

  /// Fetch and parse RSS feed from URL with optional caching
  ///
  /// This method:
  /// 1. Checks cache first (if enabled)
  /// 2. Fetches from network if not cached or cache expired
  /// 3. Parses the RSS content
  /// 4. Saves to cache (if enabled)
  /// 5. Returns parsed Feed object
  ///
  /// [url] - The RSS feed URL to fetch
  ///
  /// Returns a [Feed] object containing the parsed RSS data
  /// Throws [RssAgentException] if the fetch or parse operation fails
  Future<Feed> fetchFeed(String url) async {
    try {
      // Check cache first (if enabled)
      if (_cacheManager != null) {
        final cachedContent = await _cacheManager!.getCachedContent(url);
        if (cachedContent != null) {
          return _parser.parse(cachedContent);
        }
      }

      // Fetch from network
      final content = await _httpClient.fetchString(url);

      // Save to cache (if enabled)
      if (_cacheManager != null) {
        await _cacheManager!.saveCachedContent(url, content);
      }

      // Parse and return feed
      return _parser.parse(content);
    } on RssHttpException catch (e) {
      // If network fails but we have cache (even if expired), try to use it
      if (_cacheManager != null) {
        try {
          // Create a temporary cache manager with very long expiration to get expired cache
          final fallbackConfig = CacheConfig.custom(
            enabled: true,
            cacheDir: _cacheManager!.config.cacheDir,
            expirationSeconds:
                86400 * 365, // 1 year (effectively never expires)
          );
          final fallbackCacheManager = CacheManager(fallbackConfig);
          final expiredContent =
              await fallbackCacheManager.getCachedContent(url);
          if (expiredContent != null) {
            return _parser.parse(expiredContent);
          }
        } catch (cacheError) {
          // Ignore cache errors and throw original network error
        }
      }

      throw RssAgentException(
        'Failed to fetch RSS feed from $url: ${e.message}',
        e,
      );
    } catch (e) {
      throw RssAgentException(
        'Failed to fetch or parse RSS feed from $url: $e',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Dispose of resources (HTTP client, etc.)
  ///
  /// Call this method when you're done with the RSS agent to properly
  /// clean up HTTP client resources.
  void dispose() {
    _httpClient.dispose();
  }

  /// Clear all cached content (if caching is enabled)
  ///
  /// This will delete all cached RSS feed files from the cache directory.
  Future<void> clearCache() async {
    if (_cacheManager != null) {
      await _cacheManager!.clearCache();
    }
  }

  /// Get cache statistics (if caching is enabled)
  ///
  /// Returns information about cached files count and total size.
  /// Returns empty stats if caching is disabled.
  Future<CacheStats> getCacheStats() async {
    if (_cacheManager != null) {
      return await _cacheManager!.getCacheStats();
    }
    return const CacheStats(fileCount: 0, totalSizeBytes: 0);
  }
}
