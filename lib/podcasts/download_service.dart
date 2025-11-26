import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../player/data/episode_media.dart';
import '../settings/settings_service.dart';
import 'podcast_library_service.dart';

/// Service for downloading podcast episodes.
///
/// This is a stateless service - download progress and state are managed
/// by episode download commands.
class DownloadService {
  DownloadService({
    required PodcastLibraryService libraryService,
    required Dio dio,
    required SettingsService settingsService,
  }) : _libraryService = libraryService,
       _dio = dio,
       _settingsService = settingsService;

  final PodcastLibraryService _libraryService;
  final SettingsService _settingsService;
  final Dio _dio;

  /// Downloads an episode to the local filesystem.
  ///
  /// Used by episode download commands. Progress updates are sent via the
  /// onProgress callback.
  Future<String?> download({
    required EpisodeMedia episode,
    required CancelToken cancelToken,
    required void Function(int received, int total) onProgress,
  }) async {
    final url = episode.url;
    if (url == null) {
      throw Exception('Invalid media, missing URL to download');
    }

    final downloadsDir = _settingsService.downloadsDir;
    if (downloadsDir == null) {
      throw Exception('Downloads directory not set');
    }

    if (!Directory(downloadsDir).existsSync()) {
      Directory(downloadsDir).createSync(recursive: true);
    }

    final path = p.join(downloadsDir, episode.audioDownloadId);

    final response = await _dio.download(
      url,
      path,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );

    if (response.statusCode == 200) {
      await _libraryService.addDownload(
        episodeUrl: url,
        path: path,
        feedUrl: episode.feedUrl,
      );
      return path;
    }

    return null;
  }

  /// Deletes a downloaded episode from the filesystem and library.
  Future<void> deleteDownload({required EpisodeMedia? media}) async {
    if (media?.url != null && media?.feedUrl != null) {
      await _libraryService.removeDownload(
        episodeUrl: media!.url!,
        feedUrl: media.feedUrl,
      );
    }
  }

  /// Deletes all downloaded episodes.
  Future<void> deleteAllDownloads() async =>
      _libraryService.removeAllDownloads();
}
