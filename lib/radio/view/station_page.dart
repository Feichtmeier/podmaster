import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';

import '../../common/view/no_search_result_page.dart';
import '../../common/view/safe_network_image.dart';
import '../../common/view/sliver_sticky_panel.dart';
import '../../common/view/tap_able_text.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../online_art/online_art_model.dart';
import '../../player/data/station_media.dart';
import '../../player/player_manager.dart';
import '../../player/view/player_view.dart';
import '../../search/copy_to_clipboard_content.dart';
import '../radio_service.dart';
import 'radio_browser_station_star_button.dart';

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

class SliverRadioHistoryList extends StatelessWidget with WatchItMixin {
  const SliverRadioHistoryList({
    super.key,
    this.filter,
    this.emptyMessage,
    this.padding,
    this.emptyIcon,
    this.allowNavigation = true,
  });

  final String? filter;
  final Widget? emptyMessage;
  final Widget? emptyIcon;
  final EdgeInsetsGeometry? padding;
  final bool allowNavigation;

  @override
  Widget build(BuildContext context) {
    final length =
        watchStream(
          (RadioService m) => m.propertiesChanged.map(
            (_) =>
                di<RadioService>().filteredRadioHistory(filter: filter).length,
          ),
          initialValue: di<RadioService>()
              .filteredRadioHistory(filter: filter)
              .length,
          preserveState: false,
          allowStreamChange: true,
        ).data ??
        0;

    final current = watchStream(
      (RadioService m) => m.propertiesChanged.map((_) => m.mpvMetaData),
      initialValue: di<RadioService>().mpvMetaData,
      allowStreamChange: true,
      preserveState: false,
    ).data;

    if (length == 0) {
      return SliverToBoxAdapter(
        child: NoSearchResultPage(
          message: emptyMessage ?? Text(context.l10n.emptyHearingHistory),
        ),
      );
    }

    return SliverPadding(
      padding: padding ?? EdgeInsets.zero,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final reversedIndex = length - index - 1;
          final e = di<RadioService>()
              .filteredRadioHistory(filter: filter)
              .elementAt(reversedIndex);
          return RadioHistoryTile(
            icyTitle: e.key,
            selected:
                current?.icyTitle != null &&
                current?.icyTitle == e.value.icyTitle,
            allowNavigation: allowNavigation,
          );
        }, childCount: length),
      ),
    );
  }
}

enum _RadioHistoryTileVariant { regular, simple }

class RadioHistoryTile extends StatelessWidget with WatchItMixin {
  const RadioHistoryTile({
    super.key,
    required this.icyTitle,
    required this.selected,
    this.allowNavigation = true,
  }) : _variant = _RadioHistoryTileVariant.regular;

  const RadioHistoryTile.simple({
    super.key,
    required this.icyTitle,
    required this.selected,
    this.allowNavigation = false,
  }) : _variant = _RadioHistoryTileVariant.simple;

  final _RadioHistoryTileVariant _variant;
  final String icyTitle;
  final bool selected;
  final bool allowNavigation;

  @override
  Widget build(BuildContext context) {
    final icyName = watchStream(
      (RadioService m) =>
          m.propertiesChanged.map((e) => m.getMetadata(icyTitle)?.icyName),
      initialValue: di<RadioService>().getMetadata(icyTitle)?.icyName,
      preserveState: false,
      allowStreamChange: false,
    ).data;

    return switch (_variant) {
      _RadioHistoryTileVariant.simple => _SimpleRadioHistoryTile(
        key: ValueKey(icyTitle),
        icyTitle: icyTitle,
        selected: selected,
      ),
      _RadioHistoryTileVariant.regular => ListTile(
        key: ValueKey(icyTitle),
        selected: selected,
        selectedColor: context.theme.colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: kBigPadding),
        leading: RadioHistoryTileImage(
          key: ValueKey(icyTitle),
          icyTitle: icyTitle,
        ),
        title: TapAbleText(
          overflow: TextOverflow.visible,
          maxLines: 10,
          text: icyTitle,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: CopyClipboardContent(text: icyTitle)),
          ),
        ),
        subtitle: TapAbleText(text: icyName ?? context.l10n.station),
      ),
    };
  }
}

class _SimpleRadioHistoryTile extends StatelessWidget {
  const _SimpleRadioHistoryTile({
    super.key,
    required this.icyTitle,
    required this.selected,
  });

  final String icyTitle;
  final bool selected;

  @override
  Widget build(BuildContext context) => ListTile(
    selected: selected,
    selectedColor: context.theme.colorScheme.onSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: kBigPadding),
    leading: Visibility(visible: selected, child: const Text('>')),
    trailing: Visibility(visible: selected, child: const Text('<')),
    title: TapAbleText(
      overflow: TextOverflow.visible,
      maxLines: 10,
      text: icyTitle,
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: CopyClipboardContent(text: icyTitle))),
    ),
    subtitle: Text(
      di<RadioService>().getMetadata(icyTitle)?.icyName ?? context.l10n.station,
    ),
  );
}

class RadioHistoryTileImage extends StatelessWidget with WatchItMixin {
  const RadioHistoryTileImage({
    super.key,
    required this.icyTitle,
    this.height = kAudioTrackWidth,
    this.width = kAudioTrackWidth,
    this.fit,
  });

  final String? icyTitle;

  final double height, width;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final bR = BorderRadius.circular(4);
    final imageUrl = watchPropertyValue(
      (OnlineArtModel m) => m.getCover(icyTitle!),
    );

    return Tooltip(
      message: context.l10n.metadata,
      child: ClipRRect(
        borderRadius: bR,
        child: InkWell(
          borderRadius: bR,

          child: SizedBox(
            height: height,
            width: width,
            child: SafeNetworkImage(
              url: imageUrl,
              fallBackIcon: const Icon(Icons.radio),
              filterQuality: FilterQuality.medium,
              fit: fit ?? BoxFit.fitHeight,
            ),
          ),
        ),
      ),
    );
  }
}
