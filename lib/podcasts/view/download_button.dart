import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';
import '../../extensions/build_context_x.dart';
import '../../player/data/episode_media.dart';
import '../../settings/settings_manager.dart';
import '../download_manager.dart';
import '../podcast_library_service.dart';

class DownloadButton extends StatelessWidget with WatchItMixin {
  const DownloadButton({
    super.key,
    this.iconSize,
    required this.audio,
    required this.addPodcast,
  });

  final double? iconSize;
  final EpisodeMedia? audio;
  final void Function()? addPodcast;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final manager = di<DownloadManager>();
    final value = watchPropertyValue(
      (DownloadManager m) => m.getValue(audio?.url),
    );

    final download =
        watchStream(
          (PodcastLibraryService m) => m.propertiesChanged
              .map((_) => m.getDownload(audio?.url) != null)
              .distinct(),
          initialValue:
              di<PodcastLibraryService>().getDownload(audio?.url) != null,
          preserveState: false,
        ).data ??
        false;

    final downloadsDir = watchPropertyValue(
      (SettingsManager m) => m.downloadsDir,
    );

    final radius = theme.buttonTheme.height / 2;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: (radius * 2) - 3,
          child: CircularProgressIndicator(
            padding: EdgeInsets.zero,
            value: value == null || value == 1.0 ? 0 : value,
            backgroundColor: Colors.transparent,
          ),
        ),
        IconButton(
          isSelected: download,
          tooltip: download
              ? context.l10n.removeDownloadEpisode
              : context.l10n.downloadEpisode,
          icon: Icon(
            download ? Icons.download_done : Icons.download_outlined,
            color: download ? theme.colorScheme.primary : null,
          ),
          onPressed: downloadsDir == null
              ? null
              : () {
                  if (download) {
                    manager.deleteDownload(audio: audio);
                  } else {
                    addPodcast?.call();
                    manager.startDownload(
                      finishedMessage: context.l10n.downloadFinished(
                        audio?.title ?? '',
                      ),
                      canceledMessage: context.l10n.downloadCancelled(
                        audio?.title ?? '',
                      ),
                      media: audio,
                    );
                  }
                },
          iconSize: iconSize,
          color: download
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ],
    );
  }
}
