import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../extensions/date_time_x.dart';
import '../extensions/shared_preferences_x.dart';
import 'data/podcast_metadata.dart';

class PodcastLibraryService {
  PodcastLibraryService({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;
  int? get podcastUpdatesLength => _podcastUpdates?.length;

  final SharedPreferences _sharedPreferences;

  // This stream is currently used for downloads
  // TODO: replace with download commmand in DownloadManager
  final _propertiesChangedController = StreamController<bool>.broadcast();
  Stream<bool> get propertiesChanged => _propertiesChangedController.stream;
  Future<void> notify(bool value) async =>
      _propertiesChangedController.add(value);

  ///
  /// Podcasts
  ///

  Set<String> get _podcasts =>
      _sharedPreferences.getStringList(SPKeys.podcastFeedUrls)?.toSet() ?? {};

  Set<String> _getFilteredPodcasts(String? filterText) {
    return podcasts.where((feedUrl) {
      if (filterText == null || filterText.isEmpty) return true;
      final name = getSubscribedPodcastName(feedUrl);
      final artist = getSubscribedPodcastArtist(feedUrl);
      return (name != null &&
              name.toLowerCase().contains(filterText.toLowerCase())) ||
          (artist != null &&
              artist.toLowerCase().contains(filterText.toLowerCase()));
    }).toSet();
  }

  List<PodcastMetadata> getFilteredPodcastsWithMetadata(String? filterText) {
    final filteredFeedUrls = _getFilteredPodcasts(filterText);
    final result = <PodcastMetadata>[];
    for (final feedUrl in filteredFeedUrls) {
      final metadata = getPodcastMetadata(feedUrl);
      result.add(metadata);
    }
    return result;
  }

  bool isPodcastSubscribed(String feedUrl) => _podcasts.contains(feedUrl);
  List<String> get podcastFeedUrls => _podcasts.toList();
  Set<String> get podcasts => _podcasts;
  int get podcastsLength => _podcasts.length;

  // Adding and removing Podcasts
  // ------------------

  Future<void> addPodcast(PodcastMetadata metadata) async {
    if (isPodcastSubscribed(metadata.feedUrl)) return;
    await _addPodcastMetadata(metadata);
    await _sharedPreferences.setStringList(SPKeys.podcastFeedUrls, [
      ...List<String>.from(_podcasts),
      metadata.feedUrl,
    ]);
  }

  Future<void> addPodcasts(List<PodcastMetadata> metadata) async {
    if (metadata.isEmpty) return;
    final newList = List<String>.from(_podcasts);
    for (var p in metadata) {
      if (!newList.contains(p.feedUrl)) {
        await _addPodcastMetadata(p);
        newList.add(p.feedUrl);
      }
    }
    await _sharedPreferences.setStringList(SPKeys.podcastFeedUrls, newList);
  }

  Future<void> removePodcast(String feedUrl, {bool update = true}) async {
    if (!isPodcastSubscribed(feedUrl)) return;
    final newList = List<String>.from(_podcasts)..remove(feedUrl);
    await _removeFeedWithDownload(feedUrl);
    removeSubscribedPodcastImage(feedUrl);
    removeSubscribedPodcastName(feedUrl);
    removeSubscribedPodcastArtist(feedUrl);
    _removePodcastLastUpdated(feedUrl);

    if (update) {
      await _sharedPreferences.setStringList(SPKeys.podcastFeedUrls, newList);
    }
  }

  // Podcast Metadata
  // ------------------
  Future<void> _addPodcastMetadata(PodcastMetadata metadata) async {
    if (metadata.imageUrl != null) {
      addSubscribedPodcastImage(
        feedUrl: metadata.feedUrl,
        imageUrl: metadata.imageUrl!,
      );
    }
    if (metadata.name != null) {
      addSubscribedPodcastName(feedUrl: metadata.feedUrl, name: metadata.name!);
    }
    if (metadata.artist != null) {
      addSubscribedPodcastArtist(
        feedUrl: metadata.feedUrl,
        artist: metadata.artist!,
      );
    }
    if (metadata.genreList != null) {
      addSubscribedPodcastGenreList(
        feedUrl: metadata.feedUrl,
        genreList: metadata.genreList!,
      );
    }
    await addPodcastLastUpdated(
      feedUrl: metadata.feedUrl,
      timestamp: DateTime.now().podcastTimeStamp,
    );
  }

  PodcastMetadata getPodcastMetadata(String feedUrl) => PodcastMetadata(
    feedUrl: feedUrl,
    imageUrl: getSubscribedPodcastImage(feedUrl),
    name: getSubscribedPodcastName(feedUrl),
    artist: getSubscribedPodcastArtist(feedUrl),
    genreList: getSubScribedPodcastGenreList(feedUrl),
  );

  // Image URL
  String? getSubscribedPodcastImage(String feedUrl) =>
      _sharedPreferences.getString(feedUrl + SPKeys.podcastImageUrlSuffix);
  void addSubscribedPodcastImage({
    required String feedUrl,
    required String imageUrl,
  }) => _sharedPreferences.setString(
    feedUrl + SPKeys.podcastImageUrlSuffix,
    imageUrl,
  );
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
  }) => _sharedPreferences.setString(
    feedUrl + SPKeys.podcastArtistSuffix,
    artist,
  );
  void removeSubscribedPodcastArtist(String feedUrl) =>
      _sharedPreferences.remove(feedUrl + SPKeys.podcastArtistSuffix);

  // Genre List
  List<String>? getSubScribedPodcastGenreList(String feedUrl) =>
      _sharedPreferences.getStringList(feedUrl + SPKeys.podcastGenreListSuffix);
  void addSubscribedPodcastGenreList({
    required String feedUrl,
    required List<String> genreList,
  }) => _sharedPreferences.setStringList(
    feedUrl + SPKeys.podcastGenreListSuffix,
    genreList,
  );
  void removeSubscribedPodcastGenreList(String feedUrl) =>
      _sharedPreferences.remove(feedUrl + SPKeys.podcastGenreListSuffix);

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
  }) async => _sharedPreferences.setString(
    feedUrl + SPKeys.podcastLastUpdatedSuffix,
    timestamp,
  );

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
