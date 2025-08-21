#!/usr/bin/env dart

import 'dart:io';

/// Version updater for RSS Agent
/// Format: 1.YYYYmmdd.1HHii
/// Example: 1.20250821.11045
void main(List<String> arguments) async {
  try {
    final now = DateTime.now();
    final version = generateVersion(now);

    print('Updating RSS Agent version to: $version');

    // Update pubspec.yaml
    await updatePubspec(version);

    // Update version.dart
    await updateVersionDart(version, now);

    print('✅ Version updated successfully!');
    print('📦 Version: $version');
    print('📅 Build Date: ${formatDate(now)}');
    print('🕒 Build Time: ${formatTime(now)}');
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
