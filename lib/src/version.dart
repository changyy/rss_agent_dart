import 'dart:convert';

/// Version information stored as JSON string (updated by update_version.dart)
const String _versionInfoJson = r'''
{
  "package": "rss_agent",
  "version": "1.20250828.12055",
  "build_date": "20250828",
  "build_time": "2055",
  "build_timestamp": "20250828T2055",
  "dependencies": {},
  "package_type": "base"
}
''';

/// Base version information interface for RSS Agent packages
abstract class BaseVersionInfo {
  /// Get package name
  String getPackageName();

  /// Get package version
  String getPackageVersion();

  /// Get build timestamp
  String getBuildTimestamp();

  /// Get dependency versions (base packages this package depends on)
  Map<String, String> getDependencies();

  /// Get full version string including dependencies
  String getFullVersionString();

  /// Get version info as Map
  Map<String, dynamic> getVersionMap();
}

/// Version information for RSS Agent
class RssAgentVersion {
  /// Parse version information from JSON
  static Map<String, dynamic> get _versionData {
    try {
      return json.decode(_versionInfoJson.trim()) as Map<String, dynamic>;
    } catch (e) {
      // Fallback in case of JSON parse error - use obvious fallback values
      return {
        'package': 'rss_agent',
        'version': '1.0.0',
        'build_date': '19700101',
        'build_time': '0000',
        'build_timestamp': '19700101T0000',
        'dependencies': <String, String>{},
        'package_type': 'base'
      };
    }
  }

  /// Current version of RSS Agent
  static String get version => _versionData['version'] as String;

  /// Build date in YYYYMMDD format
  static String get buildDate => _versionData['build_date'] as String;

  /// Build time in HHmm format
  static String get buildTime => _versionData['build_time'] as String;

  /// Full version string
  static String get fullVersion => 'RSS Agent v$version';

  /// Parse version components
  static Map<String, String> get versionInfo => {
        'version': version,
        'major': version.split('.')[0],
        'date': buildDate,
        'time': buildTime,
      };

  /// Get base RSS Agent version info (for use by derived packages)
  static Map<String, String> get baseVersionInfo => {
        'rss_agent': version,
      };

  /// Create version info instance for inheritance
  static RssAgentVersionInfo get instance => RssAgentVersionInfo();
}

/// RSS Agent version info implementation
class RssAgentVersionInfo implements BaseVersionInfo {
  @override
  String getPackageName() => 'rss_agent';

  @override
  String getPackageVersion() => RssAgentVersion.version;

  @override
  String getBuildTimestamp() =>
      '${RssAgentVersion.buildDate}T${RssAgentVersion.buildTime.padLeft(4, '0')}';

  @override
  Map<String, String> getDependencies() =>
      {}; // Base package has no RSS Agent dependencies

  @override
  String getFullVersionString() => RssAgentVersion.fullVersion;

  @override
  Map<String, dynamic> getVersionMap() => {
        'package': getPackageName(),
        'version': getPackageVersion(),
        'build_timestamp': getBuildTimestamp(),
        'dependencies': getDependencies(),
      };
}
