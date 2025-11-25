import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../player/player_manager.dart';
import '../podcast_manager.dart';

class PodcastCardPlayButton extends StatelessWidget with WatchItMixin {
  const PodcastCardPlayButton({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) {
    // Handler only exists while this button is mounted - won't fire when
    // PodcastPageEpisodeList fetches episodes (different widget tree)
    registerHandler(
      select: (PodcastManager m) => m.fetchEpisodeMediaCommand.results,
      handler: (context, result, cancel) {
        if (result.isRunning) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        } else if (result.isSuccess) {
          Navigator.of(context).pop();
          if (result.data != null && result.data!.isNotEmpty) {
            di<PlayerManager>().setPlaylist(result.data!, index: 0);
          }
        } else if (result.hasError) {
          Navigator.of(context).pop();
        }
      },
    );

    return FloatingActionButton.small(
      heroTag: 'podcastcardfap',
      onPressed: () =>
          di<PodcastManager>().fetchEpisodeMediaCommand.run(podcastItem),
      child: const Icon(Icons.play_arrow),
    );
  }
}
