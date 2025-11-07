import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:phoenix_theme/phoenix_theme.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../common/view/safe_network_image.dart';
import '../../extensions/build_context_x.dart';
import '../podcast_library_service.dart';
import 'podcast_page.dart';

class PodcastCard extends StatelessWidget {
  const PodcastCard({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) {
    final isLight = context.colorScheme.isLight;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PodcastPage(podcastItem: podcastItem),
        ),
      ),
      child: SizedBox.square(
        dimension: 200,
        child: Card(
          color: (isLight ? Colors.white : context.colorScheme.onSurface)
              .withAlpha(isLight ? 200 : 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (podcastItem.bestArtworkUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadiusGeometry.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: SizedBox(
                    height: 200,
                    child: SafeNetworkImage(
                      url: podcastItem.bestArtworkUrl!,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  podcastItem.collectionName ?? '',
                  style: Theme.of(context).textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PodcastFavoriteButton extends StatelessWidget with WatchItMixin {
  const PodcastFavoriteButton({super.key, required this.podcastItem});

  final Item podcastItem;

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

    return IconButton(
      onPressed: () => isSubscribed
          ? di<PodcastLibraryService>().removePodcast(podcastItem.feedUrl!)
          : di<PodcastLibraryService>().addPodcast(
              feedUrl: podcastItem.feedUrl!,
              name: podcastItem.collectionName!,
              artist: podcastItem.artistName!,
              imageUrl: podcastItem.bestArtworkUrl!,
            ),
      icon: Icon(isSubscribed ? Icons.favorite : Icons.favorite_border),
    );
  }
}
