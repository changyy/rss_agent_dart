import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:rss_agent/src/utils/cache_manager.dart';

void main() {
  group('CacheConfig', () {
    test('should create default config', () {
      const config = CacheConfig();

      expect(config.enabled, isTrue);
      expect(config.cacheDir, isNull);
      expect(config.expirationSeconds, equals(180));
    });

    test('should create disabled config', () {
      const config = CacheConfig.disabled;

      expect(config.enabled, isFalse);
      expect(config.cacheDir, isNull);
      expect(config.expirationSeconds, equals(180));
    });

    test('should create custom config', () {
      final config = CacheConfig.custom(
        enabled: true,
        cacheDir: './custom-cache',
        expirationSeconds: 600,
      );

      expect(config.enabled, isTrue);
      expect(config.cacheDir, equals('./custom-cache'));
      expect(config.expirationSeconds, equals(600));
    });

    test('should have default config constant', () {
      const config = CacheConfig.defaultConfig;

      expect(config.enabled, isTrue);
      expect(config.cacheDir, isNull);
      expect(config.expirationSeconds, equals(180));
    });
  });

  group('CacheManager', () {
    late Directory tempDir;
    late CacheManager cacheManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rss_cache_test_');
      final config = CacheConfig.custom(
        enabled: true,
        cacheDir: tempDir.path,
        expirationSeconds: 300,
      );
      cacheManager = CacheManager(config);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should create cache manager with config', () {
      expect(cacheManager, isNotNull);
      expect(cacheManager.config.enabled, isTrue);
      expect(cacheManager.config.cacheDir, equals(tempDir.path));
    });

    test('should generate consistent cache keys', () {
      const url1 = 'https://example.com/feed.xml';
      const url2 = 'https://different.com/feed.xml';

      final key1a = cacheManager.getCacheKey(url1);
      final key1b = cacheManager.getCacheKey(url1);
      final key2 = cacheManager.getCacheKey(url2);

      expect(key1a, equals(key1b));
      expect(key1a, isNot(equals(key2)));
      expect(key1a, hasLength(32)); // MD5 hash length
    });

    test('should get cache file path', () {
      const url = 'https://example.com/feed.xml';

      final filePath = cacheManager.getCacheFilePath(url);

      expect(filePath, startsWith(tempDir.path));
      expect(filePath, endsWith('.xml'));
      expect(filePath, contains('rss_cache_'));
    });

    test('should save and retrieve cached content', () async {
      const url = 'https://example.com/feed.xml';
      const content = '''<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Test Item</title>
    </item>
  </channel>
</rss>''';

      // Save to cache
      await cacheManager.saveCachedContent(url, content);

      // Retrieve from cache
      final cachedContent = await cacheManager.getCachedContent(url);

      expect(cachedContent, equals(content));
    });

    test('should return null for non-existent cache', () async {
      const url = 'https://nonexistent.com/feed.xml';

      final cachedContent = await cacheManager.getCachedContent(url);

      expect(cachedContent, isNull);
    });

    test('should return null for expired cache', () async {
      const url = 'https://example.com/feed.xml';
      const content = 'test content';

      // Save content first
      await cacheManager.saveCachedContent(url, content);

      // Create cache manager with very short expiration
      final shortConfig = CacheConfig.custom(
        enabled: true,
        cacheDir: tempDir.path,
        expirationSeconds: 0, // Expire immediately
      );
      final shortCacheManager = CacheManager(shortConfig);

      // Wait a moment to ensure the file modification time is in the past
      await Future.delayed(const Duration(milliseconds: 100));

      // Should return null due to expiration (0 second expiration)
      final cachedContent = await shortCacheManager.getCachedContent(url);

      expect(cachedContent, isNull);
    });

    test('should handle cache directory creation', () async {
      final nonExistentDir = path.join(tempDir.path, 'nested', 'cache');
      final config = CacheConfig.custom(
        enabled: true,
        cacheDir: nonExistentDir,
        expirationSeconds: 300,
      );
      final manager = CacheManager(config);

      const url = 'https://example.com/feed.xml';
      const content = 'test content';

      // Should create directory and save content
      await manager.saveCachedContent(url, content);

      expect(Directory(nonExistentDir).existsSync(), isTrue);

      final retrieved = await manager.getCachedContent(url);
      expect(retrieved, equals(content));
    });

    test('should handle save errors gracefully', () async {
      // Create manager with invalid directory (read-only)
      final invalidConfig = CacheConfig.custom(
        enabled: true,
        cacheDir: '/invalid/readonly/path',
        expirationSeconds: 300,
      );
      final invalidManager = CacheManager(invalidConfig);

      const url = 'https://example.com/feed.xml';
      const content = 'test content';

      // Should not throw error, just fail silently
      expect(
        () => invalidManager.saveCachedContent(url, content),
        returnsNormally,
      );
    });

    test('should handle read errors gracefully', () async {
      const url = 'https://example.com/feed.xml';
      const content = 'test content';

      // Save content first
      await cacheManager.saveCachedContent(url, content);

      // Corrupt the cache file
      final filePath = cacheManager.getCacheFilePath(url);
      final file = File(filePath);
      await file.writeAsBytes([0xFF, 0xFE, 0xFD]); // Invalid UTF-8

      // Should return null instead of throwing
      final result = await cacheManager.getCachedContent(url);
      expect(result, isNull);
    });

    test('should use system temp directory when cacheDir is null', () {
      const config = CacheConfig(); // cacheDir is null
      final manager = CacheManager(config);

      const url = 'https://example.com/feed.xml';
      final filePath = manager.getCacheFilePath(url);

      // Should use system temp directory
      expect(filePath, startsWith(Directory.systemTemp.path));
    });

    test('should handle cross-platform default cache directory', () {
      const config = CacheConfig();
      final manager = CacheManager(config);

      final defaultDir = manager.getDefaultCacheDir();

      // Should return a valid directory path
      expect(defaultDir, isNotNull);
      expect(defaultDir, isNotEmpty);

      // Should be able to create a directory there (or fallback works)
      expect(() => Directory(defaultDir).path, returnsNormally);
    });
  });
}
