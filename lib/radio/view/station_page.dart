import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';

import '../../common/view/safe_network_image.dart';
import '../../common/view/sliver_sticky_panel.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../player/data/station_media.dart';
import '../../player/player_manager.dart';
import '../../player/view/player_view.dart';
import '../../search/copy_to_clipboard_content.dart';
import '../radio_service.dart';
import 'radio_browser_station_star_button.dart';
import 'sliver_radio_history_list.dart';

class StationPage extends StatelessWidget {
  const StationPage({
    super.key,
    required this.uuid,
    required this.stationMedia,
  });

  final String uuid;
  final StationMedia stationMedia;

  static void go(BuildContext context, {required StationMedia media}) =>
      context.go('/station/${Uri.encodeComponent(media.id)}', extra: media);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: YaruWindowTitleBar(
      border: BorderSide.none,
      leading: Center(
        child: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      title: Text(stationMedia.title),
    ),
    bottomNavigationBar: const PlayerView(),
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(kBigPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 200,
                    width: 200,
                    child: SafeNetworkImage(
                      url: stationMedia.artUrl,
                      fallBackIcon: const Icon(Icons.radio),
                      filterQuality: FilterQuality.medium,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: kBigPadding),
                Text(
                  stationMedia.title,
                  style: context.theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SliverStickyPanel(
          controlPanel: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: kSmallPadding,
            children: [
              RadioBrowserStationStarButton(media: stationMedia),
              IconButton(
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: context.theme.colorScheme.primaryContainer,
                ),
                onPressed: () =>
                    di<PlayerManager>().setPlaylist([stationMedia]),
                icon: const Icon(Icons.play_arrow),
              ),
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: CopyClipboardContent(
                      text: di<RadioService>().getRadioHistoryList(
                        filter: stationMedia.title,
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
        ),
        SliverRadioHistoryList(
          filter: stationMedia.title.toLowerCase(),
          emptyMessage: const Text(''),
          emptyIcon: const Icon(Icons.radio),
          padding: const EdgeInsets.all(kBigPadding),
          allowNavigation: false,
        ),
      ],
    ),
  );
}
