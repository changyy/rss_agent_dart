import '../agent/monitor_strategy.dart';

/// Configuration for monitoring a feed
class FeedConfig {
  /// Feed URL
  final String url;

  /// Check interval
  final Duration interval;

  /// Monitoring strategy
  final MonitorStrategy strategy;

  /// Custom headers for HTTP requests
  final Map<String, String>? headers;

  /// Enable duplicate detection
  final bool detectDuplicates;

  /// Enable caching
  final bool enableCache;

  /// Cache duration
  final Duration? cacheDuration;

  /// Maximum items to keep in history
  final int? maxHistoryItems;

  /// Feed-specific user agent
  final String? userAgent;

  /// Creates a new [FeedConfig] instance with the given properties.
  ///
  /// The [url] parameter is required and specifies the feed URL to monitor.
  /// All other parameters have sensible defaults for typical feed monitoring scenarios.
  FeedConfig({
    required this.url,
    this.interval = const Duration(minutes: 30),
    this.strategy = MonitorStrategy.adaptive,
    this.headers,
    this.detectDuplicates = true,
    this.enableCache = true,
    this.cacheDuration,
    this.maxHistoryItems = 1000,
    this.userAgent,
  });

  /// Create a copy with updated fields
  FeedConfig copyWith({
    String? url,
    Duration? interval,
    MonitorStrategy? strategy,
    Map<String, String>? headers,
    bool? detectDuplicates,
    bool? enableCache,
    Duration? cacheDuration,
    int? maxHistoryItems,
    String? userAgent,
  }) {
    return FeedConfig(
      url: url ?? this.url,
      interval: interval ?? this.interval,
      strategy: strategy ?? this.strategy,
      headers: headers ?? this.headers,
      detectDuplicates: detectDuplicates ?? this.detectDuplicates,
      enableCache: enableCache ?? this.enableCache,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
      userAgent: userAgent ?? this.userAgent,
    );
  }

  @override
  String toString() {
    return 'FeedConfig(url: $url, interval: $interval, strategy: $strategy)';
  }
}
