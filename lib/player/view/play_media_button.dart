import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../extensions/build_context_x.dart';
import '../data/unique_media.dart';
import '../player_manager.dart';

class PlayMediasButton extends StatelessWidget {
  const PlayMediasButton({super.key, required this.medias});

  final List<UniqueMedia> medias;

  @override
  Widget build(BuildContext context) => IconButton(
    style: IconButton.styleFrom(
      shape: const CircleBorder(),
      backgroundColor: context.theme.colorScheme.primaryContainer,
    ),
    onPressed: () {
      final player = di<PlayerManager>();
      if (player.isPlaying &&
          medias.any((media) => media.id == player.currentMedia?.id)) {
        player.pause();
      } else {
        if (medias.any((media) => media.id == player.currentMedia?.id)) {
          player.playOrPause();
        } else {
          player.setPlaylist(medias);
        }
      }
    },
    icon: _PlayPageIcon(medias),
  );
}

class _PlayPageIcon extends StatelessWidget with WatchItMixin {
  const _PlayPageIcon(this.medias);

  final List<UniqueMedia> medias;

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        watchStream(
          (PlayerManager p) => p.isPlayingStream,
          initialValue: di<PlayerManager>().isPlaying,
          preserveState: false,
          allowStreamChange: true,
        ).data ??
        false;

    final queueContainsCurrentMedia = medias.any(
      (media) => media.id == di<PlayerManager>().currentMedia?.id,
    );

    return Icon(
      isPlaying && queueContainsCurrentMedia ? Icons.pause : Icons.play_arrow,
    );
  }
}
