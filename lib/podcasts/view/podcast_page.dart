import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../common/view/safe_network_image.dart';
import '../../common/view/sliver_audio_page_control_panel.dart';
import '../../extensions/build_context_x.dart';
import 'podcast_card.dart';
import 'podcast_page_episode_list.dart';

class PodcastPage extends StatelessWidget with WatchItMixin {
  const PodcastPage({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) {
    var radius = Radius.circular(
      context.theme.dialogTheme.shape is RoundedRectangleBorder
          ? (context.theme.dialogTheme.shape as RoundedRectangleBorder)
                .borderRadius
                .resolve(TextDirection.ltr)
                .topLeft
                .x
          : 12,
    );
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,

      content: ClipRRect(
        borderRadius: BorderRadiusGeometry.all(radius),

        child: SizedBox(
          height: 800,
          width: 400,
          child: CustomScrollView(
            slivers: [
              if (podcastItem.bestArtworkUrl != null)
                SliverToBoxAdapter(
                  child: Material(
                    color: Colors.transparent,
                    child: SafeNetworkImage(
                      height: 400,
                      width: double.infinity,
                      url: podcastItem.bestArtworkUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              SliverAudioPageControlPanel(
                backgroundColor: context.theme.dialogTheme.backgroundColor,
                controlPanel: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    PodcastFavoriteButton(podcastItem: podcastItem),
                    Flexible(
                      child: Text(
                        podcastItem.collectionName ?? context.l10n.podcast,
                        style: context.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PodcastPageEpisodeList(podcastItem: podcastItem),
            ],
          ),
        ),
      ),
    );
  }
}
