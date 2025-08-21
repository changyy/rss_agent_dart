import 'package:rss_agent/rss_agent.dart';

void main() {
  // Parse RSS content
  const rssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Tech News</title>
    <link>https://technews.example.com</link>
    <description>Latest technology news</description>
    <item>
      <title>New Flutter Release</title>
      <link>https://technews.example.com/flutter-release</link>
      <description>Flutter 3.x has been released with exciting new features</description>
      <pubDate>Mon, 15 Jan 2024 10:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>''';

  // Parse the RSS feed
  final parser = Rss2Parser();
  final feed = parser.parse(rssXml);

  // Access feed properties
  print('Feed: ${feed.title}');
  print('Description: ${feed.description}');
  print('Items: ${feed.items.length}');

  // Access item properties
  for (final item in feed.items) {
    print('\nItem: ${item.title}');
    print('Link: ${item.link}');
    print('Published: ${item.pubDate}');
  }

  // Generate RSS feed
  final newFeed = Feed(
    title: 'My Blog',
    description: 'Personal blog about Dart and Flutter',
    link: 'https://myblog.example.com',
    items: [
      FeedItem(
        title: 'Getting Started with RSS Agent',
        description: 'Learn how to use RSS Agent in your Dart projects',
        link: 'https://myblog.example.com/rss-agent-intro',
        pubDate: DateTime.now(),
      ),
    ],
    format: FeedFormat.rss2,
  );

  final generator = Rss2Generator();
  final generatedXml = generator.generate(newFeed);

  print('\nGenerated RSS:');
  print('${generatedXml.substring(0, 200)}...');
}
