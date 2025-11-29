import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../collection/collection_manager.dart';
import '../common/logging.dart';
import '../extensions/country_x.dart';
import '../extensions/date_time_x.dart';
import '../extensions/podcast_x.dart';
import '../extensions/string_x.dart';
import '../notifications/notifications_service.dart';
import '../player/data/episode_media.dart';
import '../player/player_manager.dart';
import '../search/search_manager.dart';
import 'data/podcast_metadata.dart';
import 'download_service.dart';
import 'podcast_library_service.dart';
import 'podcast_service.dart';

/// Manages podcast search and episode fetching.
///
/// Note: This manager is registered as a singleton in get_it and lives for the
/// entire app lifetime. Commands and subscriptions don't need explicit disposal
/// as they're automatically cleaned up when the app process terminates.
class PodcastManager {
  PodcastManager({
    required PodcastService podcastService,
    required DownloadService downloadService,
    required SearchManager searchManager,
    required CollectionManager collectionManager,
    required PodcastLibraryService podcastLibraryService,
    required NotificationsService notificationsService,
    required PlayerManager playerManager,
  }) : _podcastService = podcastService,
       _downloadService = downloadService,
       _podcastLibraryService = podcastLibraryService,
       _notificationsService = notificationsService,
       _playerManager = playerManager {
    Command.globalExceptionHandler = (e, s) {
      printMessageInDebugMode(e.error, s);
    };
    updateSearchCommand = Command.createAsync<String?, SearchResult>(
      (String? query) async => _podcastService.search(
        searchQuery: query,
        limit: 20,
        country: CountryX.platformDefault,
      ),
      initialValue: SearchResult(items: []),
    );

    // Subscription doesn't need disposal - manager lives for app lifetime
    searchManager.textChangedCommand
        .debounce(const Duration(milliseconds: 500))
        .listen((filterText, sub) => updateSearchCommand.run(filterText));

    getSubscribedPodcastsCommand = Command.createSync((filterText) {
      final items = podcastLibraryService.getFilteredPodcastsItems(filterText);

      return items
          .map(
            (e) => Item(
              feedUrl: e.feedUrl,
              artworkUrl: podcastLibraryService.getSubscribedPodcastImage(
                e.feedUrl,
              ),
              collectionName: e.name,
              artistName: e.artist,
            ),
          )
          .toList();
    }, initialValue: []);

    collectionManager.textChangedCommand.listen(
      (filterText, sub) => getSubscribedPodcastsCommand.run(filterText),
    );

    getSubscribedPodcastsCommand.run(null);

    updateSearchCommand.run(null);
  }

  final PodcastService _podcastService;
  final PodcastLibraryService _podcastLibraryService;
  final DownloadService _downloadService;
  final NotificationsService _notificationsService;
  final PlayerManager _playerManager;

  final showInfo = ValueNotifier(false);

  // Map of feedUrl to fetch episodes command
  final _fetchEpisodeMediaCommands =
      <String, Command<String, List<EpisodeMedia>>>{};

  Command<String, List<EpisodeMedia>> _getFetchEpisodesCommand(String feedUrl) {
    return _fetchEpisodeMediaCommands.putIfAbsent(
      feedUrl,
      () => Command.createAsync<String, List<EpisodeMedia>>(
        (feedUrl) async => findEpisodes(feedUrl: feedUrl),
        initialValue: [],
      ),
    );
  }

  Command<String, List<EpisodeMedia>> runFetchEpisodesCommand(String feedUrl) {
    _getFetchEpisodesCommand(feedUrl).run(feedUrl);
    return _getFetchEpisodesCommand(feedUrl);
  }

  final Map<String, Command<int, void>> _fetchAndPlayCommands = {};
  Command<int, void> getOrCreatePlayCommand(String feedUrl) =>
      _fetchAndPlayCommands.putIfAbsent(
        feedUrl,
        () => _createFetchEpisodesAndPlayCommand(feedUrl),
      );

  Command<int, void> _createFetchEpisodesAndPlayCommand(String feedUrl) =>
      Command.createAsyncNoResult<int>((startIndex) async {
        final episodes = await _getFetchEpisodesCommand(
          feedUrl,
        ).runAsync(feedUrl);

        if (episodes.isNotEmpty) {
          await _playerManager.setPlaylist(episodes, index: startIndex);
        }
      });

  late Command<String?, SearchResult> updateSearchCommand;
  late Command<String?, List<Item>> getSubscribedPodcastsCommand;
  late Command<GetMetadataCapsule, PodcastMetadata?> getPodcastMetadataCommand;

  final _metaDataCommands =
      <GetMetadataCapsule, Command<GetMetadataCapsule, PodcastMetadata?>>{};
  Command<GetMetadataCapsule, PodcastMetadata?> getAndRunMetadataCommand(
    GetMetadataCapsule capsule,
  ) {
    return _metaDataCommands.putIfAbsent(
      capsule,
      () => _createGetPodcastMetadataCommand(),
    )..run(capsule);
  }

  Command<GetMetadataCapsule, PodcastMetadata?>
  _createGetPodcastMetadataCommand() =>
      Command.createAsync<GetMetadataCapsule, PodcastMetadata?>((
        capsule,
      ) async {
        if (capsule.item != null) {
          return PodcastMetadata.fromItem(capsule.item!);
        } else if (_podcastLibraryService.isPodcastSubscribed(
          capsule.feedUrl,
        )) {
          return _podcastLibraryService.getSubScribedPodcastMetadata(
            capsule.feedUrl,
          );
        } else {
          throw ArgumentError(
            'Cannot get metadata for unsubscribed podcast without item',
          );
        }
      }, initialValue: null);

