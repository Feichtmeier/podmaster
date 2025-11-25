import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../data/podcast_metadata.dart';
import '../podcast_manager.dart';

class PodcastFavoriteButton extends StatelessWidget with WatchItMixin {
  const PodcastFavoriteButton({super.key, required this.podcastItem})
    : _floating = false;
  const PodcastFavoriteButton.floating({super.key, required this.podcastItem})
    : _floating = true;

  final Item podcastItem;
  final bool _floating;

  @override
  Widget build(BuildContext context) {
    final isSubscribed = watchValue(
      (PodcastManager m) => m.podcastCollectionCommand.select(
        (podcasts) => podcasts.any((p) => p.feedUrl == podcastItem.feedUrl),
      ),
    );

    void onPressed() => isSubscribed
        ? di<PodcastManager>().removePodcast(feedUrl: podcastItem.feedUrl!)
        : di<PodcastManager>().addPodcast(
            PodcastMetadata.fromItem(podcastItem),
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
