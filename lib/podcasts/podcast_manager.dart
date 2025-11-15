import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../common/logging.dart';
import '../extensions/country_x.dart';
import '../player/data/episode_media.dart';
import 'podcast_service.dart';

/// Manages podcast search and episode fetching.
///
/// Note: This manager is registered as a singleton in get_it and lives for the
/// entire app lifetime. Commands and subscriptions don't need explicit disposal
/// as they're automatically cleaned up when the app process terminates.
class PodcastManager {
  PodcastManager({required PodcastService podcastService})
    : _podcastService = podcastService {
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
    textChangedCommand = Command.createSync((s) => s, initialValue: '');

    // Subscription doesn't need disposal - manager lives for app lifetime
    textChangedCommand
        .debounce(const Duration(milliseconds: 500))
        .listen((filterText, sub) => updateSearchCommand.run(filterText));

    fetchEpisodeMediaCommand = Command.createAsync<Item, List<EpisodeMedia>>(
      (podcast) => _podcastService.findEpisodes(item: podcast),
      initialValue: [],
    );
    updateSearchCommand.run(null);
  }

  final PodcastService _podcastService;
  late Command<String, String> textChangedCommand;
  late Command<String?, SearchResult> updateSearchCommand;
  late Command<Item, List<EpisodeMedia>> fetchEpisodeMediaCommand;
}
