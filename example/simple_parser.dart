import 'package:rss_agent/rss_agent.dart';

/// Simple RSS parsing example
void main() async {
  print('RSS Agent ${RssAgentVersion.fullVersion}');
  print('Example: Simple RSS Parser');
  print('=' * 40);

  // Note: This is a basic structure example
  // The actual implementation will be developed using TDD approach

  try {
    print('This example will be implemented once the core parsers are ready.');
    print('Expected features:');
    print('- Parse RSS 2.0, Atom 1.0, and JSON Feed 1.1');
    print('- Display feed information');
    print('- List all articles with titles and dates');
    print('');
    print('Version info:');
    RssAgentVersion.versionInfo.forEach((key, value) {
      print('  $key: $value');
    });
  } catch (e) {
    print('Error: $e');
  }
}
