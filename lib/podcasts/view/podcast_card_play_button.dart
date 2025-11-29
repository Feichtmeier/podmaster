import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';

import '../podcast_manager.dart';

class PodcastCardPlayButton extends StatelessWidget with WatchItMixin {
  const PodcastCardPlayButton({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
    heroTag: 'podcastcardfap',
    onPressed: () => di<PodcastManager>()
        .getOrCreatePlayCommand(podcastItem.feedUrl!)
        .run(0),
    child: const Icon(Icons.play_arrow),
  );
}
