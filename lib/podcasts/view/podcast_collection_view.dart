import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../collection/collection_manager.dart';
import '../../common/view/ui_constants.dart';
import '../podcast_library_service.dart';
import '../podcast_manager.dart';
import 'podcast_card.dart';

class PodcastCollectionView extends StatelessWidget with WatchItMixin {
  const PodcastCollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final feedsWithDownloads =
        watchStream(
          (PodcastLibraryService m) =>
              m.propertiesChanged.map((_) => m.feedsWithDownloads),
          initialValue: di<PodcastLibraryService>().feedsWithDownloads,
          allowStreamChange: true,
          preserveState: false,
        ).data ??
        <String>{};

    final showOnlyDownloads = watchValue(
      (CollectionManager m) => m.showOnlyDownloadsNotifier,
    );

    return watchValue(
      (PodcastManager m) => m.getSubscribedPodcastsCommand.results,
    ).toWidget(
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
            return PodcastCard(key: ValueKey(item), podcastItem: item);
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
