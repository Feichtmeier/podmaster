import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:yaru/yaru.dart';

import '../collection/view/collection_view.dart';
import '../common/view/ui_constants.dart';
import '../extensions/build_context_x.dart';
import '../player/player_manager.dart';
import '../player/view/player_full_view.dart';
import '../player/view/player_view.dart';
import '../podcasts/download_manager.dart';
import '../search/view/search_view.dart';
import '../settings/view/settings_dialog.dart';

class Home extends StatelessWidget with WatchItMixin {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    registerStreamHandler(
      select: (DownloadManager m) => m.messageStream,
      handler: downloadMessageStreamHandler,
    );

    final playerFullWindowMode = watchValue(
      (PlayerManager m) => m.playerViewState.select((e) => e.fullMode),
    );

    if (playerFullWindowMode) return const PlayerFullView();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: YaruWindowTitleBar(
          border: BorderSide.none,
          titleSpacing: 0,
          title: SizedBox(
            width: 450,
            child: TabBar(
              tabs: [
                Tab(text: context.l10n.search),
                Tab(text: context.l10n.collection),
              ],
            ),
          ),
          actions: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSmallPadding),
                child: IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const SettingsDialog(),
                  ),
                  icon: const Icon(Icons.settings),
                ),
              ),
            ),
          ],
        ),
        body: const TabBarView(children: [SearchView(), CollectionView()]),
        bottomNavigationBar: const PlayerView(),
      ),
    );
  }
}
