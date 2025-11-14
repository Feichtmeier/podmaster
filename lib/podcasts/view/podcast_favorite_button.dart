import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../podcast_library_service.dart';

class PodcastFavoriteButton extends StatelessWidget with WatchItMixin {
  const PodcastFavoriteButton({super.key, required this.podcastItem})
    : _floating = false;
  const PodcastFavoriteButton.floating({super.key, required this.podcastItem})
    : _floating = true;

  final Item podcastItem;
  final bool _floating;

  @override
  Widget build(BuildContext context) {
    final isSubscribed =
        watchStream(
          (PodcastLibraryService s) => s.propertiesChanged.map(
            (_) => di<PodcastLibraryService>().isPodcastSubscribed(
              podcastItem.feedUrl!,
            ),
          ),
          initialValue: di<PodcastLibraryService>().isPodcastSubscribed(
            podcastItem.feedUrl!,
          ),
        ).data ??
        false;

    void onPressed() => isSubscribed
        ? di<PodcastLibraryService>().removePodcast(podcastItem.feedUrl!)
        : di<PodcastLibraryService>().addPodcast(
            feedUrl: podcastItem.feedUrl!,
            name: podcastItem.collectionName!,
            artist: podcastItem.artistName!,
            imageUrl: podcastItem.bestArtworkUrl!,
            genreList:
                podcastItem.genre?.map((e) => e.name).toList() ?? <String>[],
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
