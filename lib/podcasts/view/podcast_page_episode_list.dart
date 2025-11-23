import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../collection/collection_manager.dart';
import '../../player/player_manager.dart';
import '../download_manager.dart';
import '../podcast_manager.dart';
import 'episode_tile.dart';

class PodcastPageEpisodeList extends StatelessWidget with WatchItMixin {
  const PodcastPageEpisodeList({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) {
    callOnce(
      (context) => di<PodcastManager>().fetchEpisodeMediaCommand(podcastItem),
    );

    final downloadsOnly = watchValue(
      (CollectionManager m) => m.showOnlyDownloadsNotifier,
    );

    return watchValue(
      (PodcastManager m) => m.fetchEpisodeMediaCommand.results,
    ).toWidget(
      onData: (episodesX, param) {
        final episodes = downloadsOnly
            ? episodesX
                  .where(
                    (e) => di<DownloadManager>().getDownload(e.url) != null,
                  )
                  .toList()
            : episodesX;
        return SliverList.builder(
          itemCount: episodes.length,
          itemBuilder: (context, index) => EpisodeTile(
            episode: episodes.elementAt(index),
            podcastImage: podcastItem.bestArtworkUrl,
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
