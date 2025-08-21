# Changelog

All notable changes to the rss_agent package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/changyy/rss_agent_dart/compare/v1.20250821.12035...HEAD
[1.20250821.12035]: https://github.com/changyy/rss_agent_dart/releases/tag/v1.20250821.12035