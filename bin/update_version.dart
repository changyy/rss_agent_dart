#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// Universal Version Updater for RSS Agent packages
///
/// Supports two types of packages:
/// 1. Base RSS Agent (rss_agent) - Format: 1.YYYYmmdd.1HHii
/// 2. Derived packages (rss_agent_for_xxx) - Format: semantic versioning
///
/// Usage:
///   dart run rss_agent:update_version                    # Auto-generate RSS Agent version
///   dart run rss_agent:update_version 1.20250821.12054  # Specific RSS Agent version
///   dart run rss_agent:update_version --semantic 1.2.3  # Semantic version for derived packages
///   dart run rss_agent:update_version --help            # Show help
void main(List<String> arguments) async {
  try {
    // Handle help request
    if (arguments.contains('--help') || arguments.contains('-h')) {
      showHelp();
      return;
    }

    // Detect package type
    final packageType = await detectPackageType();

    if (arguments.contains('--semantic')) {
      // Force semantic versioning mode
      if (arguments.length < 2) {
        print('❌ Error: --semantic flag requires a version argument');
        exit(1);
      }
      await updateSemanticVersion(arguments[1]);
    } else if (packageType == PackageType.baseRssAgent) {
      // RSS Agent base package (special format)
      await updateRssAgentVersion(arguments);
    } else {
      // Derived package (semantic versioning)
      if (arguments.isEmpty) {
        print('❌ Error: Derived packages require explicit version argument');
        showHelp();
        exit(1);
      }
      await updateSemanticVersion(arguments[0]);
    }
  } catch (e) {
    print('❌ Error updating version: $e');
    exit(1);
  }
}

/// Package type enumeration
enum PackageType { baseRssAgent, derivedPackage }

/// Detect the package type based on current directory structure
Future<PackageType> detectPackageType() async {
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    throw Exception('pubspec.yaml not found');
  }

  final content = await pubspecFile.readAsString();

  // Check if this is the base rss_agent package
  if (content.contains('name: rss_agent') &&
      !content.contains('name: rss_agent_for_')) {
    return PackageType.baseRssAgent;
  }

  return PackageType.derivedPackage;
}

/// Update RSS Agent base package version (1.YYYYmmdd.1HHii format)
Future<void> updateRssAgentVersion(List<String> arguments) async {
  final now = DateTime.now();
  String version;
  DateTime buildTime;

  if (arguments.isNotEmpty) {
    // Use specified version
    version = arguments.first;

    // Validate version format
    if (!isValidRssAgentVersion(version)) {
      print('❌ Invalid RSS Agent version format: $version');
      print('📋 Expected format: 1.YYYYmmdd.1HHii (e.g., 1.20250821.11045)');
      exit(1);
    }

    // Try to parse build time from version, fallback to current time
    buildTime = parseVersionDateTime(version) ?? now;
    print('📦 Using specified RSS Agent version: $version');
  } else {
    // Auto-generate version
    version = generateRssAgentVersion(now);
    buildTime = now;
    print('🔄 Auto-generating RSS Agent version: $version');
  }

  print('Updating RSS Agent version to: $version');

  // Update pubspec.yaml
  await updatePubspec(version);

  // Update version.dart for RSS Agent
  await updateRssAgentVersionDart(version, buildTime);

  print('✅ RSS Agent version updated successfully!');
  print('📦 Version: $version');
  print('📅 Build Date: ${formatDate(buildTime)}');
  print('🕒 Build Time: ${formatTime(buildTime)}');
}

/// Update derived package version (semantic versioning)
Future<void> updateSemanticVersion(String version) async {
  // Validate semantic version format
  if (!isValidSemanticVersion(version)) {
    print('❌ Invalid semantic version format: $version');
    print('📋 Expected format: MAJOR.MINOR.PATCH (e.g., 1.2.3)');
    exit(1);
  }

  print('📦 Updating derived package version to: $version');

  // Update pubspec.yaml
  await updatePubspec(version);

  // Update version.dart for derived package
  await updateDerivedVersionDart(version);

  print('✅ Derived package version updated successfully!');
  print('📦 Version: $version');
  print('📅 Build Timestamp: ${DateTime.now().toUtc().toIso8601String()}');
}

