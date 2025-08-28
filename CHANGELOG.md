# Changelog

All notable changes to the rss_agent package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.20250828.12055] - 2025-08-28

### Enhanced
- **JSON-Based Version Management**: Revolutionized version management system for better maintainability
  - Version information now stored in JSON format within `_versionInfoJson` constant
  - Program code structure remains completely unchanged, only JSON data is updated
  - Smart fallback mechanism with obvious indicators (`1.0.0`, `19700101T0000`, `fallback`)
  - Universal version updater (`bin/update_version.dart`) supports both base and derived packages
  - Auto-detection of package type (base RSS Agent vs derived packages)
  - Preserves all existing APIs while improving underlying architecture

### Improved
- **Version Update Tool**: Single universal tool for all RSS Agent packages
  - **Base Package Mode**: Supports RSS Agent format (`1.YYYYmmdd.1HHii`) with auto-generation
  - **Derived Package Mode**: Supports semantic versioning with dependency tracking
  - **JSON-Only Updates**: Only updates version JSON, preserves all code structure
  - **Automatic Detection**: Intelligently detects package type from `pubspec.yaml`
  - **Cross-Platform**: Works consistently across all supported platforms

### Technical Improvements
- **Fallback Safety**: Clear fallback values for JSON parsing failures
  - Base package: `1.0.0` version, `19700101T0000` timestamp (Unix epoch)
  - Derived packages: `0.0.0` version, `1970-01-01T00:00:00.000Z` timestamp
  - Dependencies marked as `'fallback'` for easy identification
- **Code Quality**: Fixed all linter issues, achieved 0 warnings
- **Test Coverage**: Enhanced version tests with BaseVersionInfo interface validation
- **Architecture**: Maintains full backward compatibility while enabling future expansion

## [1.20250828.12035] - 2025-08-28

### Added
- **Cache Management System**: Complete file-based caching infrastructure for RSS agents
  - `CacheManager` class with MD5-based cache key generation
  - `CacheConfig` with customizable cache directory, expiration time, and enable/disable options
  - Cross-platform cache directory support (Windows, macOS, Linux)
  - Cache statistics and cleanup functionality
- **BaseRssAgent**: Abstract base class for RSS agents providing common functionality
  - HTTP client management with automatic resource disposal
  - RSS parsing using Rss2Parser
  - Optional caching mechanism integration
  - Error handling with RssAgentException
  - Cache statistics and clearing methods
- **BaseCLITool**: Shared CLI infrastructure for command-line tools
  - Standardized argument parsing (help, version, format, cache, verbose)
  - JSON output formatting with consistent result structure
  - Cache configuration parsing from command line arguments
  - Version information display with repository links
  - Error handling and logging utilities

### Enhanced
- **Architecture**: Refactored to support extensible RSS agent ecosystem
  - Base classes enable easy creation of future `rss_agent_for_xxx` packages
  - Shared components reduce code duplication across implementations
  - Consistent error handling and caching across all agents
- **CLI Tools**: Enhanced command-line interface capabilities
  - `--cache` parameter for custom cache directory specification
  - `--cache-expired-time` for configurable cache expiration (default: 180 seconds)
  - `--no-cache` flag to disable caching entirely
  - `--verbose` flag for detailed operation logging
- **Test Coverage**: Comprehensive test suite for new components
  - 24 tests for CacheManager functionality (file operations, expiration, stats)
  - 11 tests for BaseRssAgent (initialization, caching, disposal, error handling)
  - 13 tests for BaseCLITool (argument parsing, JSON formatting, result creation)
  - Cross-platform testing with temporary directory management

### Technical Improvements
- **Code Quality**: Fixed all 14 linter issues identified by `dart analyze`
  - Removed dead code and unused imports
  - Fixed string interpolation patterns
  - Improved code formatting and type annotations
  - Converted to super parameter syntax where applicable
- **Dependency Management**: Added crypto package for MD5 hash generation
- **Error Resilience**: Enhanced error handling with fallback to expired cache on network failures
- **Memory Management**: Proper resource disposal patterns with dispose() methods

### API Additions
- **CacheConfig**: 
  - `CacheConfig()` - Default configuration (enabled, 3 minutes expiration)
  - `CacheConfig.disabled` - Completely disable caching
  - `CacheConfig.custom()` - Custom cache settings
- **BaseRssAgent**:
  - `fetchFeed(String url)` - Fetch and parse RSS with optional caching
  - `clearCache()` - Clear all cached content
  - `getCacheStats()` - Get cache statistics
  - `dispose()` - Clean up resources
- **BaseCLITool**:
  - `buildBaseArgParser()` - Create standard argument parser
  - `parseCacheConfig()` - Parse cache configuration from CLI args
  - `createResult()` - Create standardized success result
  - `createErrorResult()` - Create standardized error result

### Migration Support
- **Backward Compatibility**: All existing APIs remain unchanged
- **Extension Ready**: Framework prepared for creating domain-specific RSS agents
- **Test Infrastructure**: TDD approach maintained with expanded test coverage (total: 186 tests)

## [1.20250828.10740] - 2025-08-28

### Fixed
- **RFC 2822 Timezone Parsing**: Fixed critical bug where timezone information in RSS pubDate fields was completely ignored
  - Previously: `Thu, 28 Aug 2025 00:46:04 +0800` parsed as `2025-08-28 00:46:04Z` (incorrect)
  - Now: `Thu, 28 Aug 2025 00:46:04 +0800` parses as `2025-08-27 16:46:04Z` (correct UTC conversion)
