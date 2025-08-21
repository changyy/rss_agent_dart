/// Monitoring strategies for RSS feeds
enum MonitorStrategy {
  /// Fixed interval checking
  fixed,

  /// Adaptive interval based on feed update patterns
  adaptive,

  /// More frequent checks during peak hours
  peak,

  /// Minimize requests while ensuring timely updates
  efficient,

  /// Manual checking only
  manual;

  /// Get a human-readable description
  String get description {
    switch (this) {
      case MonitorStrategy.fixed:
        return 'Check at fixed intervals';
      case MonitorStrategy.adaptive:
        return 'Automatically adjust frequency based on update patterns';
      case MonitorStrategy.peak:
        return 'More frequent checks during peak hours';
      case MonitorStrategy.efficient:
        return 'Minimize requests while ensuring updates';
      case MonitorStrategy.manual:
        return 'Manual checking only';
    }
  }
}
