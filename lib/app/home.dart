import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:yaru/yaru.dart';

import '../collection/view/collection_view.dart';
import '../common/view/ui_constants.dart';
import '../extensions/build_context_x.dart';
import '../player/view/player_view.dart';
import '../podcasts/view/recent_downloads_button.dart';
import '../search/view/search_view.dart';
import '../settings/view/settings_dialog.dart';

final _selectedHomeTabIndex = ValueNotifier<int>(0);

class Home extends StatelessWidget with WatchItMixin {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    registerStreamHandler<Stream<CommandError>, CommandError>(
      target: Command.globalErrors,
      handler: (context, snapshot, cancel) {
        if (snapshot.hasData) {
          final error = snapshot.data!;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text('Download error: ${error.error}')),
          );
        }
      },
    );

    return ValueListenableBuilder(
      valueListenable: _selectedHomeTabIndex,
      builder: (context, value, child) {
        return DefaultTabController(
          length: 2,
          initialIndex: value,
          child: Scaffold(
            appBar: YaruWindowTitleBar(
              border: BorderSide.none,
              titleSpacing: 0,
              title: SizedBox(
                width: 450,
                child: TabBar(
                  onTap: (index) => _selectedHomeTabIndex.value = index,
                  tabs: [
                    Tab(text: context.l10n.search),
                    Tab(text: context.l10n.collection),
                  ],
                ),
              ),
              actions:
                  [
                        const RecentDownloadsButton(),
                        IconButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => const SettingsDialog(),
                          ),
                          icon: const Icon(Icons.settings),
                        ),
                      ]
                      .map(
                        (e) => Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSmallPadding,
                            ),
                            child: e,
                          ),
                        ),
                      )
                      .toList(),
            ),
            body: const TabBarView(children: [SearchView(), CollectionView()]),
            bottomNavigationBar: const PlayerView(),
          ),
        );
      },
    );
  }
}
