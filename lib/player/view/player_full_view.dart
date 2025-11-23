import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:yaru/yaru.dart';

import '../../common/view/theme.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../player_manager.dart';
import 'player_album_art.dart';
import 'player_control_mixin.dart';
import 'player_explorer.dart';
import 'player_track_info.dart';
import 'player_view.dart';

class PlayerFullView extends StatelessWidget
    with WatchItMixin, PlayerControlMixin {
  const PlayerFullView({super.key});

  @override
  Widget build(BuildContext context) {
    final showPlayerExplorer = watchValue(
      (PlayerManager m) =>
          m.playerViewState.select((e) => e.showPlayerExplorer),
    );

    final isVideo =
        watchStream(
          (PlayerManager p) => p.isVideoStream,
          initialValue: di<PlayerManager>().isVideo,
          preserveState: false,
        ).data ??
        false;

    final media = watchStream(
      (PlayerManager p) => p.currentMediaStream,
      initialValue: di<PlayerManager>().currentMedia,
      preserveState: false,
    ).data;

    final color =
        watchValue(
          (PlayerManager p) => p.playerViewState.select((e) => e.color),
        ) ??
        context.colorScheme.primary;

    final isPortrait = !context.showSideBar;

    final theme = context.theme;
    final colorScheme = context.colorScheme;

    final iconColor = getPlayerIconColor(theme);

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: theme.colorScheme.isLight
              ? color.scale(lightness: -0.3, saturation: 0.3)
              : color.scale(lightness: 0.5, saturation: 0.3),
          outline: iconColor,
        ),
        textSelectionTheme: theme.textSelectionTheme.copyWith(
          cursorColor: color,
          selectionColor: color.withAlpha(100),
          selectionHandleColor: color,
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: getPlayerBg(
          theme,
          color,
          saturation: colorScheme.isLight ? -0.8 : -0.6,
        ),
      ),

      child: Scaffold(
        appBar: YaruWindowTitleBar(
          title: Text('Media Player', style: TextStyle(color: iconColor)),
          backgroundColor: Colors.transparent,
          border: BorderSide.none,
          actions: [
            IconButton(
              icon: Icon(Icons.arrow_downward, color: iconColor),
              onPressed: () => togglePlayerFullMode(context),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                isSelected: showPlayerExplorer,
                icon: Icon(
                  showPlayerExplorer
                      ? Icons.view_sidebar
                      : Icons.view_sidebar_outlined,
                  color: iconColor,
                ),
                onPressed: () => di<PlayerManager>().updateState(
                  showPlayerExplorer: !showPlayerExplorer,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isVideo ? null : const PlayerView(),
        body: Row(
          children: [
            if (!isPortrait || (isPortrait && !showPlayerExplorer))
              if (isVideo)
                Expanded(
                  flex: 2,
                  child: Video(controller: di<PlayerManager>().videoController),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerAlbumArt(
                          media: media,
                          dimension: 300,
                          fit: BoxFit.fitHeight,
                        ),
                        if (isPortrait ||
                            (!isPortrait && !showPlayerExplorer)) ...[
                          const SizedBox(height: kBigPadding),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kBigPadding,
                            ),
                            child: PlayerTrackInfo(
                              textColor: iconColor,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              artistStyle: context.textTheme.bodyMedium,
                              titleStyle: context.textTheme.bodyLarge,
                              durationStyle: context.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            if (showPlayerExplorer) const Expanded(child: PlayerExplorer()),
          ],
        ),
      ),
    );
  }
}
