import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:yaru/yaru.dart';

import '../../player/data/unique_media.dart';
import '../../player/player_manager.dart';
import '../radio_manager.dart';

class RadioBrowserStationStarButton extends StatelessWidget with WatchItMixin {
  const RadioBrowserStationStarButton({super.key, required this.media});

  final UniqueMedia media;

  @override
  Widget build(BuildContext context) {
    final isFavorite = watchValue(
      (RadioManager s) => s.getFavoriteStationsCommand.select(
        (favorites) => favorites.any((m) => m.id == media.id),
      ),
    );

    // Error handler for favorite toggle
    registerHandler(
      select: (RadioManager m) => m.toggleFavoriteStationCommand.errors,
      handler: (context, error, cancel) {
        if (error != null && error.error is! UndoException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update favorite: ${error.error}'),
            ),
          );
        }
      },
    );

    return IconButton(
      onPressed: () =>
          di<RadioManager>().toggleFavoriteStationCommand.run(media.id),
      icon: Icon(isFavorite ? YaruIcons.star_filled : YaruIcons.star),
    );
  }
}

class RadioStationStarButton extends StatelessWidget with WatchItMixin {
  const RadioStationStarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currentMedia = watchStream(
      (PlayerManager p) => p.currentMediaStream,
      initialValue: di<PlayerManager>().currentMedia,
      preserveState: false,
    ).data;
    final isFavorite = watchValue(
      (RadioManager s) => s.getFavoriteStationsCommand.select(
        (favorites) => favorites.any((m) => m.id == currentMedia?.id),
      ),
    );

    // Error handler for favorite toggle
    registerHandler(
      select: (RadioManager m) => m.toggleFavoriteStationCommand.errors,
      handler: (context, error, cancel) {
        if (error != null && error.error is! UndoException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update favorite: ${error.error}'),
            ),
          );
        }
      },
    );

    return IconButton(
      onPressed: currentMedia == null
          ? null
          : () => di<RadioManager>().toggleFavoriteStationCommand.run(
              currentMedia.id,
            ),
      icon: Icon(isFavorite ? YaruIcons.star_filled : YaruIcons.star),
    );
  }
}
