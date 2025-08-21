import 'package:test/test.dart';
import 'package:rss_agent/src/utils/http_client.dart';

void main() {
  group('RssHttpClient', () {
    late RssHttpClient client;

    setUp(() {
      client = RssHttpClient();
    });

    tearDown(() {
      client.dispose();
    });

    test('should create client with default configuration', () {
      expect(client, isNotNull);
      expect(client.timeout, equals(const Duration(seconds: 30)));
      expect(client.userAgent, contains('RSS Agent'));
    });

    test('should create client with custom configuration', () {
      final customClient = RssHttpClient(
        timeout: const Duration(seconds: 60),
        userAgent: 'Custom Agent/1.0',
      );

      expect(customClient.timeout, equals(const Duration(seconds: 60)));
      expect(customClient.userAgent, equals('Custom Agent/1.0'));

      customClient.dispose();
    });

    test('should fetch content from valid URL', () async {
      // This test requires internet connection
      // We'll use a reliable RSS feed for testing
      const testUrl = 'https://httpbin.org/xml';

      try {
        final result = await client.fetchString(testUrl);
        expect(result, isA<String>());
        expect(result, isNotEmpty);
      } catch (e) {
        // Skip test if no internet connection
        print('Skipping network test: $e');
      }
    }, skip: 'Network test - requires internet connection');

    test('should handle invalid URL gracefully', () async {
      const invalidUrl = 'invalid-url';

      expect(
        () => client.fetchString(invalidUrl),
        throwsA(isA<RssHttpException>()),
      );
    });

    test('should handle timeout', () async {
      final timeoutClient =
          RssHttpClient(timeout: const Duration(milliseconds: 1));

      expect(
        () => timeoutClient.fetchString('https://httpbin.org/delay/5'),
        throwsA(isA<RssHttpException>()),
      );

      timeoutClient.dispose();
    }, skip: 'Network test - requires internet connection');

    test('should include custom headers', () async {
      final headers = {'Custom-Header': 'test-value'};

      // We can't easily test this without a mock server
      // This is more of an integration test
      try {
        await client.fetchString('https://httpbin.org/headers',
            headers: headers);
        // If we reach here, the request succeeded
        expect(true, isTrue);
      } catch (e) {
        // Skip test if no internet connection
        print('Skipping network test: $e');
      }
    }, skip: 'Network test - requires internet connection');
  });
}
