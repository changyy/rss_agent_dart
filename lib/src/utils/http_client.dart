import 'dart:io';
import 'package:http/http.dart' as http;
import '../version.dart';

/// Exception thrown by RSS HTTP client
class RssHttpException implements Exception {
  final String message;
  final int? statusCode;
  final String? url;

  RssHttpException(this.message, {this.statusCode, this.url});

  @override
  String toString() {
    final parts = ['RssHttpException: $message'];
    if (url != null) {
      parts.add('URL: $url');
    }
    if (statusCode != null) {
      parts.add('Status: $statusCode');
    }
    return parts.join(', ');
  }
}

/// HTTP client for fetching RSS feeds
class RssHttpClient {
  final Duration timeout;
  final String userAgent;
  final http.Client _httpClient;

  RssHttpClient({
    this.timeout = const Duration(seconds: 30),
    String? userAgent,
  })  : userAgent = userAgent ?? 'RSS Agent v${RssAgentVersion.version}',
        _httpClient = http.Client();

  /// Fetch content from URL as string with automatic redirect following
  Future<String> fetchString(String url,
      {Map<String, String>? headers, int maxRedirects = 5}) async {
    var currentUrl = url;
    var redirectCount = 0;

    while (redirectCount <= maxRedirects) {
      try {
        final uri = Uri.parse(currentUrl);
        final requestHeaders = <String, String>{
          'User-Agent': userAgent,
          'Accept':
              'application/rss+xml, application/xml, text/xml, application/atom+xml, application/json',
          ...?headers,
        };

        final response = await _httpClient
            .get(uri, headers: requestHeaders)
            .timeout(timeout);

        if (response.statusCode == 200) {
          return response.body;
        } else if (_isRedirect(response.statusCode)) {
          final location = response.headers['location'];
          if (location == null) {
            throw RssHttpException(
              'HTTP ${response.statusCode}: Redirect without location header',
              statusCode: response.statusCode,
              url: currentUrl,
            );
          }

          // Handle relative URLs
          final redirectUri = Uri.parse(location);
          if (!redirectUri.hasScheme) {
            final baseUri = Uri.parse(currentUrl);
            currentUrl = baseUri.resolve(location).toString();
          } else {
            currentUrl = location;
          }

          redirectCount++;
          continue;
        } else {
          throw RssHttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            statusCode: response.statusCode,
            url: currentUrl,
          );
        }
      } on SocketException catch (e) {
        throw RssHttpException(
          'Network error: ${e.message}',
          url: url,
        );
      } on FormatException catch (e) {
        throw RssHttpException(
          'Invalid URL format: ${e.message}',
          url: currentUrl,
        );
      } on HttpException catch (e) {
        throw RssHttpException(
          'HTTP error: ${e.message}',
          url: currentUrl,
        );
      } catch (e) {
        throw RssHttpException(
          'Unexpected error: $e',
          url: currentUrl,
        );
      }
    }

    throw RssHttpException(
      'Too many redirects (max: $maxRedirects)',
      url: url,
    );
  }

  /// Check if status code indicates a redirect
  bool _isRedirect(int statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }

  /// Dispose the HTTP client
  void dispose() {
    _httpClient.close();
  }
}
