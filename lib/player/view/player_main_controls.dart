import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:media_kit/media_kit.dart';

import '../../common/view/ui_constants.dart';
import '../player_manager.dart';

class PlayerMainControls extends StatelessWidget {
  const PlayerMainControls({
    super.key,
    required this.iconColor,
    required this.selectedColor,
  });

  final Color iconColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kMediumPadding,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlayerShuffleButton(iconColor: iconColor, selectedColor: selectedColor),
        IconButton(
          style: playerButtonStyle,
          icon: Icon(Icons.skip_previous, color: iconColor),
          onPressed: di<PlayerManager>().skipToPrevious,
        ),
        PlayerIsPlayingButton(iconColor: iconColor),
        IconButton(
          style: playerButtonStyle,
          icon: Icon(Icons.skip_next, color: iconColor),
          onPressed: di<PlayerManager>().skipToNext,
        ),
        PlayerPlaylistModeButton(
          iconColor: iconColor,
          selectedColor: selectedColor,
        ),
      ],
    );
  }
}

class PlayerShuffleButton extends StatelessWidget with WatchItMixin {
  const PlayerShuffleButton({
    super.key,
    required this.iconColor,
    required this.selectedColor,
  });

  final Color iconColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final shuffle = watchValue((PlayerManager p) => p.shuffle);
    return IconButton(
      style: playerButtonStyle,
      icon: Icon(Icons.shuffle, color: shuffle ? selectedColor : iconColor),
      onPressed: () => di<PlayerManager>().toggleShuffle(),
    );
  }
}

class PlayerPlaylistModeButton extends StatelessWidget with WatchItMixin {
  const PlayerPlaylistModeButton({
    super.key,
    required this.iconColor,
    required this.selectedColor,
  });

  final Color iconColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final playlistMode = watchStream(
      (PlayerManager p) => p.playlistModeStream,
      initialValue: di<PlayerManager>().playlistMode,
      preserveState: true,
    ).data;

    return IconButton(
      style: playerButtonStyle,
      icon: Icon(
        switch (playlistMode) {
          PlaylistMode.single => Icons.repeat_one,
          _ => Icons.repeat,
        },
        color: switch (playlistMode) {
          PlaylistMode.single || PlaylistMode.loop => selectedColor,
          _ => iconColor,
        },
      ),
      onPressed: () => di<PlayerManager>().changePlaylistMode(),
    );
  }
}

class PlayerIsPlayingButton extends StatelessWidget with WatchItMixin {
  const PlayerIsPlayingButton({super.key, required this.iconColor});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isPlaying = watchStream(
      (PlayerManager p) => p.isPlayingStream,
      initialValue: di<PlayerManager>().isPlaying,
      preserveState: true,
    ).data;

    return IconButton(
      style: playerButtonStyle,
      icon: Icon(
        isPlaying == true ? Icons.pause : Icons.play_arrow,
        color: iconColor,
      ),
      onPressed: di<PlayerManager>().playOrPause,
    );
  }
}
