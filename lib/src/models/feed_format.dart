/// Supported feed formats
enum FeedFormat {
  /// RSS 2.0 format
  rss2('RSS 2.0'),

  /// Atom 1.0 format
  atom('Atom 1.0'),

  /// JSON Feed 1.1 format
  jsonFeed('JSON Feed 1.1'),

  /// Unknown/unsupported format
  unknown('Unknown');

  /// The human-readable display name for this feed format.
  final String displayName;

  const FeedFormat(this.displayName);

  @override
  String toString() => displayName;
}
