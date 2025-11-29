import 'package:flutter/material.dart';
import 'package:phoenix_theme/phoenix_theme.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../common/view/safe_network_image.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../extensions/string_x.dart';
import '../data/podcast_metadata.dart';
import 'podcast_card_play_button.dart';
import 'podcast_favorite_button.dart';
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
          builder: (context) => PodcastPage(
            feedUrl: widget.podcastItem.feedUrl!,
            podcastItem: widget.podcastItem,
          ),
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
                              PodcastCardPlayButton(
                                podcastItem: widget.podcastItem,
                              ),
                              PodcastFavoriteButton.floating(
                                metadata: PodcastMetadata(
                                  feedUrl: widget.podcastItem.feedUrl!,
                                  imageUrl: widget.podcastItem.bestArtworkUrl,
                                  name: widget.podcastItem.collectionName,
                                  artist: widget.podcastItem.artistName,
                                  genreList: widget.podcastItem.genre
                                      ?.map((e) => e.name)
                                      .toList(),
                                ),
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
