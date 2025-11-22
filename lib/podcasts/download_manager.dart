import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../extensions/date_time_x.dart';
import '../player/data/episode_media.dart';
import '../settings/settings_service.dart';
import 'podcast_library_service.dart';

class DownloadManager extends ChangeNotifier {
  DownloadManager({
    required PodcastLibraryService libraryService,
    required SettingsService settingsService,
    required Dio dio,
  }) : _libraryService = libraryService,
       _settingsService = settingsService,
       _dio = dio;

  final PodcastLibraryService _libraryService;
  final SettingsService _settingsService;
  final Dio _dio;

  final _values = <String, double?>{};
  final _cancelTokens = <String, CancelToken?>{};
  final _messageStreamController = StreamController<String>.broadcast();
  String _lastMessage = '';
  void _addMessage(String message) {
    if (message == _lastMessage) return;
    _lastMessage = message;
    _messageStreamController.add(message);
  }

  Stream<String> get messageStream => _messageStreamController.stream;

  double? getValue(String? url) => _values[url];
  void setValue({
    required int received,
    required int total,
    required String url,
  }) {
    if (total <= 0) return;
    final v = received / total;
    _values.containsKey(url)
        ? _values.update(url, (value) => v)
        : _values.putIfAbsent(url, () => v);

    notifyListeners();
  }

  Future<void> deleteDownload({required EpisodeMedia? media}) async {
    if (media?.url != null &&
        _settingsService.downloadsDir != null &&
        media?.feedUrl != null) {
      await _libraryService.removeDownload(
        episodeID: media!.url!,
        feedUrl: media.feedUrl,
      );
      if (_values.containsKey(media.url)) {
        _values.update(media.url!, (value) => null);
      }

      notifyListeners();
    }
  }

  Future<void> deleteAllDownloads() async {
    if (_settingsService.downloadsDir != null) {
      await _libraryService.removeAllDownloads();
      _values.clear();

      notifyListeners();
    }
  }

  Future<void> startDownload({
    required EpisodeMedia? media,
    required String canceledMessage,
    required String finishedMessage,
  }) async {
    final downloadsDir = _settingsService.downloadsDir;
    if (media?.url == null || downloadsDir == null) return;
    final url = media!.url!;

    if (_cancelTokens[url] != null) {
      _cancelTokens[url]?.cancel();
      _values.containsKey(url)
          ? _values.update(url, (value) => null)
          : _values.putIfAbsent(url, () => null);
      _cancelTokens.update(url, (value) => null);
      notifyListeners();
      return;
    }

    _dio.interceptors.add(LogInterceptor());
    _dio.options.headers = {HttpHeaders.acceptEncodingHeader: '*'};

    if (!Directory(downloadsDir).existsSync()) {
      Directory(downloadsDir).createSync();
    }

    final path = p.join(downloadsDir, _createAudioDownloadId(media));
    await _download(
      canceledMessage: canceledMessage,
      url: url,
      path: path,
      name: media.title ?? '',
    ).then((response) async {
      if (response?.statusCode == 200) {
        await _libraryService.addDownload(
          episodeID: url,
          path: path,
          feedUrl: media.feedUrl,
        );
        _addMessage(finishedMessage);

        _cancelTokens.containsKey(url)
            ? _cancelTokens.update(url, (value) => null)
            : _cancelTokens.putIfAbsent(url, () => null);
      }
    });
  }

  String _createAudioDownloadId(EpisodeMedia media) {
    final now = DateTime.now().toUtc().toString();
    return '${media.artist ?? ''}${media.title ?? ''}${media.duration?.inMilliseconds ?? ''}${media.creationDateTime?.podcastTimeStamp ?? ''})$now'
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  Future<Response<dynamic>?> _download({
    required String url,
    required String path,
    required String name,
    required String canceledMessage,
  }) async {
    _cancelTokens.containsKey(url)
        ? _cancelTokens.update(url, (value) => CancelToken())
        : _cancelTokens.putIfAbsent(url, () => CancelToken());
    try {
      return await _dio.download(
        url,
        path,
        onReceiveProgress: (count, total) =>
            setValue(received: count, total: total, url: url),
        cancelToken: _cancelTokens[url],
      );
    } catch (e) {
      _cancelTokens[url]?.cancel();

      String? message;
      if (e.toString().contains('[request cancelled]')) {
        message = canceledMessage;
      }

      _addMessage(message ?? e.toString());
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    await _messageStreamController.close();
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
