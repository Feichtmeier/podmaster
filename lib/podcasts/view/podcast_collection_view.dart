import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../common/view/ui_constants.dart';
import '../podcast_library_service.dart';
import 'podcast_card.dart';

class PodcastCollectionView extends StatelessWidget with WatchItMixin {
  const PodcastCollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final podcastsLength =
        watchStream(
          (PodcastLibraryService s) => s.propertiesChanged.map(
            (e) => di<PodcastLibraryService>().podcastsLength,
          ),
          initialValue: di<PodcastLibraryService>().podcastsLength,
        ).data ??
        0;

    final podcasts = di<PodcastLibraryService>().podcasts;

    return GridView.builder(
      padding: kGridViewPadding,
      gridDelegate: kGridViewDelegate,
      itemCount: podcastsLength,
      itemBuilder: (context, index) {
        final feedUrl = podcasts.elementAt(index);
        return PodcastCard(
          key: ValueKey(feedUrl),
          podcastItem: Item(
            feedUrl: feedUrl,
            collectionName: di<PodcastLibraryService>()
                .getSubscribedPodcastName(feedUrl),
            artworkUrl: di<PodcastLibraryService>().getSubscribedPodcastImage(
              feedUrl,
            ),
          ),
        );
      },
    );
  }
}
