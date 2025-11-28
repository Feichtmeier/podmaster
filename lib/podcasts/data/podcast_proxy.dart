import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../player/data/episode_media.dart';
import '../../player/player_manager.dart';
import '../podcast_service.dart';

/// Wraps Item (search result) and lazily loads Podcast + episodes.
/// Each podcast owns its own fetchEpisodesCommand.
class PodcastProxy {
  PodcastProxy({
    required this.item,
    PodcastService? podcastService,
    PlayerManager? playerManager,
  }) : _podcastService = podcastService ?? di<PodcastService>(),
       _playerManager = playerManager ?? di<PlayerManager>() {
    fetchEpisodesCommand = Command.createAsyncNoParam<List<EpisodeMedia>>(
      () async {
        if (_episodes != null) return _episodes!;

        final result = await _podcastService.findEpisodes(item: item);
        _podcast = result.podcast;
        _episodes = result.episodes;
        return _episodes!;
      },
      initialValue: [],
    );
  }

  final Item item;
  final PodcastService _podcastService;
  final PlayerManager _playerManager;

  Podcast? _podcast;
  List<EpisodeMedia>? _episodes;

  late final Command<void, List<EpisodeMedia>> fetchEpisodesCommand;

  /// Fetches episodes if not cached, then starts playback.
  late final playEpisodesCommand = Command.createAsyncNoResult<int>((
    startIndex,
  ) async {
    // Fetch if not cached
    if (_episodes == null) {
      await fetchEpisodesCommand.runAsync();
    }

    if (_episodes != null && _episodes!.isNotEmpty) {
      await _playerManager.setPlaylist(_episodes!, index: startIndex);
    }
  });

  /// Clears cached episodes to force re-fetch on next command run.
  void clearEpisodeCache() {
    _episodes = null;
  }

  // Getters - use Podcast if loaded, fall back to Item
  String get feedUrl => item.feedUrl!;
  String? get description => _podcast?.description;
  String? get title => _podcast?.title ?? item.collectionName;
  String? get image => _podcast?.image ?? item.bestArtworkUrl;
  List<EpisodeMedia> get episodes => _episodes ?? [];
}
