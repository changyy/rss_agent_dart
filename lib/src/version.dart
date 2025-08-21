/// Version information for RSS Agent
class RssAgentVersion {
  /// Current version of RSS Agent
  static const String version = '1.20250821.12157';

  /// Build date in YYYYMMDD format
  static const String buildDate = '20250821';

  /// Build time in HHmm format
  static const String buildTime = '2157';

  /// Full version string
  static String get fullVersion => 'RSS Agent v$version';

  /// Parse version components
  static Map<String, String> get versionInfo => {
        'version': version,
        'major': version.split('.')[0],
        'date': buildDate,
        'time': buildTime,
      };
}
