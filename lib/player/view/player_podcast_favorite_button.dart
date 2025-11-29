import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../podcasts/data/podcast_metadata.dart';
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

    void onPressed() =>
        di<PodcastManager>().togglePodcastSubscriptionCommand.run(
          PodcastMetadata(
            feedUrl: episodeMedia.feedUrl,
            name: episodeMedia.collectionName,
            imageUrl: episodeMedia.collectionArtUrl,
            genreList: episodeMedia.genres,
            artist: episodeMedia.artist,
            description: episodeMedia.description,
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
