import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../collection/collection_manager.dart';
import '../../common/view/ui_constants.dart';
import '../podcast_library_service.dart';
import 'podcast_card.dart';

class PodcastCollectionView extends StatelessWidget with WatchItMixin {
  const PodcastCollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final filterText = watchValue(
      (CollectionManager s) => s.textChangedCommand,
    );
    final podcasts =
        watchStream(
          (PodcastLibraryService s) => s.getPodcastStream(filterText),
          initialValue: di<PodcastLibraryService>().getFilteredPodcasts(
            filterText,
          ),
          preserveState: false,
          allowStreamChange: true,
        ).data ??
        <String>{};

    return GridView.builder(
      padding: kGridViewPadding.copyWith(top: kBigPadding),
      gridDelegate: kGridViewDelegate,
      itemCount: podcasts.length,
      itemBuilder: (context, index) {
        final feedUrl = podcasts.elementAt(index);
        return PodcastCard(
          key: ValueKey(feedUrl),
          podcastItem: Item(
            feedUrl: feedUrl,
            artistName: di<PodcastLibraryService>().getSubscribedPodcastArtist(
              feedUrl,
            ),
            collectionName: di<PodcastLibraryService>()
                .getSubscribedPodcastName(feedUrl),
            artworkUrl: di<PodcastLibraryService>().getSubscribedPodcastImage(
              feedUrl,
            ),
            genre:
                di<PodcastLibraryService>()
                    .getSubScribedPodcastGenreList(feedUrl)
                    ?.mapIndexed((i, e) => Genre(i, e))
                    .toList() ??
                <Genre>[],
          ),
        );
      },
    );
  }
}
