/// RSS Agent for Dart - A comprehensive RSS/Atom/JSON Feed monitoring service
library rss_agent;

// Export version information
export 'src/version.dart';

// Export models
export 'src/models/feed.dart';
export 'src/models/feed_item.dart';
export 'src/models/feed_config.dart';
export 'src/models/feed_format.dart';
export 'src/models/media_content.dart';

// Export parsers
// export 'src/parsers/feed_parser.dart';
export 'src/parsers/rss2_parser.dart';
// export 'src/parsers/atom_parser.dart';
// export 'src/parsers/json_feed_parser.dart';

// Export generators
export 'src/generators/rss2_generator.dart';

// Export agent components
// export 'src/agent/rss_agent.dart';
export 'src/agent/monitor_strategy.dart';
// export 'src/agent/feed_monitor.dart';
// export 'src/agent/diff_detector.dart';

// Export events (TODO: implement these)
// export 'src/agent/events/feed_event.dart';
// export 'src/agent/events/new_articles_event.dart';
// export 'src/agent/events/feed_update_event.dart';
// export 'src/agent/events/feed_error_event.dart';

// Export utils
export 'src/utils/http_client.dart';
// export 'src/utils/cache_manager.dart';
