import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:podcast_search/podcast_search.dart';

import '../common/logging.dart';
import '../extensions/podcast_x.dart';
import '../extensions/shared_preferences_x.dart';
import '../player/data/episode_media.dart';
import '../settings/settings_service.dart';
import 'data/podcast_genre.dart';
import 'data/simple_language.dart';
import 'podcast_library_service.dart';

class PodcastService {
  final SettingsService _settingsService;
  final PodcastLibraryService _libraryService;
  PodcastService({
    required SettingsService settingsService,
    required PodcastLibraryService libraryService,
  }) : _settingsService = settingsService,
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
    SearchResult res;
    try {
      if (searchQuery == null || searchQuery.isEmpty) {
        res = await _search.charts(
          genre: podcastGenre == PodcastGenre.all ? '' : podcastGenre.id,
          limit: limit,
          country: country ?? Country.none,
          language: country != null || language?.isoCode == null
              ? ''
              : language!.isoCode,
        );
      } else {
        res = await _search.search(
          searchQuery,
          country: country ?? Country.none,
          language: country != null || language?.isoCode == null
              ? ''
              : language!.isoCode,
          limit: limit,
          attribute: attribute,
        );
      }
      if (!res.successful) {
        throw Exception(
          'Search failed: ${res.lastError} ${res.lastErrorType.name}',
        );
      }
      return res;
    } catch (e) {
      rethrow;
    }
  }

  // Stateless operation - just fetches podcast and episodes, no caching
  Future<({Podcast? podcast, List<EpisodeMedia> episodes})> findEpisodes({
    Item? item,
    String? feedUrl,
  }) async {
    if (item == null && item?.feedUrl == null && feedUrl == null) {
      printMessageInDebugMode('findEpisodes called without feedUrl or item');
      return (podcast: null, episodes: <EpisodeMedia>[]);
    }

    final url = feedUrl ?? item!.feedUrl!;

    // Save artwork if available
    if (item?.bestArtworkUrl != null) {
      _libraryService.addSubscribedPodcastImage(
        feedUrl: url,
        imageUrl: item!.bestArtworkUrl!,
      );
    }

    Podcast? podcast;
    try {
      podcast = await compute(loadPodcast, url);
    } catch (e) {
      printMessageInDebugMode('Error loading podcast feed: $e');
      return (podcast: null, episodes: <EpisodeMedia>[]);
    }

    if (podcast?.image != null) {
      _libraryService.addSubscribedPodcastImage(
        feedUrl: url,
        imageUrl: podcast!.image!,
      );
    }

    final episodes = podcast?.toEpisodeMediaList(url, item) ?? <EpisodeMedia>[];

    return (podcast: podcast, episodes: episodes);
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
