import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';

import '../../common/view/safe_network_image.dart';
import '../../common/view/sliver_sticky_panel.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../player/data/station_media.dart';
import '../../player/view/play_media_button.dart';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (stationMedia.artUrl != null)
                      Blur(
                        blur: 20,
                        colorOpacity: 0.7,
                        blurColor: const Color.fromARGB(255, 48, 48, 48),
                        child: SafeNetworkImage(
                          height: 350,
                          width: double.infinity,
                          url: stationMedia.artUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SafeNetworkImage(
                        height: 250,
                        width: 250,
                        url: stationMedia.artUrl,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ],
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
        SliverStickyPanel(
          controlPanel: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: kSmallPadding,
            children: [
              RadioBrowserStationStarButton(media: stationMedia),
              PlayMediasButton(medias: [stationMedia]),
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
