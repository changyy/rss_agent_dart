# RSS Agent for Dart

[![pub package](https://img.shields.io/pub/v/rss_agent.svg)](https://pub.dev/packages/rss_agent)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive RSS/Atom/JSON Feed monitoring service for Dart and Flutter. Not just a parser - `rss_agent` provides automatic monitoring, diff detection, smart scheduling, and real-time notifications for RSS feed updates.

## Features

- **Multi-Format Support**: RSS 2.0, Atom 1.0, JSON Feed 1.1
- **Automatic Monitoring**: Set up once and get notified of new content
- **Smart Diff Detection**: Only get notified of truly new articles
- **Intelligent Scheduling**: Adaptive polling intervals based on feed update patterns
- **Resource Efficient**: Built-in caching and deduplication
- **Flutter Ready**: Works seamlessly in both Dart and Flutter applications
- **Event-Driven**: Stream-based API for real-time updates
- **Batch Operations**: Monitor multiple feeds simultaneously
- **Error Recovery**: Automatic retry with exponential backoff

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  rss_agent: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Command Line Tools

The package includes powerful command-line tools for analyzing RSS feeds:

#### Single RSS Analyzer

Analyze individual RSS feeds:

```bash
# Analyze a feed with pretty output (default)
dart run rss_agent:rss_analyzer https://news.google.com/rss

# Analyze with JSON output  
dart run rss_agent:rss_analyzer https://feeds.bbci.co.uk/news/rss.xml --format json

# Verbose output with processing details
dart run rss_agent:rss_analyzer https://rss.cnn.com/rss/edition.rss --verbose

# Get help
dart run rss_agent:rss_analyzer --help
```

#### Batch RSS Analyzer

Process multiple RSS feeds from JSON array input:

```bash
# From file with simple URL array
echo '["https://feeds.bbci.co.uk/news/rss.xml", "https://rss.cnn.com/rss/edition.rss"]' > feeds.json
dart run rss_agent:rss_batch_analyzer --input feeds.json --format json

# From stdin with metadata objects
echo '[{"url": "https://feeds.bbci.co.uk/news/rss.xml", "name": "BBC News", "category": "news"}]' | dart run rss_agent:rss_batch_analyzer --verbose

# High concurrency processing
dart run rss_agent:rss_batch_analyzer --input feeds.json --concurrent 5

# Get help
dart run rss_agent:rss_batch_analyzer --help
```

**JSON Input Formats:**

Simple URL array:
```json
[
  "https://feeds.bbci.co.uk/news/rss.xml",
  "https://rss.cnn.com/rss/edition.rss"
]
```

With metadata objects:
```json
[
  {
    "url": "https://feeds.bbci.co.uk/news/rss.xml",
    "name": "BBC News",
    "category": "international_news",
    "description": "BBC News RSS feed",
    "priority": "high"
  }
]
```

**Key Features:**
- ✅ **Batch Processing**: Analyze multiple feeds concurrently (1-10 concurrent requests)
- ✅ **Flexible Input**: JSON array from file or stdin with URLs or metadata objects
- ✅ **Error Resilience**: Individual feed failures don't stop batch processing
- ✅ **Rich Metadata**: Support custom metadata fields for feed organization
- ✅ **Automatic Redirects**: Follows HTTP redirects automatically (like `curl -L`)
- ✅ **Multiple Formats**: Supports RSS 2.0, Atom 1.0, JSON Feed 1.1
- ✅ **JSON & Pretty Output**: Choose between structured JSON or human-readable format
- ✅ **Rich Analysis**: Extracts feed metadata, article details, media content, and categories

### Simple RSS Parsing (Programmatic)

```dart
import 'package:rss_agent/rss_agent.dart';

void main() async {
  final httpClient = RssHttpClient();
  final parser = Rss2Parser();
  
  try {
    // Fetch RSS content (supports redirects)
    final xmlContent = await httpClient.fetchString('https://example.com/feed.xml');
    
    // Parse the RSS feed
    final feed = parser.parse(xmlContent);
    
    print('Feed: ${feed.title}');
    print('Items: ${feed.items.length}');
    
    for (final item in feed.items) {
      print('- ${item.title} (${item.pubDate})');
    }
  } finally {
    httpClient.dispose();
  }
}
```

### Monitoring RSS Feeds

```dart
import 'package:rss_agent/rss_agent.dart';

void main() async {
  final agent = RssAgent();
  
  // Start monitoring a feed
  agent.monitor(
    'https://example.com/feed.xml',
    interval: Duration(minutes: 30),
  );
  
  // Listen for new articles
  agent.onNewArticles.listen((event) {
    print('New articles detected: ${event.articles.length}');
    for (final article in event.articles) {
      print('- ${article.title}');
      print('  ${article.link}');
    }
  });
  
  // Start the agent
  await agent.start();
  
  // Keep the program running
  await Future.delayed(Duration(hours: 24));
  
  // Clean up
  await agent.stop();
}
```

### Advanced Usage

```dart
import 'package:rss_agent/rss_agent.dart';

void main() async {
  final agent = RssAgent();
  
  // Configure the agent
  agent.configure(
    maxConcurrent: 5,
    userAgent: 'MyApp/1.0',
    timeout: Duration(seconds: 30),
    retryAttempts: 3,
    cacheEnabled: true,
    cacheDuration: Duration(hours: 1),
  );
  
  // Monitor multiple feeds with different strategies
  agent.monitorMultiple([
    FeedConfig(
      url: 'https://news.example.com/feed.xml',
      interval: Duration(minutes: 15),
      strategy: MonitorStrategy.adaptive,
    ),
    FeedConfig(
      url: 'https://blog.example.com/feed.xml',
      interval: Duration(hours: 1),
      strategy: MonitorStrategy.efficient,
    ),
  ]);
  
  // Listen to different events
  agent.onNewArticles.listen((event) {
    print('New articles from ${event.feedUrl}');
  });
  
  agent.onFeedUpdate.listen((event) {
    print('Feed updated: ${event.feedUrl}');
  });
  
  agent.onError.listen((event) {
    print('Error in ${event.feedUrl}: ${event.error}');
  });
  
  // Query historical data
  final recentArticles = await agent.getArticlesSince(
    DateTime.now().subtract(Duration(days: 7)),
  );
  
  await agent.start();
}
```

## Monitoring Strategies

The agent supports different monitoring strategies:

- **`MonitorStrategy.fixed`**: Check at fixed intervals
- **`MonitorStrategy.adaptive`**: Automatically adjust check frequency based on feed update patterns
- **`MonitorStrategy.peak`**: More frequent checks during peak hours
- **`MonitorStrategy.efficient`**: Minimize requests while ensuring timely updates

## Supported Feed Formats

- **RSS 2.0**: Full specification support including enclosures and extensions
- **Atom 1.0**: Complete Atom feed support with all standard elements
- **JSON Feed 1.1**: Modern JSON-based feed format

The agent automatically detects the feed format, or you can specify it explicitly:

```dart
// Auto-detect format
final feed = await agent.parseFeed(url);

// Force specific format
final rssFeed = await agent.parseRss2(url);
final atomFeed = await agent.parseAtom(url);
final jsonFeed = await agent.parseJsonFeed(url);
```

## API Reference

### RssAgent

The main class for RSS monitoring and parsing.

#### Methods

- `parseFeed(String url)`: Parse a feed once
- `monitor(String url, {Duration interval, MonitorStrategy strategy})`: Start monitoring a feed
- `monitorMultiple(List<FeedConfig> configs)`: Monitor multiple feeds
- `start()`: Start the monitoring service
- `stop()`: Stop all monitoring
- `pause()`: Temporarily pause monitoring
- `resume()`: Resume monitoring
- `getArticlesSince(DateTime since)`: Get articles since a specific date

#### Events

- `Stream<NewArticlesEvent> onNewArticles`: New articles detected
- `Stream<FeedUpdateEvent> onFeedUpdate`: Feed updated (may not have new articles)
- `Stream<FeedErrorEvent> onError`: Error occurred during monitoring

## Examples

Check the `example/` directory for more comprehensive examples:

- `simple_parser.dart`: Basic feed parsing
- `feed_monitor.dart`: Setting up feed monitoring
- `multi_feed_monitor.dart`: Monitoring multiple feeds
- `flutter_app.dart`: Integration with Flutter

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**changyy**

- GitHub: [@changyy](https://github.com/changyy)

## Support

If you find this package useful, please consider giving it a star on [GitHub](https://github.com/changyy/rss_agent_dart) and a like on [pub.dev](https://pub.dev/packages/rss_agent).

For bugs or feature requests, please [create an issue](https://github.com/changyy/rss_agent_dart/issues).
