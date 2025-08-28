import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// Cache configuration for RSS agents
class CacheConfig {
  /// Enable or disable caching
  final bool enabled;

  /// Cache directory path (null = system temp directory)
  final String? cacheDir;

  /// Cache expiration time in seconds (default: 180 seconds = 3 minutes)
  final int expirationSeconds;

  const CacheConfig({
    this.enabled = true,
    this.cacheDir,
    this.expirationSeconds = 180,
  });

  /// Disable caching entirely
  static const CacheConfig disabled = CacheConfig(enabled: false);

  /// Default cache configuration (enabled, 3 minutes expiration)
  static const CacheConfig defaultConfig = CacheConfig();

  /// Custom cache configuration
  static CacheConfig custom({
    bool enabled = true,
    String? cacheDir,
    int expirationSeconds = 180,
  }) =>
      CacheConfig(
        enabled: enabled,
        cacheDir: cacheDir,
        expirationSeconds: expirationSeconds,
      );

  @override
  String toString() {
    return 'CacheConfig(enabled: $enabled, cacheDir: $cacheDir, '
        'expirationSeconds: $expirationSeconds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CacheConfig &&
        other.enabled == enabled &&
        other.cacheDir == cacheDir &&
        other.expirationSeconds == expirationSeconds;
  }

  @override
  int get hashCode {
    return enabled.hashCode ^ cacheDir.hashCode ^ expirationSeconds.hashCode;
  }
}

/// Manages RSS feed caching with file-based storage
class CacheManager {
  final CacheConfig config;

  CacheManager(this.config);

  /// Generate cache key from URL using MD5 hash
  String getCacheKey(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  /// Get cache file path for URL (cross-platform compatible)
  String getCacheFilePath(String url) {
    String cacheDir;

    if (config.cacheDir != null) {
      cacheDir = config.cacheDir!;
    } else {
      cacheDir = getDefaultCacheDir();
    }

    final cacheKey = getCacheKey(url);
    return path.join(cacheDir, 'rss_cache_$cacheKey.xml');
  }

  /// Get default cache directory based on platform
  String getDefaultCacheDir() {
    try {
      // Try to use system temp directory (works on all platforms)
      return Directory.systemTemp.path;
    } catch (e) {
      // Fallback for platforms where systemTemp might not work
      return './cache';
    }
  }

  /// Get cached content if exists and not expired
  Future<String?> getCachedContent(String url) async {
    try {
      final cacheFile = File(getCacheFilePath(url));
      if (!await cacheFile.exists()) {
        return null;
      }

      final stat = await cacheFile.stat();
      final age = DateTime.now().difference(stat.modified).inSeconds;

      if (age >= config.expirationSeconds) {
        return null; // Cache expired
      }

      return await cacheFile.readAsString();
    } catch (e) {
      return null; // Cache read failed, continue with network fetch
    }
  }

  /// Save content to cache
  Future<void> saveCachedContent(String url, String content) async {
    try {
      final cacheFile = File(getCacheFilePath(url));
      await cacheFile.parent.create(recursive: true);
      await cacheFile.writeAsString(content);
    } catch (e) {
      // Cache save failed, but don't fail the whole operation
      // This is intentionally silent to not interrupt the main RSS fetch operation
    }
  }

  /// Clear all cache files in the cache directory
  Future<void> clearCache() async {
    try {
      final cacheDir = config.cacheDir ?? getDefaultCacheDir();
      final directory = Directory(cacheDir);

      if (!await directory.exists()) {
        return;
      }

      await for (final entity in directory.list()) {
        if (entity is File && entity.path.contains('rss_cache_')) {
          await entity.delete();
        }
      }
    } catch (e) {
      // Ignore errors during cache clearing
    }
  }

  /// Get cache statistics (number of files, total size)
  Future<CacheStats> getCacheStats() async {
    try {
      final cacheDir = config.cacheDir ?? getDefaultCacheDir();
      final directory = Directory(cacheDir);

      if (!await directory.exists()) {
        return const CacheStats(fileCount: 0, totalSizeBytes: 0);
      }

      var fileCount = 0;
      var totalSize = 0;

      await for (final entity in directory.list()) {
        if (entity is File && entity.path.contains('rss_cache_')) {
          fileCount++;
          try {
            final stat = await entity.stat();
            totalSize += stat.size;
          } catch (e) {
            // Skip files that can't be accessed
          }
        }
      }

      return CacheStats(fileCount: fileCount, totalSizeBytes: totalSize);
    } catch (e) {
      return const CacheStats(fileCount: 0, totalSizeBytes: 0);
    }
  }
}

/// Cache statistics information
class CacheStats {
  final int fileCount;
  final int totalSizeBytes;

  const CacheStats({
    required this.fileCount,
    required this.totalSizeBytes,
  });

  /// Get total size in MB
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  /// Get total size in KB
  double get totalSizeKB => totalSizeBytes / 1024;

  @override
  String toString() {
    return 'CacheStats(files: $fileCount, size: ${totalSizeKB.toStringAsFixed(1)} KB)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CacheStats &&
        other.fileCount == fileCount &&
        other.totalSizeBytes == totalSizeBytes;
  }

  @override
  int get hashCode {
    return fileCount.hashCode ^ totalSizeBytes.hashCode;
  }
}
