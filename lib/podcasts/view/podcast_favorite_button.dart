import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../data/podcast_metadata.dart';
import '../podcast_manager.dart';

class PodcastFavoriteButton extends StatelessWidget with WatchItMixin {
  const PodcastFavoriteButton({super.key, required this.metadata})
    : _floating = false;
  const PodcastFavoriteButton.floating({super.key, required this.metadata})
    : _floating = true;

  final PodcastMetadata metadata;
  final bool _floating;

  @override
  Widget build(BuildContext context) {
    final isSubscribed = watchValue(
      (PodcastManager m) => m.getSubscribedPodcastsCommand.select(
        (podcasts) => podcasts.any((p) => p.feedUrl == metadata.feedUrl),
      ),
    );

    void onPressed() => isSubscribed
        ? di<PodcastManager>().removePodcast(feedUrl: metadata.feedUrl)
        : di<PodcastManager>().addPodcast(metadata);
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
