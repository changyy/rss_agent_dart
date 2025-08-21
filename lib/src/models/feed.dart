import 'feed_item.dart';
import 'feed_format.dart';

/// Represents a parsed RSS/Atom/JSON feed
class Feed {
  /// Feed title
  final String? title;

  /// Feed description
  final String? description;

  /// Feed link
  final String? link;

  /// Feed language
  final String? language;

  /// Feed copyright
  final String? copyright;

  /// Feed publication date
  final DateTime? pubDate;

  /// Feed last build date
  final DateTime? lastBuildDate;

  /// Feed items/articles
  final List<FeedItem> items;

  /// Feed format type
  final FeedFormat format;

  /// Feed image URL
  final String? imageUrl;

  /// Feed author
  final String? author;

  /// Feed categories
  final List<String> categories;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  Feed({
    this.title,
    this.description,
    this.link,
    this.language,
    this.copyright,
    this.pubDate,
    this.lastBuildDate,
    required this.items,
    required this.format,
    this.imageUrl,
    this.author,
    this.categories = const [],
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  Feed copyWith({
    String? title,
    String? description,
    String? link,
    String? language,
    String? copyright,
    DateTime? pubDate,
    DateTime? lastBuildDate,
    List<FeedItem>? items,
    FeedFormat? format,
    String? imageUrl,
    String? author,
    List<String>? categories,
    Map<String, dynamic>? metadata,
  }) {
    return Feed(
      title: title ?? this.title,
      description: description ?? this.description,
      link: link ?? this.link,
      language: language ?? this.language,
      copyright: copyright ?? this.copyright,
      pubDate: pubDate ?? this.pubDate,
      lastBuildDate: lastBuildDate ?? this.lastBuildDate,
      items: items ?? this.items,
      format: format ?? this.format,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      categories: categories ?? this.categories,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Feed(title: $title, items: ${items.length}, format: $format)';
  }
}
