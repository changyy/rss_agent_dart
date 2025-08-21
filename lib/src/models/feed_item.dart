import 'media_content.dart';

/// Represents an item/article in a feed
class FeedItem {
  /// Item title
  final String? title;

  /// Item description/content
  final String? description;

  /// Item link
  final String? link;

  /// Item unique identifier
  final String? guid;

  /// Item publication date
  final DateTime? pubDate;

  /// Item author
  final String? author;

  /// Item categories
  final List<String> categories;

  /// Item media content (images, videos, etc.)
  final List<MediaContent> media;

  /// Item source feed title
  final String? sourceFeed;

  /// Content hash for duplicate detection
  final String? contentHash;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// Creates a new [FeedItem] instance with the given properties.
  ///
  /// All parameters are optional, allowing for flexible item creation
  /// based on the available data from different feed formats.
  FeedItem({
    this.title,
    this.description,
    this.link,
    this.guid,
    this.pubDate,
    this.author,
    this.categories = const [],
    this.media = const [],
    this.sourceFeed,
    this.contentHash,
    this.metadata = const {},
  });

  /// Check if this item is the same as another (for duplicate detection)
  bool isSameAs(FeedItem other) {
    // First check GUID if both have it and they match
    if (guid != null && other.guid != null) {
      if (guid == other.guid) {
        return true;
      }
    }

    // Then check content hash if available and they match
    if (contentHash != null && other.contentHash != null) {
      if (contentHash == other.contentHash) {
        return true;
      }
    }

    // Then check link if available and they match
    if (link != null && other.link != null) {
      if (link == other.link) {
        return true;
      }
    }

    // If all else fails, check title and date
    if (title != null &&
        other.title != null &&
        pubDate != null &&
        other.pubDate != null) {
      return title == other.title && pubDate == other.pubDate;
    }

    // No match found
    return false;
  }

  /// Create a copy with updated fields
  FeedItem copyWith({
    String? title,
    String? description,
    String? link,
    String? guid,
    DateTime? pubDate,
    String? author,
    List<String>? categories,
    List<MediaContent>? media,
    String? sourceFeed,
    String? contentHash,
    Map<String, dynamic>? metadata,
  }) {
    return FeedItem(
      title: title ?? this.title,
      description: description ?? this.description,
      link: link ?? this.link,
      guid: guid ?? this.guid,
      pubDate: pubDate ?? this.pubDate,
      author: author ?? this.author,
      categories: categories ?? this.categories,
      media: media ?? this.media,
      sourceFeed: sourceFeed ?? this.sourceFeed,
      contentHash: contentHash ?? this.contentHash,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'FeedItem(title: $title, link: $link, pubDate: $pubDate)';
  }
}
