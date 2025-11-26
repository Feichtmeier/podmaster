import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../podcasts/podcast_manager.dart';
import '../data/episode_media.dart';

class PlayerPodcastFavoriteButton extends StatelessWidget with WatchItMixin {
  const PlayerPodcastFavoriteButton({super.key, required this.episodeMedia})
    : _floating = false;
  const PlayerPodcastFavoriteButton.floating({
    super.key,
    required this.episodeMedia,
  }) : _floating = true;

  final EpisodeMedia episodeMedia;
  final bool _floating;

  @override
  Widget build(BuildContext context) {
    final isSubscribed = watchValue(
      (PodcastManager m) => m.getSubscribedPodcastsCommand.select(
        (podcasts) => podcasts.any((p) => p.feedUrl == episodeMedia.feedUrl),
      ),
    );

    void onPressed() => isSubscribed
        ? di<PodcastManager>().removePodcast(feedUrl: episodeMedia.feedUrl)
        : di<PodcastManager>().addPodcast(
            Item(
              feedUrl: episodeMedia.feedUrl,
              artworkUrl: episodeMedia.albumArtUrl,
              artworkUrl600: episodeMedia.albumArtUrl,
              collectionName: episodeMedia.collectionName,
              artistName: episodeMedia.artist,
            ),
          );
    final icon = Icon(isSubscribed ? Icons.favorite : Icons.favorite_border);

    if (_floating) {
      return FloatingActionButton.small(
        heroTag: 'favtag',
        onPressed: onPressed,
        child: icon,
      );
    }

    return IconButton(onPressed: onPressed, icon: icon);
  }
}
