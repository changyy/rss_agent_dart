#!/usr/bin/env dart

import 'dart:io';

/// Version updater for RSS Agent
/// Format: 1.YYYYmmdd.1HHii
/// Example: 1.20250821.11045
///
/// Usage:
///   dart tool/update_version.dart                    # Auto-generate version
///   dart tool/update_version.dart 1.20250821.12054  # Use specified version
///   dart tool/update_version.dart --help            # Show help
void main(List<String> arguments) async {
  try {
    // Handle help request
    if (arguments.contains('--help') || arguments.contains('-h')) {
      showHelp();
      return;
    }

    final now = DateTime.now();
    String version;
    DateTime buildTime;

    if (arguments.isNotEmpty) {
      // Use specified version
      version = arguments.first;

      // Validate version format
      if (!isValidVersion(version)) {
        print('❌ Invalid version format: $version');
        print('📋 Expected format: 1.YYYYmmdd.1HHii (e.g., 1.20250821.11045)');
        exit(1);
      }

      // Try to parse build time from version, fallback to current time
      buildTime = parseVersionDateTime(version) ?? now;
      print('📦 Using specified version: $version');
    } else {
      // Auto-generate version
      version = generateVersion(now);
      buildTime = now;
      print('🔄 Auto-generating version: $version');
    }

    print('Updating RSS Agent version to: $version');

    // Update pubspec.yaml
    await updatePubspec(version);

    // Update version.dart
    await updateVersionDart(version, buildTime);

    print('✅ Version updated successfully!');
    print('📦 Version: $version');
    print('📅 Build Date: ${formatDate(buildTime)}');
    print('🕒 Build Time: ${formatTime(buildTime)}');
  } catch (e) {
    print('❌ Error updating version: $e');
    exit(1);
  }
}

/// Generate version string in format: 1.YYYYmmdd.1HHii
String generateVersion(DateTime dateTime) {
  final date = formatDate(dateTime);
  final time = formatTime(dateTime);
  return '1.$date.1$time';
}

/// Format date as YYYYmmdd
String formatDate(DateTime dateTime) {
  final year = dateTime.year.toString();
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year$month$day';
}

/// Format time as HHmm
String formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour$minute';
}

/// Update pubspec.yaml with new version
Future<void> updatePubspec(String version) async {
  final file = File('pubspec.yaml');

  if (!await file.exists()) {
    throw Exception('pubspec.yaml not found');
  }

  final content = await file.readAsString();
  final lines = content.split('\n');

  for (var i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('version:')) {
      lines[i] = 'version: $version';
      break;
    }
  }

  await file.writeAsString(lines.join('\n'));
  print('📝 Updated pubspec.yaml');
}

/// Update lib/src/version.dart with new version information
Future<void> updateVersionDart(String version, DateTime buildTime) async {
  final file = File('lib/src/version.dart');

  if (!await file.exists()) {
    throw Exception('lib/src/version.dart not found');
  }

  final buildDate = formatDate(buildTime);
  final buildTimeStr = formatTime(buildTime);

  final content = '''/// Version information for RSS Agent
class RssAgentVersion {
  /// Current version of RSS Agent
  static const String version = '$version';
  
  /// Build date in YYYYMMDD format
  static const String buildDate = '$buildDate';
  
  /// Build time in HHmm format
  static const String buildTime = '$buildTimeStr';
  
  /// Full version string
  static String get fullVersion => 'RSS Agent v\$version';
  
  /// Parse version components
  static Map<String, String> get versionInfo => {
    'version': version,
    'major': version.split('.')[0],
    'date': buildDate,
    'time': buildTime,
  };
}''';

  await file.writeAsString(content);
  print('📝 Updated lib/src/version.dart');
}

/// Show help information
void showHelp() {
  print('''
RSS Agent Version Updater

Usage:
  dart tool/update_version.dart [version] [options]

Arguments:
  version    Optional version string in format: 1.YYYYmmdd.1HHii
             If not provided, auto-generates based on current time

Options:
  -h, --help    Show this help message

Examples:
  dart tool/update_version.dart                    # Auto-generate: 1.20250821.11045
  dart tool/update_version.dart 1.20250821.12054  # Use specific version
  dart tool/update_version.dart 2.20250821.10000  # Use major version 2

Version Format:
  1.YYYYmmdd.1HHii
  │ │       │ │
  │ │       │ └─ Time (HHmm)
  │ │       └─── Build number (1 for standard)
  │ └─────────── Date (YYYYmmdd)
  └───────────── Major version (1, 2, 3, etc.)
''');
}

/// Validate version format: 1.YYYYmmdd.1HHii
bool isValidVersion(String version) {
  final pattern = RegExp(r'^\d+\.\d{8}\.1\d{4}$');
  return pattern.hasMatch(version);
}

/// Parse DateTime from version string
/// Returns null if parsing fails
DateTime? parseVersionDateTime(String version) {
  try {
    final parts = version.split('.');
    if (parts.length != 3) {
      return null;
    }

    final dateStr = parts[1]; // YYYYmmdd
    final timeStr = parts[2].substring(1); // Remove '1' prefix from 1HHmm

    if (dateStr.length != 8 || timeStr.length != 4) {
      return null;
    }

    final year = int.parse(dateStr.substring(0, 4));
    final month = int.parse(dateStr.substring(4, 6));
    final day = int.parse(dateStr.substring(6, 8));
    final hour = int.parse(timeStr.substring(0, 2));
    final minute = int.parse(timeStr.substring(2, 4));

    return DateTime(year, month, day, hour, minute);
  } catch (e) {
    return null;
  }
}
