import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../common/logging.dart';
import '../player/data/episode_media.dart';
import 'podcast_service.dart';

class PodcastManager {
  PodcastManager({required PodcastService podcastService})
    : _podcastService = podcastService {
    Command.globalExceptionHandler = (e, s) {
      printMessageInDebugMode(e.error, s);
    };
    updateSearchCommand = Command.createAsync<String?, SearchResult>(
      (String? query) async =>
          _podcastService.search(searchQuery: query, limit: 20),
      initialValue: SearchResult(items: []),
    );
    textChangedCommand = Command.createSync((s) => s, initialValue: '');

    textChangedCommand
        .debounce(const Duration(milliseconds: 500))
        .listen((filterText, sub) => updateSearchCommand.execute(filterText));

    fetchEpisodeMediaCommand = Command.createAsync<Item, List<EpisodeMedia>>(
      (podcast) => _podcastService.findEpisodes(item: podcast),
      initialValue: [],
    );
    updateSearchCommand.execute(null);
  }

  final PodcastService _podcastService;
  late Command<String, String> textChangedCommand;
  late Command<String?, SearchResult> updateSearchCommand;
  late Command<Item, List<EpisodeMedia>> fetchEpisodeMediaCommand;
}
