import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../collection/collection_manager.dart';
import '../common/logging.dart';
import '../extensions/country_x.dart';
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
  }) : _podcastService = podcastService,
       _podcastLibraryService = podcastLibraryService {
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

    podcastsCommand = Command.createSync(
      (filterText) =>
          podcastLibraryService.getFilteredPodcastsWithMetadata(filterText),
      initialValue: [],
    );

    collectionManager.textChangedCommand.listen(
      (filterText, sub) => podcastsCommand.run(filterText),
    );

    fetchEpisodeMediaCommand = Command.createAsync<Item, List<EpisodeMedia>>(
      (podcast) => _podcastService.findEpisodes(item: podcast),
      initialValue: [],
    );

    podcastsCommand.run(null);

    updateSearchCommand.run(null);
  }

  final PodcastService _podcastService;
  final PodcastLibraryService _podcastLibraryService;

  // Track episodes currently downloading
  final activeDownloads = ListNotifier<EpisodeMedia>();

  late Command<String?, SearchResult> updateSearchCommand;
  late Command<Item, List<EpisodeMedia>> fetchEpisodeMediaCommand;
  late Command<String?, List<PodcastMetadata>> podcastsCommand;

  Future<void> addPodcast(PodcastMetadata metadata) async {
    await _podcastLibraryService.addPodcast(metadata);
    podcastsCommand.run();
  }

  Future<void> removePodcast({required String feedUrl}) async {
    await _podcastLibraryService.removePodcast(feedUrl);
    podcastsCommand.run();
  }
}
