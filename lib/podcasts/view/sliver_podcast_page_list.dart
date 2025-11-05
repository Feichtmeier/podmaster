import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../player/data/episode_media.dart';
import '../../player/player_manager.dart';
import '../podcast_library_service.dart';
import 'podcast_audio_tile.dart';

class SliverPodcastPageList extends StatelessWidget with WatchItMixin {
  const SliverPodcastPageList({
    super.key,
    required this.medias,
    required this.pageId,
  });

  final List<EpisodeMedia> medias;
  final String pageId;

  @override
  Widget build(BuildContext context) {
    final libraryModel = di<PodcastLibraryService>();
    final currentMedia = watchPropertyValue(
      (PlayerManager m) => m.currentMedia,
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate(childCount: medias.length, (
        context,
        index,
      ) {
        final episode = medias.elementAt(index);

        return PodcastAudioTile(
          key: ValueKey(episode.id),
          audio: episode,
          addPodcast: () async => libraryModel.addPodcast(
            feedUrl: episode.feedUrl,
            imageUrl: episode.artUrl,
            name: episode.title ?? '',
            artist: episode.artist ?? '',
          ),
          isExpanded: episode == currentMedia,
          selected: episode == currentMedia,
          startPlaylist: () =>
              di<PlayerManager>().setPlaylist(medias, index: index),
        );
      }),
    );
  }
}
