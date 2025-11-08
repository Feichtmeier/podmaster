import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:phoenix_theme/phoenix_theme.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../common/view/safe_network_image.dart';
import '../../extensions/build_context_x.dart';
import '../../player/player_manager.dart';
import '../podcast_library_service.dart';
import '../podcast_service.dart';
import 'podcast_page.dart';

class PodcastCard extends StatefulWidget {
  const PodcastCard({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  State<PodcastCard> createState() => _PodcastCardState();
}

class _PodcastCardState extends State<PodcastCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = context.colorScheme.isLight;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onHover: (hovering) => setState(() => _hovered = hovering),
      onTap: () => showDialog(
        context: context,
        fullscreenDialog: true,
        builder: (context) => PodcastPage(podcastItem: widget.podcastItem),
      ),
      child: Card(
        color: (isLight ? Colors.white : context.colorScheme.onSurface)
            .withAlpha(isLight ? 200 : 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                AnimatedOpacity(
                  opacity: _hovered ? 0.4 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: (widget.podcastItem.bestArtworkUrl != null)
                      ? ClipRRect(
                          borderRadius: const BorderRadiusGeometry.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: SizedBox(
                            height: 200,
                            child: SafeNetworkImage(
                              url: widget.podcastItem.bestArtworkUrl!,
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 200,
                          child: Icon(
                            Icons.podcasts,
                            size: 100,
                            color: context.colorScheme.onSurface.withAlpha(100),
                          ),
                        ),
                ),
                if (_hovered)
                  Positioned.fill(
                    child: Center(
                      child: IconButton(
                        onPressed: () async {
                          final res = await showFutureLoadingDialog(
                            context: context,
                            future: () async => di<PodcastService>()
                                .findEpisodes(item: widget.podcastItem),
                          );
                          if (res.isValue) {
                            final episodes = res.asValue!.value;
                            if (episodes.isNotEmpty) {
                              await di<PlayerManager>().setPlaylist(
                                episodes,
                                index: 0,
                              );
                            }
                          }
                        },
                        icon: Icon(
                          Icons.play_circle_fill,
                          size: 64,
                          color: context.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    widget.podcastItem.collectionName ?? '',
                    style: Theme.of(context).textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
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
