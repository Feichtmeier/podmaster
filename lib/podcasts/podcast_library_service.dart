import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:podcast_search/podcast_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../extensions/date_time_x.dart';
import '../extensions/podcast_item_x.dart';
import '../extensions/shared_preferences_x.dart';

class PodcastLibraryService {
  PodcastLibraryService({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;
  int? get podcastUpdatesLength => _podcastUpdates?.length;

  final SharedPreferences _sharedPreferences;

  // This stream is currently used for notifying whoever is listening to changes
  //
  final _propertiesChangedController = StreamController<bool>.broadcast();
  Stream<bool> get propertiesChanged => _propertiesChangedController.stream;
  Future<void> notify(bool value) async =>
      _propertiesChangedController.add(value);

  ///
  /// Podcasts
  ///

  Set<String> get _subscribedPodcastFeeds =>
      _sharedPreferences.getStringList(SPKeys.podcastFeedUrls)?.toSet() ?? {};

  List<Item> getFilteredPodcastsItems(String? filterText) => podcasts
      .map((feedUrl) => getPodcastItem(feedUrl))
      .whereType<Item>()
      .where((item) {
        if (filterText == null || filterText.isEmpty) return true;

        final term = filterText.toLowerCase();
        final name = item.collectionName?.toLowerCase() ?? '';
        final artist = item.artistName?.toLowerCase() ?? '';

        return name.contains(term) || artist.contains(term);
      })
      .toList();

  bool isPodcastSubscribed(String? feedUrl) =>
      feedUrl != null && _subscribedPodcastFeeds.contains(feedUrl);
  List<String> get podcastFeedUrls => _subscribedPodcastFeeds.toList();
  Set<String> get podcasts => _subscribedPodcastFeeds;
  int get podcastsLength => _subscribedPodcastFeeds.length;

  // Adding and removing Podcasts
  // ------------------

  Future<void> addSubscribedPodcasts(List<Item> items) async {
    if (items.isEmpty) return;
    final newList = List<String>.from(_subscribedPodcastFeeds);
    for (var item in items) {
      if (item.feedUrl != null && !newList.contains(item.feedUrl)) {
        await addPodcastData(item);
        newList.add(item.feedUrl!);
      }
    }
    await _sharedPreferences.setStringList(SPKeys.podcastFeedUrls, newList);
  }

  Future<void> removeSubscribedPodcast(
    String feedUrl, {
    bool update = true,
  }) async {
    if (!isPodcastSubscribed(feedUrl)) return;
    final newList = List<String>.from(_subscribedPodcastFeeds)..remove(feedUrl);
    await _removeFeedWithDownload(feedUrl);
    await removeSubscribedPodcastData(feedUrl);
    _removePodcastLastUpdated(feedUrl);

    if (update) {
      await _sharedPreferences.setStringList(SPKeys.podcastFeedUrls, newList);
    }
  }

  // Podcast Metadata
  // ------------------

  Future<bool> addPodcastData(Item item) {
    if (item.feedUrl == null) return Future.value(false);
    final jsonString = jsonEncode(item.toJson());
    return _sharedPreferences.setString(
      item.feedUrl! + SPKeys.podcastDataSuffix,
      jsonString,
    );
  }

  Item? getPodcastItem(String feedUrl) {
    var string = _sharedPreferences.getString(
      feedUrl + SPKeys.podcastDataSuffix,
    );
    Map<String, dynamic>? json;
    if (string != null) {
      json = jsonDecode(string);
    }
    return Item.fromJson(json: json);
  }

  Future<void> removeSubscribedPodcastData(String feedUrl) =>
      _sharedPreferences.remove(feedUrl + SPKeys.podcastDataSuffix);

  // Podcast Downloads
  // ------------------

  List<String> get downloadedEpisodeUrls {
    final keys = _sharedPreferences.getKeys().where(
      (key) => key.endsWith(SPKeys.podcastEpisodeDownloadedSuffix),
    );
    return keys
        .map((e) => e.replaceAll(SPKeys.podcastEpisodeDownloadedSuffix, ''))
        .toList();
  }

  String? getDownload(String? url) => url == null
      ? null
      : _sharedPreferences.getString(
          url + SPKeys.podcastEpisodeDownloadedSuffix,
        );

  Set<String> get _feedsWithDownloads =>
      _sharedPreferences.getStringList(SPKeys.podcastsWithDownloads)?.toSet() ??
      {};
  Future<void> addFeedWithDownload(String feedUrl) async {
    if (_feedsWithDownloads.contains(feedUrl)) return;
    final updatedFeeds = Set<String>.from(_feedsWithDownloads)..add(feedUrl);
    await _sharedPreferences
        .setStringList(SPKeys.podcastsWithDownloads, updatedFeeds.toList())
        .then(notify);
  }

  bool feedHasDownloads(String feedUrl) =>
      _feedsWithDownloads.contains(feedUrl);
  int get feedsWithDownloadsLength => _feedsWithDownloads.length;
  List<String> get feedsWithDownloads => _feedsWithDownloads.toList();

  Future<void> addDownload({
    required String episodeUrl,
    required String path,
    required String feedUrl,
  }) async {
    if (getDownload(episodeUrl) != null && feedHasDownloads(feedUrl)) {
      return;
    }
    await _sharedPreferences
        .setString(episodeUrl + SPKeys.podcastEpisodeDownloadedSuffix, path)
        .then(notify);
    await addFeedWithDownload(feedUrl);
  }

  Future<void> removeDownload({
    required String episodeUrl,
    required String feedUrl,
  }) async {
    if (getDownload(episodeUrl) == null) return;
    _deleteDownload(episodeUrl);
    await _sharedPreferences
        .remove(episodeUrl + SPKeys.podcastEpisodeDownloadedSuffix)
        .then(notify);
    // Check if there are any downloads left for this feed
    final hasMoreDownloads = _sharedPreferences.getKeys().any(
      (key) =>
          key.endsWith(SPKeys.podcastEpisodeDownloadedSuffix) &&
          key.startsWith(feedUrl),
    );
    if (!hasMoreDownloads) {
      await _removeFeedWithDownload(feedUrl);
    }
  }

  void _deleteDownload(String url) {
    final path = getDownload(url);

    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  Future<void> removeAllDownloads() async {
    final keys = _sharedPreferences.getKeys().where(
      (key) => key.endsWith(SPKeys.podcastEpisodeDownloadedSuffix),
    );
    for (final key in keys) {
      _deleteDownload(key);
      await _sharedPreferences.remove(key);
    }
    await _sharedPreferences.remove(SPKeys.podcastsWithDownloads).then(notify);
  }

  Future<void> _removeFeedWithDownload(String feedUrl) async {
    if (!_feedsWithDownloads.contains(feedUrl)) return;
    final updatedFeeds = Set<String>.from(_feedsWithDownloads)..remove(feedUrl);
    await _sharedPreferences
        .setStringList(SPKeys.podcastsWithDownloads, updatedFeeds.toList())
        .then(notify);
  }

  // Podcast Updates
  // ------------------
  Set<String>? get _podcastUpdates =>
      _sharedPreferences.getStringList(SPKeys.podcastsWithUpdates)?.toSet();

  Future<void> addPodcastLastUpdated({
    required String feedUrl,
    required String timestamp,
  }) async => _sharedPreferences
      .setString(feedUrl + SPKeys.podcastLastUpdatedSuffix, timestamp)
      .then(notify);

  void _removePodcastLastUpdated(String feedUrl) =>
      _sharedPreferences.remove(feedUrl + SPKeys.podcastLastUpdatedSuffix);

  String? getPodcastLastUpdated(String feedUrl) =>
      _sharedPreferences.getString(feedUrl + SPKeys.podcastLastUpdatedSuffix);

  bool podcastUpdateAvailable(String feedUrl) =>
      _podcastUpdates?.contains(feedUrl) == true;

  Future<void> addPodcastUpdate(String feedUrl, DateTime lastUpdated) async {
    if (_podcastUpdates?.contains(feedUrl) == true) return;

    final updatedFeeds = Set<String>.from(_podcastUpdates ?? {})..add(feedUrl);
    await _sharedPreferences
        .setStringList(SPKeys.podcastsWithUpdates, updatedFeeds.toList())
        .then(
          (v) => addPodcastLastUpdated(
            feedUrl: feedUrl,
            timestamp: lastUpdated.podcastTimeStamp,
          ),
        );
  }

  Future<void> removePodcastUpdate(String feedUrl) async {
    if (_podcastUpdates?.contains(feedUrl) != true) return;

    final updatedFeeds = Set<String>.from(_podcastUpdates!)..remove(feedUrl);
    await _sharedPreferences
        .setStringList(SPKeys.podcastsWithUpdates, updatedFeeds.toList())
        .then(notify);
  }

  // Podcast Episode Ordering
  // ------------------
  bool showPodcastAscending(String feedUrl) =>
      _sharedPreferences.getBool(SPKeys.ascendingFeeds + feedUrl) ?? false;

  Future<void> _addAscendingPodcast(String feedUrl) async {
    await _sharedPreferences
        .setBool(SPKeys.ascendingFeeds + feedUrl, true)
        .then(notify);
  }

  Future<void> _removeAscendingPodcast(String feedUrl) async =>
      _sharedPreferences.remove(SPKeys.ascendingFeeds + feedUrl).then(notify);

  Future<void> reorderPodcast({
    required String feedUrl,
    required bool ascending,
  }) async {
    if (ascending) {
      await _addAscendingPodcast(feedUrl);
    } else {
      await _removeAscendingPodcast(feedUrl);
    }
  }
}
