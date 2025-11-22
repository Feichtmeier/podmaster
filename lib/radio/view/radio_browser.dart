import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../player/player_manager.dart';
import '../radio_manager.dart';
import 'radio_browser_station_star_button.dart';
import 'radio_host_not_connected_content.dart';
import 'remote_media_list_tile_image.dart';

class RadioBrowser extends StatelessWidget with WatchItMixin {
  const RadioBrowser({super.key});

  @override
  Widget build(BuildContext context) =>
      watchValue((RadioManager s) => s.updateSearchCommand.results).toWidget(
        whileRunning: (lastResult, param) =>
            const Center(child: CircularProgressIndicator.adaptive()),
        onError: (error, param, lastResult) => RadioHostNotConnectedContent(
          message: 'Error: $error',
          onRetry: di<RadioManager>().updateSearchCommand.run,
        ),
        onData: (data, param) => ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final media = data[index];
            return ListTile(
              key: ValueKey(media.id),
              title: Text(media.title ?? context.l10n.stations),
              minLeadingWidth: kDefaultTileLeadingDimension,
              leading: RemoteMediaListTileImage(media: media),
              subtitle: Text(media.genres.take(5).toList().join(', ')),
              onTap: () => di<PlayerManager>().setPlaylist([media]),
              trailing: RadioBrowserStationStarButton(media: media),
            );
          },
        ),
      );
}
