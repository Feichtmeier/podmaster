import '../../player/data/episode_media.dart';

class DownloadCapsule {
  const DownloadCapsule({
    required this.media,
    required this.canceledMessage,
    required this.finishedMessage,
    required this.downloadsDir,
  });

  final EpisodeMedia media;
  final String canceledMessage;
  final String finishedMessage;
  final String downloadsDir;
}
