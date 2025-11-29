import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../collection/collection_manager.dart';
import '../../player/player_manager.dart';
import '../podcast_manager.dart';
import 'episode_tile.dart';

class PodcastPageEpisodeList extends StatelessWidget with WatchItMixin {
  const PodcastPageEpisodeList({super.key, required this.feedUrl});

  final String feedUrl;

  @override
  Widget build(BuildContext context) {
    final downloadsOnly = watchValue(
      (CollectionManager m) => m.showOnlyDownloadsNotifier,
    );

    return watchValue(
      (PodcastManager m) => m.runFetchEpisodesCommand(feedUrl).results,
    ).toWidget(
      onData: (episodesX, param) {
        final episodes = downloadsOnly
            ? episodesX
                  .where(
                    (e) =>
                        di<PodcastManager>()
                            .getDownloadCommand(e)
                            .progress
                            .value ==
                        1.0,
                  )
                  .toList()
            : episodesX;
        return SliverList.builder(
          itemCount: episodes.length,
          itemBuilder: (context, index) => EpisodeTile(
            episode: episodes.elementAt(index),
            podcastImage: episodes.elementAt(index).albumArtUrl,
            setPlaylist: () =>
                di<PlayerManager>().setPlaylist(episodes, index: index),
          ),
        );
      },
      onError: (error, lastResult, param) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Error loading episodes: $error')),
      ),
      whileRunning: (res, query) => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}
