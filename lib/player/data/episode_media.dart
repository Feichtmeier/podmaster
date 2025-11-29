import 'dart:typed_data';

import 'package:podcast_search/podcast_search.dart';

import '../../extensions/date_time_x.dart';
import 'unique_media.dart';

class EpisodeMedia extends UniqueMedia {
  EpisodeMedia(
    super.resource, {
    super.extras,
    super.httpHeaders,
    super.start,
    super.end,
    required this.episode,
    required String feedUrl,
    int? bitRate,
    String? albumArtUrl,
    List<String> genres = const [],
    String? collectionName,
    String? artist,
  }) : _feedUrl = feedUrl,
       _bitRate = bitRate,
       _albumArtUrl = albumArtUrl,
       _genres = genres,
       _collectionName = collectionName,
       _artist = artist;

  final Episode episode;
  final String _feedUrl;
  final int? _bitRate;
  final String? _albumArtUrl;
  String? get albumArtUrl => _albumArtUrl;
  final List<String> _genres;
  final String? _collectionName;
  final String? _artist;
  String? get url => episode.contentUrl;
  String get feedUrl => _feedUrl;
  String? get description => episode.description;

  @override
  Uint8List? get artData => null;

  @override
  Future<Uri?> get artUri => episode.imageUrl != null
      ? Future.value(Uri.tryParse(episode.imageUrl!))
      : Future.value(null);

  @override
  String? get artUrl => episode.imageUrl;

  @override
  String? get artist => _artist;

  @override
  int? get bitrate => _bitRate;

  @override
  String? get collectionName => _collectionName;

  @override
  DateTime? get creationDateTime => episode.publicationDate;

  @override
  Duration? get duration => episode.duration;

  @override
  List<String> get genres => _genres;

  @override
  String get id => episode.guid;

  @override
  String? get language => episode.transcripts.isNotEmpty
      ? episode.transcripts.first.language
      : null;

  @override
  List<String>? get performers => episode.persons.isNotEmpty
      ? episode.persons.map((p) => p.name).toList()
      : null;

  @override
  String? get title => episode.title;

  @override
  String? get collectionArtUrl => _albumArtUrl;

  EpisodeMedia copyWithX({
    required String resource,
    Map<String, dynamic>? extras,
    Map<String, String>? httpHeaders,
    Duration? start,
    Duration? end,
    Episode? episode,
    String? feedUrl,
    int? bitRate,
    String? albumArtUrl,
    List<String> genres = const [],
    String? collectionName,
    String? artist,
  }) => EpisodeMedia(
    resource,
    episode: episode ?? this.episode,
    feedUrl: feedUrl ?? this.feedUrl,
    bitRate: bitRate ?? _bitRate,
    albumArtUrl: albumArtUrl ?? _albumArtUrl,
    genres: genres.isEmpty ? _genres : genres,
    collectionName: collectionName ?? _collectionName,
    artist: artist ?? _artist,
    extras: extras ?? this.extras,
    start: start ?? this.start,
    end: end ?? this.end,
    httpHeaders: httpHeaders ?? this.httpHeaders,
  );

  String get audioDownloadId {
    final now = DateTime.now().toUtc().toString();
    return '${artist ?? ''}${title ?? ''}${duration?.inMilliseconds ?? ''}${creationDateTime?.podcastTimeStamp ?? ''})$now'
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }
}
