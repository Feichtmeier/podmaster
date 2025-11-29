import 'package:dio/dio.dart';
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
import '../search/search_manager.dart';
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
  }) : _podcastService = podcastService,
       _downloadService = downloadService,
       _podcastLibraryService = podcastLibraryService,
       _notificationsService = notificationsService {
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

    getSubscribedPodcastsCommand = Command.createSync(
      (filterText) =>
          podcastLibraryService.getFilteredPodcastsItems(filterText),
      initialValue: [],
    );

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

  // Map of feedUrl to fetch episodes command
  final _fetchEpisodeMediaCommands =
      <String, Command<Item, List<EpisodeMedia>>>{};

  Command<Item, List<EpisodeMedia>> _getFetchEpisodesCommand(Item item) {
    if (item.feedUrl == null) {
      throw ArgumentError('Item must have a feedUrl to fetch episodes');
    }
    return _fetchEpisodeMediaCommands.putIfAbsent(
      item.feedUrl!,
      () => Command.createAsync<Item, List<EpisodeMedia>>(
        (item) async => findEpisodes(item: item),
        initialValue: [],
      ),
    );
  }

  Command<Item, List<EpisodeMedia>> runFetchEpisodesCommand(Item item) {
    _getFetchEpisodesCommand(item).run(item);
    return _getFetchEpisodesCommand(item);
  }

  late Command<String?, SearchResult> updateSearchCommand;
  late Command<String?, List<Item>> getSubscribedPodcastsCommand;

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
    }, errorFilter: const LocalAndGlobalErrorFilter());

    if (_podcastLibraryService.getDownload(media.url) != null) {
      command.resetProgress(progress: 1.0);
    }

    return command;
  }

  Future<void> addPodcast(Item item) async {
    await _podcastLibraryService.addPodcast(item);
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
