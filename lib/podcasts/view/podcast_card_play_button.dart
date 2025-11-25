import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../podcast_manager.dart';

class PodcastCardPlayButton extends StatelessWidget with WatchItMixin {
  const PodcastCardPlayButton({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) {
    final proxy = di<PodcastManager>().getOrCreateProxy(podcastItem);

    registerHandler(
      target: proxy.playEpisodesCommand.results,
      handler: (context, CommandResult<int, void>? result, cancel) {
        if (result == null) return;

        if (result.isRunning) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        } else if (result.isSuccess) {
          Navigator.of(context).pop();
        } else if (result.hasError) {
          Navigator.of(context).pop();
        }
      },
    );

    return FloatingActionButton.small(
      heroTag: 'podcastcardfap',
      onPressed: () => proxy.playEpisodesCommand(0),
      child: const Icon(Icons.play_arrow),
    );
  }
}
