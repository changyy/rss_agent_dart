import 'package:rss_agent/rss_agent.dart';

void main() async {
  // Example 1: Parse an RSS feed
  await parseRssFeed();

  // Example 2: Generate an RSS feed
  await generateRssFeed();

  // Example 3: Use HTTP client to fetch feeds
  await fetchAndParseFeed();
}

/// Example of parsing RSS content
Future<void> parseRssFeed() async {
  print('=== RSS Parsing Example ===\n');

  const rssContent = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Example Blog</title>
    <link>https://example.com</link>
    <description>An example blog feed</description>
    <item>
      <title>First Post</title>
      <link>https://example.com/first-post</link>
      <description>This is the first post content</description>
      <pubDate>Mon, 01 Jan 2024 12:00:00 GMT</pubDate>
      <guid>https://example.com/first-post</guid>
    </item>
    <item>
      <title>Second Post</title>
      <link>https://example.com/second-post</link>
      <description>This is the second post content</description>
      <pubDate>Tue, 02 Jan 2024 12:00:00 GMT</pubDate>
      <guid>https://example.com/second-post</guid>
    </item>
  </channel>
</rss>''';

  final parser = Rss2Parser();
  final feed = parser.parse(rssContent);

  print('Feed Title: ${feed.title}');
  print('Feed Description: ${feed.description}');
  print('Feed Link: ${feed.link}');
  print('Number of items: ${feed.items.length}\n');

  for (var item in feed.items) {
    print('  - ${item.title}');
    print('    Link: ${item.link}');
    print('    Date: ${item.pubDate}');
    print('    Description: ${item.description}\n');
  }
}

/// Example of generating RSS content
Future<void> generateRssFeed() async {
  print('=== RSS Generation Example ===\n');

  // Create feed items
  final items = [
    FeedItem(
      title: 'Welcome to our blog',
      description: 'This is our first blog post using rss_agent',
      link: 'https://example.com/welcome',
      guid: 'post-001',
      pubDate: DateTime.now().subtract(const Duration(days: 2)),
      author: 'John Doe',
      categories: ['news', 'announcement'],
    ),
    FeedItem(
      title: 'RSS Agent Features',
      description: 'Learn about all the features of RSS Agent',
      link: 'https://example.com/features',
      guid: 'post-002',
      pubDate: DateTime.now().subtract(const Duration(days: 1)),
      author: 'Jane Smith',
      categories: ['tutorial', 'features'],
    ),
  ];

  // Create feed
  final feed = Feed(
    title: 'RSS Agent Blog',
    description: 'News and updates about RSS Agent',
    link: 'https://example.com',
    language: 'en-US',
    copyright: '© 2024 RSS Agent',
    pubDate: DateTime.now(),
    items: items,
    format: FeedFormat.rss2,
    author: 'RSS Agent Team',
    categories: ['technology', 'rss'],
  );

  // Generate RSS XML
  final generator = Rss2Generator();
  final rssXml = generator.generate(feed);

  print('Generated RSS XML (first 500 chars):');
  print(rssXml.substring(0, rssXml.length > 500 ? 500 : rssXml.length));
  print('...\n');
}

/// Example of fetching and parsing a feed from a URL
Future<void> fetchAndParseFeed() async {
  print('=== Fetch and Parse Feed Example ===\n');

  // Note: This is a demonstration. In real usage, replace with an actual RSS feed URL
  const feedUrl = 'https://example.com/rss';

  final client = RssHttpClient();

  try {
    print('Fetching feed from: $feedUrl');
    // This will fail with the example URL, but shows the proper usage
    final content = await client.fetchString(feedUrl);

    final parser = Rss2Parser();
    final feed = parser.parse(content);

    print('Successfully parsed feed: ${feed.title}');
    print('Items found: ${feed.items.length}');
  } catch (e) {
    print('Note: This example URL does not exist.');
    print('In real usage, replace with an actual RSS feed URL.');
    print('Error type: ${e.runtimeType}');
  } finally {
    client.dispose();
  }
}
