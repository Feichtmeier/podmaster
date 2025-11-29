import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:podcast_search/podcast_search.dart';

import '../common/logging.dart';
import '../extensions/shared_preferences_x.dart';
import '../settings/settings_service.dart';
import 'data/podcast_genre.dart';
import 'data/simple_language.dart';

class PodcastService {
  final SettingsService _settingsService;
  PodcastService({required SettingsService settingsService})
    : _settingsService = settingsService {
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

  Future<Podcast?> fetchPodcast({Item? item, String? feedUrl}) async {
    if (item == null && item?.feedUrl == null && feedUrl == null) {
      return Future.error(
        ArgumentError('Either item or feedUrl must be provided'),
      );
    }

    final url = feedUrl ?? item!.feedUrl!;

    return compute(loadPodcast, url);
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
