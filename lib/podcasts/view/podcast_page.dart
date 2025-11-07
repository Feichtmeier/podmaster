import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../common/view/safe_network_image.dart';
import '../../extensions/build_context_x.dart';
import '../../player/player_manager.dart';
import '../../player/view/player_view.dart';
import 'podcast_card.dart';
import 'podcast_page_episode_list.dart';

class PodcastPage extends StatelessWidget with WatchItMixin {
  const PodcastPage({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) {
    watchStream(
      (PlayerManager m) => m.currentMediaStream,
      initialValue: di<PlayerManager>().currentMedia,
    ).data;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Flexible(
                child: Text(
                  podcastItem.collectionName ?? context.l10n.podcast,
                  style: context.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PodcastFavoriteButton(podcastItem: podcastItem),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PlayerView(),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (podcastItem.bestArtworkUrl != null)
            Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(16),
                  child: SafeNetworkImage(
                    height: 250,
                    width: 250,
                    url: podcastItem.bestArtworkUrl!,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
            ),
          Flexible(
            child: SizedBox(
              width: context.mediaQuerySize.width,
              child: PodcastPageEpisodeList(podcastItem: podcastItem),
            ),
          ),
        ],
      ),
    );
  }
}
