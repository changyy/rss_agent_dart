import 'package:rss_agent/rss_agent.dart';

/// RSS monitoring example
void main() async {
  print('RSS Agent ${RssAgentVersion.fullVersion}');
  print('Example: RSS Feed Monitoring');
  print('=' * 40);

  // Note: This is a basic structure example
  // The actual implementation will be developed using TDD approach

  print('This example will demonstrate:');
  print('- Setting up feed monitoring');
  print('- Listening for new articles');
  print('- Different monitoring strategies');
  print('- Error handling');
  print('');
  print('Monitoring strategies available:');
  for (final strategy in MonitorStrategy.values) {
    print('  ${strategy.name}: ${strategy.description}');
  }

  print('');
  print('Implementation coming soon with TDD approach!');
}
