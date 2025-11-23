import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../collection/collection_manager.dart';
import '../../common/view/ui_constants.dart';
import '../download_manager.dart';
import '../podcast_manager.dart';
import 'podcast_card.dart';

class PodcastCollectionView extends StatelessWidget with WatchItMixin {
  const PodcastCollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final feedsWithDownloads = watchPropertyValue(
      (DownloadManager m) => m.feedsWithDownloads,
    );
    final showOnlyDownloads = watchValue(
      (CollectionManager m) => m.showOnlyDownloadsNotifier,
    );

    return watchValue((PodcastManager m) => m.podcastsCommand.results).toWidget(
      onData: (pees, _) {
        final podcasts = showOnlyDownloads
            ? pees.where((p) => feedsWithDownloads.contains(p.feedUrl))
            : pees;
        return GridView.builder(
          padding: kGridViewPadding.copyWith(top: kBigPadding),
          gridDelegate: kGridViewDelegate,
          itemCount: podcasts.length,
          itemBuilder: (context, index) {
            final item = podcasts.elementAt(index);
            return PodcastCard(
              key: ValueKey(item),
              podcastItem: Item(
                feedUrl: item.feedUrl,
                artistName: item.artist,
                collectionName: item.name,
                artworkUrl: item.imageUrl,
                genre:
                    item.genreList
                        ?.mapIndexed((i, e) => Genre(i, e))
                        .toList() ??
                    <Genre>[],
              ),
            );
          },
        );
      },
      whileRunning: (_, __) =>
          const Center(child: CircularProgressIndicator.adaptive()),
      onError: (error, _, __) =>
          Center(child: Text('Error loading podcasts: $error')),
    );
  }
}
