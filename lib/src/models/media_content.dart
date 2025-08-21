/// Represents media content in a feed item
class MediaContent {
  /// Media URL
  final String url;

  /// Media type (image/jpeg, video/mp4, etc.)
  final String? type;

  /// Media title
  final String? title;

  /// Media description
  final String? description;

  /// Media file size in bytes
  final int? length;

  /// Media width in pixels
  final int? width;

  /// Media height in pixels
  final int? height;

  /// Media duration in seconds (for audio/video)
  final int? duration;

  MediaContent({
    required this.url,
    this.type,
    this.title,
    this.description,
    this.length,
    this.width,
    this.height,
    this.duration,
  });

  /// Check if this is an image
  bool get isImage {
    if (type == null) {
      return false;
    }
    return type!.startsWith('image/');
  }

  /// Check if this is a video
  bool get isVideo {
    if (type == null) {
      return false;
    }
    return type!.startsWith('video/');
  }

  /// Check if this is audio
  bool get isAudio {
    if (type == null) {
      return false;
    }
    return type!.startsWith('audio/');
  }

  @override
  String toString() {
    return 'MediaContent(url: $url, type: $type)';
  }
}
