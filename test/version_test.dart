import 'package:test/test.dart';
import 'package:rss_agent/src/version.dart';

void main() {
  group('RssAgentVersion', () {
    test('should have valid version format', () {
      final version = RssAgentVersion.version;

      expect(version, isNotEmpty);
      expect(version, matches(RegExp(r'^\d+\.\d{8}\.\d+$')));
    });

    test('should have valid build date format', () {
      final buildDate = RssAgentVersion.buildDate;

      expect(buildDate, hasLength(8));
      expect(buildDate, matches(RegExp(r'^\d{8}$')));

      // Should be a valid date (or fallback date)
      final year = int.parse(buildDate.substring(0, 4));
      final month = int.parse(buildDate.substring(4, 6));
      final day = int.parse(buildDate.substring(6, 8));

      expect(year, greaterThanOrEqualTo(1970)); // Allow fallback date 19700101
      expect(month, inInclusiveRange(1, 12));
      expect(day, inInclusiveRange(1, 31));
    });

    test('should have valid build time format', () {
      final buildTime = RssAgentVersion.buildTime;

      expect(buildTime, matches(RegExp(r'^\d{4}$')));

      // Should be a valid time
      final hour = int.parse(buildTime.substring(0, 2));
      final minute = int.parse(buildTime.substring(2, 4));

      expect(hour, inInclusiveRange(0, 23));
      expect(minute, inInclusiveRange(0, 59));
    });

    test('should provide full version string', () {
      final fullVersion = RssAgentVersion.fullVersion;

      expect(fullVersion, contains('RSS Agent'));
      expect(fullVersion, contains(RssAgentVersion.version));
    });

    test('should provide version info map', () {
      final versionInfo = RssAgentVersion.versionInfo;

      expect(versionInfo, isA<Map<String, String>>());
      expect(
          versionInfo.keys, containsAll(['version', 'major', 'date', 'time']));

      expect(versionInfo['version'], equals(RssAgentVersion.version));
      expect(versionInfo['major'], isNotEmpty);
      expect(versionInfo['date'], equals(RssAgentVersion.buildDate));
      expect(versionInfo['time'], equals(RssAgentVersion.buildTime));
    });

    test('should extract major version correctly', () {
      final versionInfo = RssAgentVersion.versionInfo;
      final majorVersion = versionInfo['major']!;
      final fullVersion = RssAgentVersion.version;

      expect(majorVersion, equals(fullVersion.split('.')[0]));
    });

    test('should provide base version info for derived packages', () {
      final baseVersionInfo = RssAgentVersion.baseVersionInfo;

      expect(baseVersionInfo, isA<Map<String, String>>());
      expect(baseVersionInfo.keys, contains('rss_agent'));
      expect(baseVersionInfo['rss_agent'], equals(RssAgentVersion.version));
    });

    test('should create version info instance', () {
      final instance = RssAgentVersion.instance;

      expect(instance, isA<RssAgentVersionInfo>());
      expect(instance, isA<BaseVersionInfo>());

      // Test BaseVersionInfo interface
      expect(instance.getPackageName(), equals('rss_agent'));
      expect(instance.getPackageVersion(), equals(RssAgentVersion.version));
      expect(instance.getBuildTimestamp(), isNotEmpty);
      expect(instance.getDependencies(),
          isEmpty); // Base package has no dependencies
      expect(
          instance.getFullVersionString(), equals(RssAgentVersion.fullVersion));

      final versionMap = instance.getVersionMap();
      expect(versionMap, isA<Map<String, dynamic>>());
      expect(versionMap['package'], equals('rss_agent'));
      expect(versionMap['version'], equals(RssAgentVersion.version));
    });
  });
}
