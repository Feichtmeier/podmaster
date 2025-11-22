import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../extensions/date_time_x.dart';
import '../extensions/shared_preferences_x.dart';

class PodcastLibraryService {
  PodcastLibraryService({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;
  int? get podcastUpdatesLength => _podcastUpdates?.length;

  final SharedPreferences _sharedPreferences;
  final _propertiesChangedController = StreamController<bool>.broadcast();
  Stream<bool> get propertiesChanged => _propertiesChangedController.stream;
  Future<void> notify(bool value) async =>
      _propertiesChangedController.add(value);

  ///
  /// Podcasts
  ///

  Set<String> get _podcasts =>
      _sharedPreferences.getStringList(SPKeys.podcastFeedUrls)?.toSet() ?? {};
  bool isPodcastSubscribed(String feedUrl) => _podcasts.contains(feedUrl);
  List<String> get podcastFeedUrls => _podcasts.toList();
  Set<String> get podcasts => _podcasts;
  int get podcastsLength => _podcasts.length;

  // Adding and removing Podcasts
  // ------------------
  Future<void> addPodcasts(
    List<
      ({
        String feedUrl,
        String? imageUrl,
        String name,
        String artist,
        List<String> genreList,
      })
    >
    podcasts,
  ) async {
    if (podcasts.isEmpty) return;
    final newList = List<String>.from(_podcasts);
    for (var p in podcasts) {
      if (!newList.contains(p.feedUrl)) {
        await _addPodcastMetadata(
          p.imageUrl,
          p.feedUrl,
          p.name,
          p.artist,
          p.genreList,
        );

        newList.add(p.feedUrl);
      }
    }
    await _sharedPreferences
        .setStringList(SPKeys.podcastFeedUrls, newList)
        .then(notify);
  }

  void removePodcast(String feedUrl) {
    if (!isPodcastSubscribed(feedUrl)) return;
    final newList = List<String>.from(_podcasts)..remove(feedUrl);
    _sharedPreferences
        .setStringList(SPKeys.podcastFeedUrls, newList)
        .then(notify);
    _removeFeedWithDownload(feedUrl);
    removeSubscribedPodcastImage(feedUrl);
    removeSubscribedPodcastName(feedUrl);
    removeSubscribedPodcastArtist(feedUrl);
  }

  Future<void> removeAllPodcasts() async {
    for (final feedUrl in _podcasts) {
      removeSubscribedPodcastImage(feedUrl);
      removeSubscribedPodcastName(feedUrl);
      removeSubscribedPodcastArtist(feedUrl);
      _removePodcastLastUpdated(feedUrl);
    }
    _podcasts.clear();
    _podcastUpdates?.clear();
    await _sharedPreferences
        .setStringList(SPKeys.podcastFeedUrls, [])
        .then(notify);
  }

  Future<void> addPodcast({
    required String feedUrl,
    required String? imageUrl,
    required String name,
    required String artist,
    required List<String> genreList,
  }) async {
    if (isPodcastSubscribed(feedUrl)) return;

    await _addPodcastMetadata(imageUrl, feedUrl, name, artist, genreList);

    await _sharedPreferences
        .setStringList(SPKeys.podcastFeedUrls, [
          ...List<String>.from(_podcasts),
          feedUrl,
        ])
        .then(notify);
  }

  // Podcast Metadata
  // ------------------
  Future<void> _addPodcastMetadata(
    String? imageUrl,
    String feedUrl,
    String name,
    String artist,
    List<String> genreList,
  ) async {
    if (imageUrl != null) {
      addSubscribedPodcastImage(feedUrl: feedUrl, imageUrl: imageUrl);
    }
    addSubscribedPodcastName(feedUrl: feedUrl, name: name);
    addSubscribedPodcastArtist(feedUrl: feedUrl, artist: artist);
    addSubscribedPodcastGenreList(feedUrl: feedUrl, genreList: genreList);
    await addPodcastLastUpdated(
      feedUrl: feedUrl,
      timestamp: DateTime.now().podcastTimeStamp,
    );
  }

  // Image URL
  String? getSubscribedPodcastImage(String feedUrl) =>
      _sharedPreferences.getString(feedUrl + SPKeys.podcastImageUrlSuffix);
  void addSubscribedPodcastImage({
    required String feedUrl,
    required String imageUrl,
  }) => _sharedPreferences
      .setString(feedUrl + SPKeys.podcastImageUrlSuffix, imageUrl)
      .then(notify);
  void removeSubscribedPodcastImage(String feedUrl) =>
      _sharedPreferences.remove(feedUrl + SPKeys.podcastImageUrlSuffix);

  // Name
  String? getSubscribedPodcastName(String feedUrl) =>
      _sharedPreferences.getString(feedUrl + SPKeys.podcastNameSuffix);
  void addSubscribedPodcastName({
    required String feedUrl,
    required String name,
  }) => _sharedPreferences.setString(feedUrl + SPKeys.podcastNameSuffix, name);
  void removeSubscribedPodcastName(String feedUrl) =>
      _sharedPreferences.remove(feedUrl + SPKeys.podcastNameSuffix);

  // Artist
  String? getSubscribedPodcastArtist(String feedUrl) =>
      _sharedPreferences.getString(feedUrl + SPKeys.podcastArtistSuffix);
  void addSubscribedPodcastArtist({
    required String feedUrl,
    required String artist,
  }) => _sharedPreferences
      .setString(feedUrl + SPKeys.podcastArtistSuffix, artist)
      .then(notify);
  void removeSubscribedPodcastArtist(String feedUrl) =>
      _sharedPreferences.remove(feedUrl + SPKeys.podcastArtistSuffix);

  // Genre List
  List<String>? getSubScribedPodcastGenreList(String feedUrl) =>
      _sharedPreferences.getStringList(feedUrl + SPKeys.podcastGenreListSuffix);
  void addSubscribedPodcastGenreList({
    required String feedUrl,
    required List<String> genreList,
  }) => _sharedPreferences
      .setStringList(feedUrl + SPKeys.podcastGenreListSuffix, genreList)
      .then(notify);
  void removeSubscribedPodcastGenreList(String feedUrl) =>
      _sharedPreferences.remove(feedUrl + SPKeys.podcastGenreListSuffix);

  // Podcast Downloads
  // ------------------
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

  Future<void> addDownload({
    required String episodeID,
    required String path,
    required String feedUrl,
  }) async {
    if (getDownload(episodeID) != null && feedHasDownloads(feedUrl)) return;
    await _sharedPreferences
        .setString(episodeID + SPKeys.podcastEpisodeDownloadedSuffix, path)
        .then(notify);
    await addFeedWithDownload(feedUrl);
  }

  Future<void> removeDownload({
    required String episodeID,
    required String feedUrl,
  }) async {
    if (getDownload(episodeID) == null) return;
    _deleteDownload(episodeID);
    await _sharedPreferences
        .remove(episodeID + SPKeys.podcastEpisodeDownloadedSuffix)
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
    await _sharedPreferences.remove(SPKeys.podcastsWithDownloads);
    _propertiesChangedController.add(true);
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

  void _removePodcastLastUpdated(String feedUrl) => _sharedPreferences
      .remove(feedUrl + SPKeys.podcastLastUpdatedSuffix)
      .then(notify);

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
          (_) => addPodcastLastUpdated(
            feedUrl: feedUrl,
            timestamp: lastUpdated.podcastTimeStamp,
          ),
        )
        .then((_) => _propertiesChangedController.add(true));
  }

  Future<void> removePodcastUpdate(String feedUrl) async {
    if (_podcastUpdates?.contains(feedUrl) != true) return;

    final updatedFeeds = Set<String>.from(_podcastUpdates!)..remove(feedUrl);
    await _sharedPreferences
        .setStringList(SPKeys.podcastsWithUpdates, updatedFeeds.toList())
        .then((_) => _propertiesChangedController.add(true));
  }

  // Podcast Episode Ordering
  // ------------------
  bool showPodcastAscending(String feedUrl) =>
      _sharedPreferences.getBool(SPKeys.ascendingFeeds + feedUrl) ?? false;

  Future<void> _addAscendingPodcast(String feedUrl) async {
    await _sharedPreferences
        .setBool(SPKeys.ascendingFeeds + feedUrl, true)
        .then((_) => _propertiesChangedController.add(true));
  }

  Future<void> _removeAscendingPodcast(String feedUrl) async =>
      _sharedPreferences
          .remove(SPKeys.ascendingFeeds + feedUrl)
          .then((_) => _propertiesChangedController.add(true));

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
