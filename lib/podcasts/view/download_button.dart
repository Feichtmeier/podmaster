import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../extensions/build_context_x.dart';
import '../../player/data/episode_media.dart';
import '../data/podcast_metadata.dart';
import '../download_service.dart';
import '../podcast_manager.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({super.key, required this.episode});

  final EpisodeMedia episode;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      _DownloadProgress(episode: episode),
      _ProcessDownloadButton(episode: episode),
    ],
  );
}

class _ProcessDownloadButton extends StatelessWidget with WatchItMixin {
  const _ProcessDownloadButton({required this.episode});

  final EpisodeMedia episode;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final progress = watch(episode.downloadCommand.progress).value;
    final isDownloaded = progress == 1.0;

    final isRunning = watch(episode.downloadCommand.isRunning).value;

    return IconButton(
      isSelected: isDownloaded,
      tooltip: isDownloaded
          ? context.l10n.removeDownloadEpisode
          : context.l10n.downloadEpisode,
      icon: Icon(
        isDownloaded ? Icons.download_done : Icons.download_outlined,
        color: isDownloaded ? theme.colorScheme.primary : null,
      ),
      onPressed: () {
        if (isDownloaded) {
          di<DownloadService>().deleteDownload(media: episode);
          episode.downloadCommand.resetProgress();
        } else if (isRunning) {
          episode.downloadCommand.cancel();
        } else {
          // Add podcast to library before downloading
          di<PodcastManager>().addPodcast(
            PodcastMetadata(
              feedUrl: episode.feedUrl,
              imageUrl: episode.albumArtUrl,
              name: episode.collectionName,
              artist: episode.artist,
              genreList: episode.genres,
            ),
          );
          episode.downloadCommand.run();
        }
      },
      color: isDownloaded
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface,
    );
  }
}

class _DownloadProgress extends StatelessWidget with WatchItMixin {
  const _DownloadProgress({required this.episode});

  final EpisodeMedia episode;

  @override
  Widget build(BuildContext context) {
    final progress = watch(episode.downloadCommand.progress).value;

    return SizedBox.square(
      dimension: (context.theme.buttonTheme.height / 2 * 2) - 3,
      child: CircularProgressIndicator(
        padding: EdgeInsets.zero,
        value: progress > 0 && progress < 1.0 ? progress : null,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
