import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/view/safe_network_image.dart';
import '../../common/view/tap_able_text.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../online_art/online_art_model.dart';
import '../../search/copy_to_clipboard_content.dart';
import '../radio_service.dart';

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