/// Generate RSS Agent version string in format: 1.YYYYmmdd.1HHii
String generateRssAgentVersion(DateTime dateTime) {
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

/// Update lib/src/version.dart for RSS Agent base package (JSON only)
Future<void> updateRssAgentVersionDart(
    String version, DateTime buildTime) async {
  final file = File('lib/src/version.dart');

  if (!await file.exists()) {
    throw Exception('lib/src/version.dart not found');
  }

  final buildDate = formatDate(buildTime);
  final buildTimeStr = formatTime(buildTime);

  // Create new version JSON
  final versionJson = {
    'package': 'rss_agent',
    'version': version,
    'build_date': buildDate,
    'build_time': buildTimeStr,
    'build_timestamp': '${buildDate}T$buildTimeStr',
    'dependencies': <String, String>{},
    'package_type': 'base'
  };

  // Read existing content
  final content = await file.readAsString();

  // Update only the JSON string, preserving all code structure
  final updatedContent = _updateJsonString(content, versionJson);

  await file.writeAsString(updatedContent);
  print('📝 Updated lib/src/version.dart (JSON only, code preserved)');
}

/// Update lib/version.dart for derived package (JSON only)
Future<void> updateDerivedVersionDart(String version) async {
  final file = File('lib/version.dart');

  if (!await file.exists()) {
    throw Exception('lib/version.dart not found');
  }

  final timestamp = DateTime.now().toUtc().toIso8601String();

  // Get package name from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  final pubspecContent = await pubspecFile.readAsString();
  final nameMatch = RegExp(r'name:\s*(.+)').firstMatch(pubspecContent);
  final packageName = nameMatch?.group(1)?.trim() ?? 'unknown_package';

  // Create new version JSON for derived package
  final versionJson = {
    'package': packageName,
    'version': version,
    'build_timestamp': timestamp,
    'dependencies': {'rss_agent': 'auto'}, // Will be resolved at runtime
    'package_type': 'derived'
  };

  // Read existing content
  final content = await file.readAsString();

  // Update only the JSON string, preserving all code structure
  final updatedContent = _updateJsonString(content, versionJson);

  await file.writeAsString(updatedContent);
  print('📝 Updated lib/version.dart (JSON only, code preserved)');
}

/// Helper function to update JSON string in Dart code while preserving all structure
String _updateJsonString(String content, Map<String, dynamic> newJsonData) {
  // Convert to pretty-printed JSON
  const encoder = JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(newJsonData);

  // Pattern to match the JSON string in const String _versionInfoJson = r'''...''';
  final pattern = RegExp(
      r"(const String _versionInfoJson = r'''[\s]*\n)(.+?)(\n[\s]*''';)",
      multiLine: true,
      dotAll: true);

  return content.replaceAllMapped(pattern, (match) {
    final prefix = match.group(1)!;
    final suffix = match.group(3)!;
    return '$prefix$jsonString$suffix';
  });
}

/// Show help information
void showHelp() {
  print('''
Universal RSS Agent Version Updater

USAGE:
  dart run rss_agent:update_version [version] [options]

AUTO-DETECTION:
  • Base RSS Agent package: Uses 1.YYYYmmdd.1HHii format
  • Derived packages: Uses semantic versioning format

RSS AGENT BASE PACKAGE:
  dart run rss_agent:update_version                    # Auto-generate: 1.20250828.12035
  dart run rss_agent:update_version 1.20250821.12054  # Specific version

DERIVED PACKAGES:
  dart run rss_agent:update_version 1.2.3             # Semantic version
  dart run rss_agent:update_version --semantic 2.0.0  # Force semantic mode

OPTIONS:
  --semantic     Force semantic versioning mode
  -h, --help     Show this help message

VERSION FORMATS:

RSS Agent Base Package (1.YYYYmmdd.1HHii):
  1.20250828.12035
  │ │         │
  │ │         └─── Build time (1HHmm)
  │ └───────────── Date (YYYYmmdd) 
  └─────────────── Major version

Derived Packages (Semantic Versioning):
  MAJOR.MINOR.PATCH[-prerelease][+build]
  Examples: 1.0.0, 1.2.3, 2.0.0-beta.1, 1.0.0+build.1

FEATURES:
  ✓ Auto-detects package type
  ✓ Updates pubspec.yaml version
  ✓ Updates version.dart with proper format
  ✓ Maintains BaseVersionInfo compatibility
  ✓ Preserves dependency version tracking
  ✓ Cross-platform support

EXAMPLES:
  # Base RSS Agent package
  cd external/rss_agent_dart
  dart run bin/update_version.dart                     # Auto-generate
  dart run bin/update_version.dart 1.20250828.15030   # Specific
  
  # Derived package  
  cd ../..
  dart run rss_agent:update_version 1.3.0             # Update to v1.3.0
  dart run rss_agent:update_version --semantic 2.0.0  # Force semantic
''');
}

/// Validate RSS Agent version format: 1.YYYYmmdd.1HHii
bool isValidRssAgentVersion(String version) {
  final pattern = RegExp(r'^\d+\.\d{8}\.1\d{4}$');
  return pattern.hasMatch(version);
}

/// Validate semantic version format
bool isValidSemanticVersion(String version) {
  final pattern =
      RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$');
  return pattern.hasMatch(version);
}

/// Parse DateTime from RSS Agent version string
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
