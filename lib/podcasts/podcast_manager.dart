import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../collection/collection_manager.dart';
import '../common/logging.dart';
import '../extensions/country_x.dart';
import '../extensions/date_time_x.dart';
import '../extensions/string_x.dart';
import '../notifications/notifications_service.dart';
import '../player/data/episode_media.dart';
import '../search/search_manager.dart';
import 'data/podcast_metadata.dart';
import 'data/podcast_proxy.dart';
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
    required SearchManager searchManager,
    required CollectionManager collectionManager,
    required PodcastLibraryService podcastLibraryService,
    required NotificationsService notificationsService,
  }) : _podcastService = podcastService,
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
      (filterText) => podcastLibraryService.getFilteredPodcastItems(filterText),
      initialValue: [],
    );

    collectionManager.textChangedCommand.listen(
      (filterText, sub) => getSubscribedPodcastsCommand.run(filterText),
    );

    checkForUpdatesCommand =
        Command.createAsync<
          ({String updateMessage, String Function(int) multiUpdateMessage}),
          void
        >((params) async {
          final updatedProxies = <PodcastProxy>[];

          // Check all subscribed podcasts for updates
          for (final feedUrl in _podcastLibraryService.podcasts) {
            final proxy = getOrCreateProxy(Item(feedUrl: feedUrl));
            final hasUpdate = await _checkForUpdate(proxy);
            if (hasUpdate) {
              updatedProxies.add(proxy);
            }
          }

          if (updatedProxies.isNotEmpty) {
            final msg = updatedProxies.length == 1
                ? '${params.updateMessage} ${updatedProxies.first.title ?? ''}'
                : params.multiUpdateMessage(updatedProxies.length);
            await _notificationsService.notify(message: msg);
          }
        }, initialValue: null);

    togglePodcastSubscriptionCommand =
        Command.createUndoableNoResult<Item, ({bool wasAdd, Item item})>(
          (item, stack) async {
            final feedUrl = item.feedUrl;
            if (feedUrl == null) return;

            final currentList = getSubscribedPodcastsCommand.value;
            final isSubscribed = currentList.any((p) => p.feedUrl == feedUrl);

            // Store operation info for undo
            stack.push((wasAdd: !isSubscribed, item: item));

            // Optimistic update: modify list directly
            if (isSubscribed) {
              getSubscribedPodcastsCommand.value = currentList
                  .where((p) => p.feedUrl != feedUrl)
                  .toList();
            } else {
              getSubscribedPodcastsCommand.value = [...currentList, item];
            }

            // Async persist
            await (isSubscribed
                ? _podcastLibraryService.removePodcast(feedUrl)
                : _podcastLibraryService.addPodcast(
                    PodcastMetadata.fromItem(item),
                  ));
          },
          undo: (stack, reason) async {
            final undoData = stack.pop();
            final currentList = getSubscribedPodcastsCommand.value;

            if (undoData.wasAdd) {
              // Was an add, so remove it
              getSubscribedPodcastsCommand.value = currentList
                  .where((p) => p.feedUrl != undoData.item.feedUrl)
                  .toList();
            } else {
              // Was a remove, so add it back
              getSubscribedPodcastsCommand.value = [
                ...currentList,
                undoData.item,
              ];
            }
          },
          undoOnExecutionFailure: true,
        );

    getSubscribedPodcastsCommand.run(null);

    updateSearchCommand.run(null);
  }

  final PodcastService _podcastService;
  final PodcastLibraryService _podcastLibraryService;
  final NotificationsService _notificationsService;

  // Track episodes currently downloading
  final activeDownloads = ListNotifier<EpisodeMedia>();

  /// Registers an episode as actively downloading.
  /// Called by EpisodeMedia.downloadCommand when download starts.
  void registerActiveDownload(EpisodeMedia episode) {
    activeDownloads.add(episode);
  }

  /// Unregisters an episode from active downloads.
  /// Called by EpisodeMedia.downloadCommand on error.
  void unregisterActiveDownload(EpisodeMedia episode) {
    activeDownloads.remove(episode);
  }

  // Proxy cache - each podcast owns its fetchEpisodesCommand
  final _proxyCache = <String, PodcastProxy>{};

  /// Gets or creates a PodcastProxy for the given Item.
  /// The proxy owns the fetchEpisodesCommand.
  PodcastProxy getOrCreateProxy(Item item) {
    return _proxyCache.putIfAbsent(
      item.feedUrl!,
      () => PodcastProxy(item: item, podcastService: _podcastService),
    );
  }

  /// Checks a single podcast for updates. Returns true if updated.
  Future<bool> _checkForUpdate(PodcastProxy proxy) async {
    final feedUrl = proxy.feedUrl;
    final storedTimeStamp = _podcastLibraryService.getPodcastLastUpdated(
      feedUrl,
    );
    DateTime? feedLastUpdated;

    try {
      feedLastUpdated = await Feed.feedLastUpdated(url: feedUrl);
    } on Exception catch (e) {
      printMessageInDebugMode(e);
    }

    printMessageInDebugMode('checking update for: ${proxy.title ?? feedUrl}');
    printMessageInDebugMode(
      'storedTimeStamp: ${storedTimeStamp ?? 'no timestamp'}',
    );
    printMessageInDebugMode(
      'feedLastUpdated: ${feedLastUpdated?.podcastTimeStamp ?? 'no timestamp'}',
    );

    if (feedLastUpdated == null) return false;

    await _podcastLibraryService.addPodcastLastUpdated(
      feedUrl: feedUrl,
      timestamp: feedLastUpdated.podcastTimeStamp,
    );

    if (storedTimeStamp != null &&
        !storedTimeStamp.isSamePodcastTimeStamp(feedLastUpdated)) {
      // Clear cached episodes to force refresh
      proxy.clearEpisodeCache();
      await proxy.fetchEpisodesCommand.runAsync();

      await _podcastLibraryService.addPodcastUpdate(feedUrl, feedLastUpdated);
      return true; // Has update
    }
    return false;
  }

  late Command<String?, SearchResult> updateSearchCommand;
  late Command<String?, List<Item>> getSubscribedPodcastsCommand;
  late Command<
    ({String updateMessage, String Function(int) multiUpdateMessage}),
    void
  >
  checkForUpdatesCommand;
  late final Command<Item, void> togglePodcastSubscriptionCommand;

  Future<void> addPodcast(PodcastMetadata metadata) async {
    await _podcastLibraryService.addPodcast(metadata);
    getSubscribedPodcastsCommand.run();
  }

  Future<void> removePodcast({required String feedUrl}) async {
    await _podcastLibraryService.removePodcast(feedUrl);
    getSubscribedPodcastsCommand.run();
  }

  String? getPodcastDescription(String? feedUrl) =>
      _proxyCache[feedUrl]?.description;
}
