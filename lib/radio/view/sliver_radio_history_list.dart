import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/view/no_search_result_page.dart';
import '../../extensions/build_context_x.dart';
import '../radio_service.dart';
import 'radio_history_tile.dart';

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
