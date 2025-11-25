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
      (filterText) =>
          podcastLibraryService.getFilteredPodcastsWithMetadata(filterText),
      initialValue: [],
    );

    collectionManager.textChangedCommand.listen(
      (filterText, sub) => getSubscribedPodcastsCommand.run(filterText),
    );

    fetchEpisodeMediaCommand = Command.createAsync<Item, List<EpisodeMedia>>((
      podcast,
    ) async {
      final feedUrl = podcast.feedUrl;
      if (feedUrl == null) return [];

      // Check cache first - returns same instances so downloadCommands work
      if (_episodeCache.containsKey(feedUrl)) {
        return _episodeCache[feedUrl]!;
      }

      // Fetch from service (no longer caches internally)
      final result = await _podcastService.findEpisodes(item: podcast);

      // Cache both episodes and description
      _episodeCache[feedUrl] = result.episodes;
      _podcastDescriptionCache[feedUrl] = result.description;

      return result.episodes;
    }, initialValue: []);

    checkForUpdatesCommand =
        Command.createAsync<
          ({
            Set<String>? feedUrls,
            String updateMessage,
            String Function(int) multiUpdateMessage,
          }),
          void
        >((params) async {
          final newUpdateFeedUrls = <String>{};

          for (final feedUrl
              in (params.feedUrls ?? _podcastLibraryService.podcasts)) {
            final storedTimeStamp = _podcastLibraryService
                .getPodcastLastUpdated(feedUrl);
            DateTime? feedLastUpdated;
            try {
              feedLastUpdated = await Feed.feedLastUpdated(url: feedUrl);
            } on Exception catch (e) {
              printMessageInDebugMode(e);
            }
            final name = _podcastLibraryService.getSubscribedPodcastName(
              feedUrl,
            );

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
              // Fetch episodes to refresh cache
              await fetchEpisodeMediaCommand.runAsync(Item(feedUrl: feedUrl));

              await _podcastLibraryService.addPodcastUpdate(
                feedUrl,
                feedLastUpdated,
              );
              newUpdateFeedUrls.add(feedUrl);
            }
          }

          if (newUpdateFeedUrls.isNotEmpty) {
            final podcastName = newUpdateFeedUrls.length == 1
                ? _podcastLibraryService.getSubscribedPodcastName(
                    newUpdateFeedUrls.first,
                  )
                : null;
            final msg = newUpdateFeedUrls.length == 1
                ? '${params.updateMessage}${podcastName != null ? ' $podcastName' : ''}'
                : params.multiUpdateMessage(newUpdateFeedUrls.length);
            await _notificationsService.notify(message: msg);
          }
        }, initialValue: null);

    togglePodcastSubscriptionCommand =
        Command.createUndoableNoResult<
          Item,
          ({bool wasAdd, PodcastMetadata metadata})
        >(
          (item, stack) async {
            final feedUrl = item.feedUrl;
            if (feedUrl == null) return;

            final currentList = getSubscribedPodcastsCommand.value;
            final isSubscribed = currentList.any((p) => p.feedUrl == feedUrl);

            final metadata = PodcastMetadata(
              feedUrl: feedUrl,
              name: item.collectionName,
              imageUrl: item.bestArtworkUrl,
            );

            // Store operation info for undo
            stack.push((wasAdd: !isSubscribed, metadata: metadata));

            // Optimistic update: modify list directly
            if (isSubscribed) {
              getSubscribedPodcastsCommand.value = currentList
                  .where((p) => p.feedUrl != feedUrl)
                  .toList();
            } else {
              getSubscribedPodcastsCommand.value = [...currentList, metadata];
            }

            // Async persist
            await (isSubscribed
                ? _podcastLibraryService.removePodcast(feedUrl)
                : _podcastLibraryService.addPodcast(metadata));
          },
          undo: (stack, reason) async {
            final undoData = stack.pop();
            final currentList = getSubscribedPodcastsCommand.value;

            if (undoData.wasAdd) {
              // Was an add, so remove it
              getSubscribedPodcastsCommand.value = currentList
                  .where((p) => p.feedUrl != undoData.metadata.feedUrl)
                  .toList();
            } else {
              // Was a remove, so add it back
              getSubscribedPodcastsCommand.value = [
                ...currentList,
                undoData.metadata,
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

  // Episode cache - ensures same instances across app for command state
  final _episodeCache = <String, List<EpisodeMedia>>{};
  final _podcastDescriptionCache = <String, String?>{};

  late Command<String?, SearchResult> updateSearchCommand;
  late Command<Item, List<EpisodeMedia>> fetchEpisodeMediaCommand;
  late Command<String?, List<PodcastMetadata>> getSubscribedPodcastsCommand;
  late Command<
    ({
      Set<String>? feedUrls,
      String updateMessage,
      String Function(int) multiUpdateMessage,
    }),
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
      _podcastDescriptionCache[feedUrl];
}
