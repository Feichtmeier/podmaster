import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../player/data/station_media.dart';
import '../../player/player_manager.dart';
import '../radio_manager.dart';
import 'radio_browser_station_star_button.dart';
import 'radio_host_not_connected_content.dart';
import 'remote_media_list_tile_image.dart';

class RadioFavoritesList extends StatelessWidget with WatchItMixin {
  const RadioFavoritesList({super.key});

  @override
  Widget build(BuildContext context) {
    callOnce((_) => di<RadioManager>().favoriteStationsCommand.run());
    return watchValue(
      (RadioManager s) => s.favoriteStationsCommand.results,
    ).toWidget(
      onData: (favorites, _) => ListView.builder(
        padding: const EdgeInsets.only(top: kBigPadding),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final media = favorites[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: kSmallPadding),
            child: _RadioFavoriteListTile(
              key: ValueKey(media.id),
              media: media,
            ),
          );
        },
      ),
      whileRunning: (_, _) =>
          const Center(child: CircularProgressIndicator.adaptive()),
      onError: (error, _, _) => RadioHostNotConnectedContent(
        message: 'Error: $error',
        onRetry: di<RadioManager>().favoriteStationsCommand.run,
      ),
    );
  }
}

class _RadioFavoriteListTile extends StatelessWidget with WatchItMixin {
  const _RadioFavoriteListTile({super.key, required this.media});

  final StationMedia media;

  @override
  Widget build(BuildContext context) {
    final isCurrentlyPlaying =
        watchStream(
          (PlayerManager p) =>
              p.currentMediaStream.map((e) => e?.id == media.id).distinct(),
          initialValue: di<PlayerManager>().currentMedia?.id == media.id,
          preserveState: false,
          allowStreamChange: true,
        ).data ??
        false;

    return ListTile(
      title: Text(media.title ?? context.l10n.stations),
      subtitle: Text(media.genres.take(5).join(', ')),
      minLeadingWidth: kDefaultTileLeadingDimension,
      leading: RemoteMediaListTileImage(media: media),
      trailing: RadioBrowserStationStarButton(media: media),
      selected: isCurrentlyPlaying,
      selectedColor: context.colorScheme.primary,
      onTap: () => di<PlayerManager>().setPlaylist([media]),
    );
  }
}
