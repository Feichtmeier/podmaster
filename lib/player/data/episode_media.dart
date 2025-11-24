import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../extensions/date_time_x.dart';
import '../../podcasts/download_service.dart';
import '../../podcasts/podcast_manager.dart';
import 'unique_media.dart';

class EpisodeMedia extends UniqueMedia {
  // Factory constructor that computes download path only once
  factory EpisodeMedia(
    String resource, {
    Map<String, dynamic>? extras,
    Map<String, String>? httpHeaders,
    Duration? start,
    Duration? end,
    required Episode episode,
    required String feedUrl,
    int? bitRate,
    String? albumArtUrl,
    List<String> genres = const [],
    String? collectionName,
    String? artist,
  }) {
    // Call getDownload only once
    final downloadPath = di<DownloadService>().getDownload(episode.contentUrl);
    final wasDownloaded = downloadPath != null;
    final effectiveResource = downloadPath ?? resource;

    return EpisodeMedia._(
      effectiveResource,
      wasDownloaded: wasDownloaded,
      extras: extras,
      httpHeaders: httpHeaders,
      start: start,
      end: end,
      episode: episode,
      feedUrl: feedUrl,
      bitRate: bitRate,
      albumArtUrl: albumArtUrl,
      genres: genres,
      collectionName: collectionName,
      artist: artist,
    );
  }

  // Private constructor that receives pre-computed values
  EpisodeMedia._(
    String resource, {
    required bool wasDownloaded,
    Map<String, dynamic>? extras,
    Map<String, String>? httpHeaders,
    Duration? start,
    Duration? end,
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
       _artist = artist,
       _wasDownloadedOnCreation = wasDownloaded,
       super(
         resource,
         extras: extras,
         httpHeaders: httpHeaders,
         start: start,
         end: end,
       );

  final bool _wasDownloadedOnCreation;
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

  /// Returns true if this episode has been downloaded (progress is 100%)
  bool get isDownloaded => downloadCommand.progress.value == 1.0;

  // Download command with progress and cancellation support
  late final downloadCommand = (() {
    final command =
        Command.createAsyncNoParamNoResultWithProgress((handle) async {
            // 1. Add to active downloads
            di<PodcastManager>().activeDownloads.add(this);

            // 2. Create CancelToken
            final cancelToken = CancelToken();

            // 3. Listen to cancellation and forward to Dio
            handle.isCanceled.listen((canceled, subscription) {
              if (canceled) {
                cancelToken.cancel();
                subscription.cancel();
              }
            });

            // 4. Download with progress updates
            await di<DownloadService>().download(
              episode: this,
              cancelToken: cancelToken,
              onProgress: (received, total) {
                handle.updateProgress(received / total);
              },
            );

            // 5. Success: remove from active downloads
            di<PodcastManager>().activeDownloads.remove(this);
          }, errorFilter: const LocalAndGlobalErrorFilter())
          ..errors.listen((error, subscription) {
            // 6. Error handler: remove from active downloads
            di<PodcastManager>().activeDownloads.remove(this);
          });

    // Initialize progress to 1.0 if already downloaded
    if (_wasDownloadedOnCreation) {
      command.resetProgress(progress: 1.0);
    }

    return command;
  })();

  // Delete download command
  late final deleteDownloadCommand = Command.createAsyncNoParamNoResult(
    () async {
      // Delete the download
      await di<DownloadService>().deleteDownload(media: this);

      // Reset download progress to 0.0
      downloadCommand.resetProgress(progress: 0.0);
    },
    errorFilter: const LocalAndGlobalErrorFilter(),
  );
}
