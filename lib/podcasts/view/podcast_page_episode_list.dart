import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:podcast_search/podcast_search.dart';
import '../../player/player_manager.dart';
import '../podcast_library_service.dart';
import '../podcast_manager.dart';
import 'download_button.dart';

class PodcastPageEpisodeList extends StatelessWidget with WatchItMixin {
  const PodcastPageEpisodeList({super.key, required this.podcastItem});

  final Item podcastItem;

  @override
  Widget build(BuildContext context) {
    callOnce(
      (context) => di<PodcastManager>().fetchEpisodeMediaCommand(podcastItem),
    );

    final currentMedia = watchStream(
      (PlayerManager m) => m.currentMediaStream,
      initialValue: di<PlayerManager>().currentMedia,
    ).data;

    final isPlaying =
        watchStream(
          (PlayerManager p) => p.isPlayingStream,
          initialValue: di<PlayerManager>().isPlaying,
          preserveState: false,
        ).data ??
        false;

    return watchValue(
      (PodcastManager m) => m.fetchEpisodeMediaCommand.results,
    ).toWidget(
      onData: (episodes, param) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: episodes.length,

        itemBuilder: (context, index) {
          final episode = episodes[index];
          final selected = currentMedia?.id == episode.id;
          void onPressed() {
            if (isPlaying && selected) {
              di<PlayerManager>().pause();
            } else {
              if (selected) {
                di<PlayerManager>().playOrPause();
              } else {
                di<PlayerManager>().setPlaylist(episodes, index: index);
              }
            }
          }

          return ExpansionTile(
            initiallyExpanded: selected,
            textColor: selected ? Theme.of(context).colorScheme.primary : null,
            collapsedTextColor: selected
                ? Theme.of(context).colorScheme.primary
                : null,
            title: Row(
              spacing: 4,
              children: [
                IconButton.filled(
                  onPressed: onPressed,
                  icon: Icon(
                    isPlaying && selected ? Icons.pause : Icons.play_arrow,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                Expanded(child: Text(episode.title ?? 'No Title')),
              ],
            ),

            children: <Widget>[
              ListTile(
                selectedColor: Theme.of(context).colorScheme.primary,
                selected: selected,
                subtitle: Text(episode.description ?? 'No Description'),
                leading: const SizedBox(width: 20),
                trailing: DownloadButton(
                  audio: episode,
                  addPodcast: () => di<PodcastLibraryService>().addPodcast(
                    feedUrl: episode.feedUrl,
                    imageUrl: episode.artUrl,
                    artist: episode.artist ?? '',
                    name: episode.collectionName ?? '',
                  ),
                ),
                onTap: onPressed,
              ),
            ],
          );
        },
      ),
      onError: (error, lastResult, param) =>
          Center(child: Text('Error loading episodes: $error')),
      whileExecuting: (res, query) =>
          const Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
