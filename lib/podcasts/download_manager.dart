import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../player/data/episode_media.dart';
import 'data/download_capsule.dart';
import 'podcast_library_service.dart';

class DownloadManager extends ChangeNotifier {
  DownloadManager({
    required PodcastLibraryService libraryService,
    required Dio dio,
  }) : _libraryService = libraryService,
       _dio = dio {
    _propertiesChangedSubscription = _libraryService.propertiesChanged.listen(
      (_) => notifyListeners(),
    );
  }

  final PodcastLibraryService _libraryService;
  final Dio _dio;
  StreamSubscription<bool>? _propertiesChangedSubscription;

  final _messageStreamController = StreamController<String>.broadcast();
  String _lastMessage = '';
  void _addMessage(String message) {
    if (message == _lastMessage) return;
    _lastMessage = message;
    _messageStreamController.add(message);
  }

  Stream<String> get messageStream => _messageStreamController.stream;

  List<String> get feedsWithDownloads => _libraryService.feedsWithDownloads;
  String? getDownload(String? url) => _libraryService.getDownload(url);
  bool isDownloaded(String? url) => getDownload(url) != null;
  final _episodeToProgress = <EpisodeMedia, double?>{};
  Map<EpisodeMedia, double?> get episodeToProgress => _episodeToProgress;
  bool getDownloadsInProgress() => _episodeToProgress.values.any(
    (progress) => progress != null && progress < 1.0,
  );

  double? getProgress(EpisodeMedia? episode) => _episodeToProgress[episode];
  void setProgress({
    required int received,
    required int total,
    required EpisodeMedia episode,
  }) {
    if (total <= 0) return;
    _episodeToProgress[episode] = received / total;
    notifyListeners();
  }

  final _episodeToCancelToken = <EpisodeMedia, CancelToken?>{};
  bool _canCancelDownload(EpisodeMedia episode) =>
      _episodeToCancelToken[episode] != null;
  Future<String?> startOrCancelDownload(DownloadCapsule capsule) async {
    final url = capsule.media.url;

    if (url == null) {
      throw Exception('Invalid media, missing URL to download');
    }

    if (_canCancelDownload(capsule.media)) {
      await _cancelDownload(capsule.media);
      await deleteDownload(media: capsule.media);
      return null;
    }

    if (!Directory(capsule.downloadsDir).existsSync()) {
      Directory(capsule.downloadsDir).createSync();
    }

    final toDownloadPath = p.join(
      capsule.downloadsDir,
      capsule.media.audioDownloadId,
    );
    final response = await _processDownload(
      canceledMessage: capsule.canceledMessage,
      episode: capsule.media,
      path: toDownloadPath,
    );

    if (response?.statusCode == 200) {
      await _libraryService.addDownload(
        episodeUrl: url,
        path: toDownloadPath,
        feedUrl: capsule.media.feedUrl,
      );
      _episodeToCancelToken.remove(capsule.media);
      _addMessage(capsule.finishedMessage);
      notifyListeners();
    }
    return _libraryService.getDownload(url);
  }

  Future<void> _cancelDownload(EpisodeMedia? episode) async {
    if (episode == null) return;
    _episodeToCancelToken[episode]?.cancel();
    _episodeToProgress.remove(episode);
    _episodeToCancelToken.remove(episode);
    notifyListeners();
  }

  Future<void> cancelAllDownloads() async {
    final episodes = _episodeToCancelToken.keys.toList();
    for (final episode in episodes) {
      _episodeToCancelToken[episode]?.cancel();
      _episodeToProgress.remove(episode);
      _episodeToCancelToken.remove(episode);
    }
    notifyListeners();
  }

  Future<Response<dynamic>?> _processDownload({
    required EpisodeMedia episode,
    required String path,
    required String canceledMessage,
  }) async {
    _episodeToCancelToken[episode] = CancelToken();
    try {
      return await _dio.download(
        episode.url!,
        path,
        onReceiveProgress: (count, total) =>
            setProgress(received: count, total: total, episode: episode),
        cancelToken: _episodeToCancelToken[episode],
      );
    } catch (e) {
      _episodeToCancelToken[episode]?.cancel();

      String? message;
      if (e.toString().contains('[request cancelled]')) {
        message = canceledMessage;
      }

      _addMessage(message ?? e.toString());
      return null;
    }
  }

  Future<void> deleteDownload({required EpisodeMedia? media}) async {
    if (media?.url != null && media?.feedUrl != null) {
      await _libraryService.removeDownload(
        episodeUrl: media!.url!,
        feedUrl: media.feedUrl,
      );
      _episodeToProgress.remove(media);
      notifyListeners();
    }
  }

  Future<void> deleteAllDownloads() async {
    if (_episodeToProgress.isNotEmpty) {
      throw Exception(
        'Cannot delete all downloads while downloads are in progress',
      );
    }
    await _libraryService.removeAllDownloads();
    _episodeToProgress.clear();
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await cancelAllDownloads();
    await _messageStreamController.close();
    await _propertiesChangedSubscription?.cancel();
    super.dispose();
  }
}

void downloadMessageStreamHandler(
  BuildContext context,
  AsyncSnapshot<String?> snapshot,
  void Function() cancel,
) {
  if (snapshot.hasData) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(snapshot.data!)));
  }
}
