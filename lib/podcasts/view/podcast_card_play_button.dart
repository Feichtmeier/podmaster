import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../extensions/build_context_x.dart';
import '../../player/player_manager.dart';
import '../podcast_manager.dart';

class PodcastCardPlayButton extends StatelessWidget with WatchItMixin {
  const PodcastCardPlayButton({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
    heroTag: 'podcastcardfap',
    onPressed: () =>
        showFutureLoadingDialog(
          context: context,
          title: context.l10n.loadingPodcastFeed,
          future: () => di<PodcastManager>().fetchEpisodes(podcastItem),
        ).then((result) {
          if (result.isValue) {
            di<PlayerManager>().setPlaylist(result.asValue!.value);
          }
        }),
    child: const Icon(Icons.play_arrow),
  );
}
