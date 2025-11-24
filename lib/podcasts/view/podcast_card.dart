import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:phoenix_theme/phoenix_theme.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../common/view/safe_network_image.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../extensions/string_x.dart';
import '../../player/player_manager.dart';
import '../podcast_manager.dart';
import 'podcast_favorite_button.dart';
import 'podcast_page.dart';

class PodcastCard extends StatefulWidget with WatchItStatefulWidgetMixin {
  const PodcastCard({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  State<PodcastCard> createState() => _PodcastCardState();
}

class _PodcastCardState extends State<PodcastCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Handle loading dialog and auto-play when episodes are fetched
    registerHandler(
      select: (PodcastManager m) => m.fetchEpisodeMediaCommand.results,
      handler: (context, result, cancel) {
        if (result.isRunning) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (result.isSuccess) {
          // Dismiss dialog
          Navigator.of(context).pop();

          // Play episodes if available
          if (result.data != null && result.data!.isNotEmpty) {
            di<PlayerManager>().setPlaylist(result.data!, index: 0);
          }
        } else if (result.hasError) {
          // Dismiss dialog on error
          Navigator.of(context).pop();
        }
      },
    );

    final theme = context.theme;
    final isLight = theme.colorScheme.isLight;
    const borderRadiusGeometry = BorderRadiusGeometry.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
    );
    return InkWell(
      focusColor: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      onHover: (hovering) => setState(() => _hovered = hovering),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PodcastPage(podcastItem: widget.podcastItem),
        ),
      ),
      child: SizedBox(
        width: kGridViewDelegate.maxCrossAxisExtent,
        height: kGridViewDelegate.mainAxisExtent,
        child: Card(
          margin: EdgeInsets.zero,
          color: (isLight ? Colors.white : theme.colorScheme.onSurface)
              .withAlpha(isLight ? 200 : 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: _hovered ? 0.3 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: (widget.podcastItem.bestArtworkUrl != null)
                        ? ClipRRect(
                            borderRadius: borderRadiusGeometry,
                            child: SizedBox(
                              width: kGridViewDelegate.maxCrossAxisExtent,
                              height: kGridViewDelegate.mainAxisExtent! - 60,
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
                              color: context.colorScheme.onSurface.withAlpha(
                                100,
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
                    child: _hovered
                        ? Row(
                            spacing: kBigPadding,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FloatingActionButton.small(
                                heroTag: 'podcastcardfap',
                                onPressed: () => di<PodcastManager>()
                                    .fetchEpisodeMediaCommand
                                    .run(widget.podcastItem),
                                child: const Icon(Icons.play_arrow),
                              ),
                              PodcastFavoriteButton.floating(
                                podcastItem: widget.podcastItem,
                              ),
                            ],
                          )
                        : Text(
                            widget.podcastItem.collectionName?.unEscapeHtml ??
                                '',
                            style: Theme.of(context).textTheme.labelSmall,
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
      ),
    );
  }
}
