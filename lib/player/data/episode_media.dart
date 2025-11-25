import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../extensions/date_time_x.dart';
import '../../podcasts/download_service.dart';
import '../../podcasts/podcast_manager.dart';
import 'unique_media.dart';

class EpisodeMedia extends UniqueMedia {
  // Factory constructor that checks for persisted downloads
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
    // Check if episode was previously downloaded (persisted in SharedPreferences)
    final downloadPath = di<DownloadService>().getDownload(episode.contentUrl);

    return EpisodeMedia._(
      resource, // Always use original URL as resource
      downloadPath: downloadPath,
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
    super.resource, {
    String? downloadPath,
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
       _artist = artist,
       _downloadPath = downloadPath;

  /// Path to downloaded file, or null if not downloaded.
  /// Updated by downloadCommand (on success) and deleteDownloadCommand (clears it).
  String? _downloadPath;
  String? get downloadPath => _downloadPath;
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

  /// Returns true if this episode has been downloaded
  bool get isDownloaded => _downloadPath != null;

  // Download command with progress and cancellation support
  late final downloadCommand = (() {
    final command =
        Command.createAsyncNoParamNoResultWithProgress((handle) async {
            // 1. Add to active downloads
            di<PodcastManager>().registerActiveDownload(this);

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
            final path = await di<DownloadService>().download(
              episode: this,
              cancelToken: cancelToken,
              onProgress: (received, total) {
                handle.updateProgress(received / total);
              },
            );

            // 5. Set download path on success
            _downloadPath = path;

            // 6. Keep in active downloads so user can see completed downloads
            // (will be removed when user deletes or starts new session)
          }, errorFilter: const LocalAndGlobalErrorFilter())
          ..errors.listen((error, subscription) {
            // Error handler: remove from active downloads
            di<PodcastManager>().unregisterActiveDownload(this);
          });

    // Initialize progress to 1.0 if already downloaded
    if (_downloadPath != null) {
      command.resetProgress(progress: 1.0);
    }

    return command;
  })();

  // Delete download command with optimistic update for progress UI
  late final deleteDownloadCommand =
      Command.createAsyncNoParamNoResult(() async {
          // Optimistic: reset progress immediately for instant UI feedback
          downloadCommand.resetProgress(progress: 0.0);

          // Delete async
          await di<DownloadService>().deleteDownload(media: this);

          // Clear downloadPath only after successful delete
          _downloadPath = null;
        }, errorFilter: const LocalAndGlobalErrorFilter())
        ..errors.listen((error, _) {
          // Rollback progress on error
          if (error != null) {
            downloadCommand.resetProgress(progress: 1.0);
          }
        });
}