  final _downloadCommands = <EpisodeMedia, Command<void, void>>{};
  final activeDownloads = ListNotifier<EpisodeMedia>();
  final recentDownloads = ListNotifier<EpisodeMedia>();

  Command<void, void> getDownloadCommand(EpisodeMedia media) =>
      _downloadCommands.putIfAbsent(media, () => _createDownloadCommand(media));

  Command<void, void> _createDownloadCommand(EpisodeMedia media) {
    final command = Command.createAsyncNoParamNoResultWithProgress((
      handle,
    ) async {
      activeDownloads.add(media);

      final cancelToken = CancelToken();

      handle.isCanceled.listen((canceled, subscription) {
        if (canceled) {
          activeDownloads.remove(media);
          cancelToken.cancel();
          subscription.cancel();
        }
      });

      await _downloadService.download(
        episode: media,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          handle.updateProgress(received / total);
        },
      );

      activeDownloads.remove(media);
      recentDownloads.add(media);
    });

    if (_podcastLibraryService.getDownload(media.url) != null) {
      command.resetProgress(progress: 1.0);
    }

    return command;
  }

  Future<void> addPodcast(PodcastMetadata metadata) async {
    await _podcastLibraryService.addPodcast(metadata);
    getSubscribedPodcastsCommand.run();
  }

  Future<void> removePodcast({required String feedUrl}) async {
    await _podcastLibraryService.removePodcast(feedUrl);
    getSubscribedPodcastsCommand.run();
  }

  final Map<String, Podcast> _podcastCache = {};
  Podcast? getPodcastFromCache(String? feedUrl) => _podcastCache[feedUrl];
  String? getPodcastDescriptionFromCache(String? feedUrl) =>
      _podcastCache[feedUrl]?.description;

  Future<List<EpisodeMedia>> findEpisodes({
    Item? item,
    String? feedUrl,
    bool loadFromCache = true,
  }) async {
    if (item == null && item?.feedUrl == null && feedUrl == null) {
      return Future.error(
        ArgumentError('Either item or feedUrl must be provided'),
      );
    }

    final url = feedUrl ?? item!.feedUrl!;

    Podcast? podcast;
    if (loadFromCache && _podcastCache.containsKey(url)) {
      podcast = _podcastCache[url];
    } else {
      podcast = await _podcastService.fetchPodcast(item: item, feedUrl: url);
      if (podcast != null) {
        _podcastCache[url] = podcast;
      }
    }

    if (podcast?.image != null) {
      _podcastLibraryService.addSubscribedPodcastImage(
        feedUrl: url,
        imageUrl: podcast!.image!,
      );
    } else if (item?.bestArtworkUrl != null) {
      _podcastLibraryService.addSubscribedPodcastImage(
        feedUrl: url,
        imageUrl: item!.bestArtworkUrl!,
      );
    }

    return podcast?.toEpisodeMediaList(url, item) ?? [];
  }

  Future<void> checkForUpdates({
    Set<String>? feedUrls,
    required String updateMessage,
    required String Function(int length) multiUpdateMessage,
  }) async {
    final newUpdateFeedUrls = <String>{};

    for (final feedUrl in (feedUrls ?? _podcastLibraryService.podcasts)) {
      final storedTimeStamp = _podcastLibraryService.getPodcastLastUpdated(
        feedUrl,
      );
      DateTime? feedLastUpdated;
      try {
        feedLastUpdated = await Feed.feedLastUpdated(url: feedUrl);
      } on Exception catch (e) {
        printMessageInDebugMode(e);
      }
      final name = _podcastLibraryService.getSubscribedPodcastName(feedUrl);

      printMessageInDebugMode('checking update for: ${name ?? feedUrl} ');
      printMessageInDebugMode(
        'storedTimeStamp: ${storedTimeStamp ?? 'no timestamp'}',
      );
      printMessageInDebugMode(
        'feedLastUpdated: ${feedLastUpdated?.podcastTimeStamp ?? 'no timestamp'}',
      );

      if (feedLastUpdated == null) continue;

      await _podcastLibraryService.addPodcastLastUpdated(
        feedUrl: feedUrl,
        timestamp: feedLastUpdated.podcastTimeStamp,
      );

      if (storedTimeStamp != null &&
          !storedTimeStamp.isSamePodcastTimeStamp(feedLastUpdated)) {
        await findEpisodes(feedUrl: feedUrl, loadFromCache: false);
        await _podcastLibraryService.addPodcastUpdate(feedUrl, feedLastUpdated);

        newUpdateFeedUrls.add(feedUrl);
      }
    }

    if (newUpdateFeedUrls.isNotEmpty) {
      final msg = newUpdateFeedUrls.length == 1
          ? '$updateMessage${_podcastCache[newUpdateFeedUrls.first]?.title != null ? ' ${_podcastCache[newUpdateFeedUrls.first]?.title}' : ''}'
          : multiUpdateMessage(newUpdateFeedUrls.length);
      await _notificationsService.notify(message: msg);
    }
  }
}

class GetMetadataCapsule {
  GetMetadataCapsule({required this.feedUrl, this.item});

  final String feedUrl;
  final Item? item;
}
