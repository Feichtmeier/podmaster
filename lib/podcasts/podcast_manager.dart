import 'package:dio/dio.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../collection/collection_manager.dart';
import '../common/logging.dart';
import '../extensions/country_x.dart';
import '../player/data/episode_media.dart';
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
  }) : _podcastService = podcastService,
       _downloadService = downloadService,
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
  final DownloadService _downloadService;

  late Command<String?, SearchResult> updateSearchCommand;
  late Command<Item, List<EpisodeMedia>> fetchEpisodeMediaCommand;
  late Command<String?, List<PodcastMetadata>> podcastsCommand;

  final downloadCommands = <EpisodeMedia, Command<void, void>>{};
  final activeDownloads = ListNotifier<EpisodeMedia>();
  final recentDownloads = ListNotifier<EpisodeMedia>();

  Command<void, void> getDownloadCommand(EpisodeMedia media) =>
      downloadCommands.putIfAbsent(media, () => _createDownloadCommand(media));

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

  Future<void> addPodcast(PodcastMetadata metadata) async {
    await _podcastLibraryService.addPodcast(metadata);
    podcastsCommand.run();
  }

  Future<void> removePodcast({required String feedUrl}) async {
    await _podcastLibraryService.removePodcast(feedUrl);
    podcastsCommand.run();
  }
}
