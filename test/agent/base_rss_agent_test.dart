import 'dart:io';
import 'package:test/test.dart';
import 'package:rss_agent/src/agent/base_rss_agent.dart';
import 'package:rss_agent/src/utils/cache_manager.dart';

// Test implementation of BaseRssAgent
class TestRssAgent extends BaseRssAgent {
  TestRssAgent({super.cacheConfig});
}

void main() {
  group('BaseRssAgent', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('base_rss_agent_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should create agent without cache config', () {
      final agent = TestRssAgent();

      expect(agent, isNotNull);
      expect(agent.cacheManager, isNull);
      expect(agent.httpClient, isNotNull);
      expect(agent.parser, isNotNull);

      agent.dispose();
    });

    test('should create agent with cache enabled', () {
      final cacheConfig = CacheConfig.custom(
        enabled: true,
        cacheDir: tempDir.path,
        expirationSeconds: 300,
      );
      final agent = TestRssAgent(cacheConfig: cacheConfig);

      expect(agent, isNotNull);
      expect(agent.cacheManager, isNotNull);
      expect(agent.cacheManager!.config.enabled, isTrue);
      expect(agent.cacheManager!.config.cacheDir, equals(tempDir.path));
      expect(agent.cacheManager!.config.expirationSeconds, equals(300));

      agent.dispose();
    });

    test('should create agent with cache disabled', () {
      final agent = TestRssAgent(cacheConfig: CacheConfig.disabled);

      expect(agent, isNotNull);
      expect(agent.cacheManager, isNull);

      agent.dispose();
    });

    test('should dispose HTTP client properly', () {
      final agent = TestRssAgent();

      // Should not throw when disposing
      expect(() => agent.dispose(), returnsNormally);
    });

    test('should handle network errors gracefully', () async {
      final agent = TestRssAgent();

      // Try to fetch from invalid URL
      expect(
        () => agent.fetchFeed('invalid://url'),
        throwsA(isA<RssAgentException>()),
      );

      agent.dispose();
    });

    test('should provide access to HTTP client and parser', () {
      final agent = TestRssAgent();

      expect(agent.httpClient, isNotNull);
      expect(agent.parser, isNotNull);

      agent.dispose();
    });

    test('should clear cache when caching enabled', () async {
      final cacheConfig = CacheConfig.custom(
        enabled: true,
        cacheDir: tempDir.path,
        expirationSeconds: 300,
      );
      final agent = TestRssAgent(cacheConfig: cacheConfig);

      // Should not throw
      await agent.clearCache();

      agent.dispose();
    });

    test('should handle clear cache when caching disabled', () async {
      final agent = TestRssAgent();

      // Should not throw even when cache is disabled
      await agent.clearCache();

      agent.dispose();
    });

    test('should get cache stats when caching enabled', () async {
      final cacheConfig = CacheConfig.custom(
        enabled: true,
        cacheDir: tempDir.path,
        expirationSeconds: 300,
      );
      final agent = TestRssAgent(cacheConfig: cacheConfig);

      final stats = await agent.getCacheStats();

      expect(stats, isNotNull);
      expect(stats.fileCount, equals(0)); // No cache files yet
      expect(stats.totalSizeBytes, equals(0));

      agent.dispose();
    });

    test('should get empty cache stats when caching disabled', () async {
      final agent = TestRssAgent();

      final stats = await agent.getCacheStats();

      expect(stats, isNotNull);
      expect(stats.fileCount, equals(0));
      expect(stats.totalSizeBytes, equals(0));

      agent.dispose();
    });

    test('should handle different cache configurations', () {
      // Test with system default cache
      final systemDefaultAgent = TestRssAgent(
        cacheConfig: const CacheConfig(),
      );
      expect(systemDefaultAgent.cacheManager, isNotNull);
      expect(systemDefaultAgent.cacheManager!.config.enabled, isTrue);
      expect(systemDefaultAgent.cacheManager!.config.cacheDir, isNull);
      systemDefaultAgent.dispose();

      // Test with custom cache directory
      final customAgent = TestRssAgent(
        cacheConfig: CacheConfig.custom(
          enabled: true,
          cacheDir: './custom-cache',
          expirationSeconds: 600,
        ),
      );
      expect(customAgent.cacheManager, isNotNull);
      expect(
          customAgent.cacheManager!.config.cacheDir, equals('./custom-cache'));
      expect(customAgent.cacheManager!.config.expirationSeconds, equals(600));
      customAgent.dispose();
    });
  });
}