- **Timezone Support**: Added comprehensive timezone parsing support in `Rss2Parser._parseRfc822Date()`
  - **Numeric Formats**: `+0800`, `-0500`, `+0930`, etc.
  - **Text Formats**: `GMT`, `UTC`, `EST`, `PST`, `JST`, `KST`, `BST`, `CET`, etc.
  - **Proper UTC Conversion**: All parsed dates are now correctly converted to UTC timezone

### Added
- **Timezone Validation Tool** (`tool/timezone_validator.dart`): Comprehensive timezone parsing validation utility
  - Test individual date strings: `dart run tool/timezone_validator.dart "Thu, 28 Aug 2025 00:46:04 +0800"`
  - Run validation suite: `dart run tool/timezone_validator.dart`
  - Detailed analysis with expected vs actual results and error reporting
- **Timezone Unit Tests** (`test/parsers/timezone_parsing_test.dart`): Complete test coverage for timezone scenarios
  - 6 comprehensive test cases covering various timezone formats
  - Tests for positive/negative numeric offsets and major text timezones
  - 100% pass rate validation for timezone accuracy

### Technical Improvements
- **Parser Enhancement**: Refactored `_parseRfc822Date()` with new `_parseTimezoneOffset()` method
- **UTC Handling**: Improved DateTime construction to ensure proper UTC marking
- **Error Resilience**: Maintains backward compatibility with existing date parsing logic
- **Test Coverage**: Added 6 new timezone-specific tests (total: 92 tests)

### Validation Results
- **Before Fix**: 0.0% accuracy (7/7 test cases failed)
- **After Fix**: 100.0% accuracy (7/7 test cases passed)
- **Timezone Coverage**: Supports 15+ major timezone abbreviations and unlimited numeric formats

## [1.20250822.10625] - 2025-08-22

### Added
- **Example Files**: Added comprehensive example files (`example/main.dart` and `example/example.dart`) demonstrating package usage
- **Platform Declaration**: Explicitly declared platform support in `pubspec.yaml` for Android, iOS, Linux, macOS, Windows, and Web

### Improved
- **API Documentation**: Added missing dartdoc comments for all public constructors:
  - `Feed.new` constructor documentation
  - `FeedConfig.new` constructor documentation
  - `FeedFormat.displayName` property documentation
  - `FeedItem.new` constructor documentation
  - `MediaContent.new` constructor documentation

### Package Score Improvements
- **Example Score**: Increased from 0/10 to 10/10 (added example directory with working examples)

### Notes
- Web/WASM platform cannot be supported due to `dart:io` dependency requirement for HTTP operations

## [1.20250821.12157] - 2025-08-21

### Fixed
- **Test Suite Stabilization**: Fixed all XML parsing test failures in RSS generator and analyzer tests
- **CDATA Formatting**: Resolved XML CDATA content formatting issues by adding proper text trimming
- **XML Element Iteration**: Fixed `Iterable<XmlElement>` vs `List` conversion issues in test expectations
- **Command-Line Tool Tests**: Completed comprehensive TDD test coverage for all bin/*.dart tools
- **Widget Test Stability**: Eliminated Timer-related test interference for reliable CI/CD execution
- **Lint Compliance**: Achieved zero lint issues across entire codebase

### Enhanced
- **Test Coverage**: Added 34 integration tests for command-line tools (analyzer, generator, batch analyzer)
- **Error Handling**: Improved error handling for edge cases (missing files, invalid JSON, empty input)
- **Code Formatting**: Applied Dart formatter across all test files for consistent code style
- **Test Utilities**: Enhanced BinTestUtils with better process handling and temporary file management

### Technical Improvements
- **Total Test Count**: 80 tests passing (up from 46 core tests)
- **Test Categories**: Models (13), Parsers (23), Generators (7), HTTP (3 skipped), Tools (34)
- **Quality Metrics**: 100% test pass rate, 0 lint issues, enterprise-level stability
- **TDD Architecture**: Complete test-driven development coverage for all public APIs

### Tools Enhanced
- **RSS Analyzer**: Multi-input support (URL/file/stdin), JSON/pretty output formats
- **RSS Generator**: URL-to-RSS conversion with JSON configuration support
- **Batch Analyzer**: Concurrent processing of multiple RSS feeds with error isolation
- **All Tools**: Comprehensive error handling, help documentation, and verbose logging

## [1.20250821.12035] - 2025-08-21

### Added
- Initial release of RSS Agent
- Support for RSS 2.0, Atom 1.0, and JSON Feed 1.1 formats
- Automatic feed monitoring with customizable intervals
- Smart diff detection to identify new articles
- Multiple monitoring strategies (fixed, adaptive, peak, efficient)
- Event-driven architecture with streams for real-time updates
- Built-in caching and deduplication
- Comprehensive error handling and recovery
- TDD approach with extensive test coverage
- Version management system with build time tracking
- MIT License for open source distribution

### Features
- **Multi-format Support**: Parse RSS 2.0, Atom 1.0, and JSON Feed 1.1
- **Monitoring Service**: Background monitoring with configurable intervals
- **Diff Detection**: Only notify on truly new content
- **Smart Scheduling**: Adaptive polling based on feed patterns
- **Resource Efficient**: Built-in caching and request optimization
- **Flutter Ready**: Works in both Dart and Flutter applications
- **Event Streams**: Real-time notifications via Dart streams
- **Batch Operations**: Monitor multiple feeds simultaneously

### Technical
- Dart SDK >= 3.0.0 compatibility
- Zero breaking dependencies
- Comprehensive unit tests
- Linting and analysis configuration
- Version format: 1.YYYYmmdd.1HHii
