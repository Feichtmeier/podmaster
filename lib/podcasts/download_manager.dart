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

  final _urlToProgress = <String, double?>{};
  final _urlToCancelToken = <String, CancelToken?>{};
  final _messageStreamController = StreamController<String>.broadcast();
  String _lastMessage = '';
  void _addMessage(String message) {
    if (message == _lastMessage) return;
    _lastMessage = message;
    _messageStreamController.add(message);
  }

  Stream<String> get messageStream => _messageStreamController.stream;

  bool isDownloaded(String? url) => _libraryService.getDownload(url) != null;
  double? getProgress(String? url) => _urlToProgress[url];
  void setProgress({
    required int received,
    required int total,
    required String url,
  }) {
    if (total <= 0) return;
    _urlToProgress[url] = received / total;
    notifyListeners();
  }

  Future<String?> startOrCancelDownload(DownloadCapsule capsule) async {
    final url = capsule.media.url;

    if (url == null) {
      throw Exception('Invalid media, missing URL to download');
    }

    if (_urlToCancelToken[url] != null) {
      _urlToCancelToken[url]?.cancel();
      _urlToProgress[url] = null;
      _urlToCancelToken[url] = null;
      await _libraryService.removeDownload(
        episodeUrl: url,
        feedUrl: capsule.media.feedUrl,
      );
      notifyListeners();
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
      url: url,
      path: toDownloadPath,
    );
    String? downloadedPath;
    if (response?.statusCode == 200) {
      downloadedPath = await _libraryService.addDownload(
        episodeUrl: url,
        path: toDownloadPath,
        feedUrl: capsule.media.feedUrl,
      );
      _addMessage(capsule.finishedMessage);
      _urlToCancelToken[url] = null;
    }
    return downloadedPath;
  }

  Future<Response<dynamic>?> _processDownload({
    required String url,
    required String path,
    required String canceledMessage,
  }) async {
    _urlToCancelToken[url] = CancelToken();
    try {
      return await _dio.download(
        url,
        path,
        onReceiveProgress: (count, total) =>
            setProgress(received: count, total: total, url: url),
        cancelToken: _urlToCancelToken[url],
      );
    } catch (e) {
      _urlToCancelToken[url]?.cancel();

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
      if (_urlToProgress.containsKey(media.url)) {
        _urlToProgress.update(media.url!, (value) => null);
      }

      notifyListeners();
    }
  }

  Future<void> deleteAllDownloads() async {
    if (_urlToProgress.isNotEmpty) {
      throw Exception(
        'Cannot delete all downloads while downloads are in progress',
      );
    }
    await _libraryService.removeAllDownloads();
    _urlToProgress.clear();
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
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
