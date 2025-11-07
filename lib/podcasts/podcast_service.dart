import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:podcast_search/podcast_search.dart';

import '../common/logging.dart';
import '../extensions/date_time_x.dart';
import '../extensions/shared_preferences_x.dart';
import '../extensions/string_x.dart';
import '../notifications/notifications_service.dart';
import '../player/data/episode_media.dart';
import '../settings/settings_service.dart';
import 'data/podcast_genre.dart';
import 'data/simple_language.dart';
import 'podcast_library_service.dart';

class PodcastService {
  final NotificationsService _notificationsService;
  final SettingsService _settingsService;
  final PodcastLibraryService _libraryService;
  PodcastService({
    required NotificationsService notificationsService,
    required SettingsService settingsService,
    required PodcastLibraryService libraryService,
  }) : _notificationsService = notificationsService,
       _settingsService = settingsService,
       _libraryService = libraryService {
    _search = Search(
      searchProvider:
          _settingsService.getBool(SPKeys.usePodcastIndex) == true &&
              _settingsService.getString(SPKeys.podcastIndexApiKey) != null &&
              _settingsService.getString(SPKeys.podcastIndexApiSecret) != null
          ? PodcastIndexProvider(
              key: _settingsService.getString(SPKeys.podcastIndexApiKey)!,
              secret: _settingsService.getString(SPKeys.podcastIndexApiSecret)!,
            )
          : const ITunesProvider(),
    );
  }

  late Search _search;

  Future<SearchResult> search({
    String? searchQuery,
    PodcastGenre podcastGenre = PodcastGenre.all,
    Country? country,
    SimpleLanguage? language,
    int limit = 10,
    Attribute attribute = Attribute.none,
  }) async {
    try {
      if (searchQuery == null || searchQuery.isEmpty == true) {
        return await _search.charts(
          genre: podcastGenre == PodcastGenre.all ? '' : podcastGenre.id,
          limit: limit,
          country: country ?? Country.germany,
          language: country != null || language?.isoCode == null
              ? ''
              : language!.isoCode,
        );
      } else {
        var res = await _search.search(
          searchQuery,
          country: country ?? Country.germany,
          language: country != null || language?.isoCode == null
              ? ''
              : language!.isoCode,
          limit: limit,
          attribute: attribute,
        );

        if (res.successful == false) {
          throw Exception(
            'Search failed: ${res.lastError} ${res.lastErrorType.name}',
          );
        }
        return res;
      }
    } catch (e) {
      rethrow;
    }
  }

  bool _updateLock = false;

  Future<void> checkForUpdates({
    Set<String>? feedUrls,
    required String updateMessage,
    required String Function(int length) multiUpdateMessage,
  }) async {
    if (_updateLock) return;
    _updateLock = true;

    final newUpdateFeedUrls = <String>{};

    for (final feedUrl in (feedUrls ?? _libraryService.podcasts)) {
      final storedTimeStamp = _libraryService.getPodcastLastUpdated(feedUrl);
      DateTime? feedLastUpdated;
      try {
        feedLastUpdated = await Feed.feedLastUpdated(url: feedUrl);
      } on Exception catch (e) {
        printMessageInDebugMode(e);
      }
      final name = _libraryService.getSubscribedPodcastName(feedUrl);

      printMessageInDebugMode('checking update for: ${name ?? feedUrl} ');
      printMessageInDebugMode(
        'storedTimeStamp: ${storedTimeStamp ?? 'no timestamp'}',
      );
      printMessageInDebugMode(
        'feedLastUpdated: ${feedLastUpdated?.podcastTimeStamp ?? 'no timestamp'}',
      );

      if (feedLastUpdated == null) continue;

      await _libraryService.addPodcastLastUpdated(
        feedUrl: feedUrl,
        timestamp: feedLastUpdated.podcastTimeStamp,
      );

      if (storedTimeStamp != null &&
          !storedTimeStamp.isSamePodcastTimeStamp(feedLastUpdated)) {
        await findEpisodes(feedUrl: feedUrl, loadFromCache: false);
        await _libraryService.addPodcastUpdate(feedUrl, feedLastUpdated);

        newUpdateFeedUrls.add(feedUrl);
      }
    }

    if (newUpdateFeedUrls.isNotEmpty) {
      final msg = newUpdateFeedUrls.length == 1
          ? '$updateMessage${_episodeCache[newUpdateFeedUrls.first]?.firstOrNull?.collectionName != null ? ' ${_episodeCache[newUpdateFeedUrls.first]?.firstOrNull?.collectionName}' : ''}'
          : multiUpdateMessage(newUpdateFeedUrls.length);
      await _notificationsService.notify(message: msg);
    }

    _updateLock = false;
  }

  List<EpisodeMedia>? getPodcastEpisodesFromCache(String? feedUrl) =>
      _episodeCache[feedUrl];
  final Map<String, List<EpisodeMedia>> _episodeCache = {};

  Future<List<EpisodeMedia>> findEpisodes({
    Item? item,
    String? feedUrl,
    bool loadFromCache = true,
  }) async {
    if (item == null && item?.feedUrl == null && feedUrl == null) {
      printMessageInDebugMode('findEpisodes called without feedUrl or item');
      return Future.value([]);
    }

    final url = feedUrl ?? item!.feedUrl!;

    if (_episodeCache.containsKey(url) && loadFromCache) {
      if (_episodeCache[url]?.firstOrNull?.artUrl != null) {
        _libraryService.addSubscribedPodcastImage(
          feedUrl: url,
          imageUrl: _episodeCache[url]!.firstOrNull!.artUrl!,
        );
      }
      return _episodeCache[url]!;
    }

    final Podcast? podcast = await compute(loadPodcast, url);
    if (podcast?.image != null) {
      _libraryService.addSubscribedPodcastImage(
        feedUrl: url,
        imageUrl: podcast!.image!,
      );
    }
    final episodes =
        podcast?.episodes
            .where((e) => e.contentUrl != null)
            .map(
              (e) => EpisodeMedia(
                e.contentUrl!,
                episode: e,
                feedUrl: url,
                albumArtUrl: item?.artworkUrl600 ?? item?.artworkUrl,
                collectionName: item?.collectionName,
                artist: item?.artistName,
                genres: [
                  if (item?.primaryGenreName != null) item!.primaryGenreName!,
                ],
              ),
            )
            .toList() ??
        <EpisodeMedia>[];

    _episodeCache[url] = episodes;

    return episodes;
  }
}

Future<Podcast?> loadPodcast(String url) async {
  try {
    return await Feed.loadFeed(url: url);
  } catch (e) {
    printMessageInDebugMode(e);
    return null;
  }
}
