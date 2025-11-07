import 'dart:typed_data';

import 'package:podcast_search/podcast_search.dart';

import 'unique_media.dart';

class EpisodeMedia extends UniqueMedia {
  EpisodeMedia(
    super.resource, {
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
  String? get artUrl => episode.imageUrl ?? _albumArtUrl;

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
  String get id => episode.contentUrl ?? episode.guid;

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
}
