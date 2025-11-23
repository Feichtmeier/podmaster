import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../extensions/build_context_x.dart';
import '../../player/data/episode_media.dart';
import '../../settings/settings_manager.dart';
import '../data/download_capsule.dart';
import '../download_manager.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    required this.episode,
    required this.addPodcast,
  });

  final EpisodeMedia episode;
  final void Function()? addPodcast;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      _DownloadProgress(url: episode.url),
      _ProcessDownloadButton(episode: episode, addPodcast: addPodcast),
    ],
  );
}

class _ProcessDownloadButton extends StatelessWidget with WatchItMixin {
  const _ProcessDownloadButton({required this.episode, this.addPodcast});

  final EpisodeMedia episode;
  final void Function()? addPodcast;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final isDownloaded = watchPropertyValue(
      (DownloadManager m) => m.isDownloaded(episode.url),
    );

    final downloadsDir = watchValue(
      (SettingsManager m) => m.downloadsDirCommand,
    );
    return IconButton(
      isSelected: isDownloaded,
      tooltip: isDownloaded
          ? context.l10n.removeDownloadEpisode
          : context.l10n.downloadEpisode,
      icon: Icon(
        isDownloaded ? Icons.download_done : Icons.download_outlined,
        color: isDownloaded ? theme.colorScheme.primary : null,
      ),
      onPressed: downloadsDir == null
          ? null
          : () {
              if (isDownloaded) {
                di<DownloadManager>().deleteDownload(media: episode);
              } else {
                addPodcast?.call();
                di<DownloadManager>().startOrCancelDownload(
                  DownloadCapsule(
                    finishedMessage: context.l10n.downloadFinished(
                      episode.title ?? '',
                    ),
                    canceledMessage: context.l10n.downloadCancelled(
                      episode.title ?? '',
                    ),
                    media: episode,
                    downloadsDir: downloadsDir,
                  ),
                );
              }
            },
      color: isDownloaded
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface,
    );
  }
}

class _DownloadProgress extends StatelessWidget with WatchItMixin {
  const _DownloadProgress({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final value = watchPropertyValue((DownloadManager m) => m.getProgress(url));
    return SizedBox.square(
      dimension: (context.theme.buttonTheme.height / 2 * 2) - 3,
      child: CircularProgressIndicator(
        padding: EdgeInsets.zero,
        value: value == null || value == 1.0 ? 0 : value,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
