import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/view/html_text.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../extensions/date_time_x.dart';
import '../../extensions/duration_x.dart';
import '../../extensions/string_x.dart';
import '../../player/data/episode_media.dart';
import '../../player/player_manager.dart';
import '../data/podcast_metadata.dart';
import '../podcast_manager.dart';
import 'download_button.dart';

class EpisodeTile extends StatelessWidget with WatchItMixin {
  const EpisodeTile({
    super.key,
    required this.episode,
    required this.setPlaylist,
    this.podcastImage,
  });

  final EpisodeMedia episode;
  final String? podcastImage;
  final VoidCallback setPlaylist;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final currentMedia = watchStream(
      (PlayerManager m) => m.currentMediaStream,
      initialValue: di<PlayerManager>().currentMedia,
    ).data;

    final selected = currentMedia?.id == episode.id;

    final isPlaying =
        watchStream(
          (PlayerManager p) => p.isPlayingStream,
          initialValue: di<PlayerManager>().isPlaying,
          preserveState: false,
        ).data ??
        false;

    void onPressed() {
      if (isPlaying && selected) {
        di<PlayerManager>().pause();
      } else {
        if (selected) {
          di<PlayerManager>().playOrPause();
        } else {
          setPlaylist();
        }
      }
    }

    return ExpansionTile(
      key: ValueKey(episode.id),
      initiallyExpanded: selected,
      textColor: selected ? theme.colorScheme.primary : null,
      collapsedTextColor: selected ? theme.colorScheme.primary : null,
      title: Row(
        spacing: 4,
        children: [
          IconButton.filled(
            onPressed: onPressed,
            icon: Icon(
              isPlaying && selected ? Icons.pause : Icons.play_arrow,
              color: selected ? theme.colorScheme.primary : null,
            ),
          ),
          Expanded(child: Text(episode.title?.unEscapeHtml ?? 'No Title')),
        ],
      ),
      children: <Widget>[
        ListTile(
          selected: selected,
          title: Row(
            spacing: kSmallPadding,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${episode.creationDateTime!.unixTimeToDateString} · ${episode.duration?.formattedTime ?? 'Unknown duration'}',
              ),
              DownloadButton(
                episode: episode,
                addPodcast: () => di<PodcastManager>().addPodcast(
                  PodcastMetadata(
                    feedUrl: episode.feedUrl,
                    imageUrl: podcastImage,
                    artist: episode.artist ?? '',
                    name: episode.collectionName ?? '',
                    genreList: episode.genres,
                  ),
                ),
              ),
            ],
          ),
          titleTextStyle: theme.textTheme.labelSmall,
          subtitle: HtmlText(text: episode.description ?? 'No Description'),
          leading: const SizedBox(width: 20),

          onTap: onPressed,
        ),
      ],
    );
  }
}
