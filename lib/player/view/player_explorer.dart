import 'package:flutter/material.dart';

import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import 'player_queue.dart';

class PlayerExplorer extends StatefulWidget {
  const PlayerExplorer({super.key});

  @override
  State<PlayerExplorer> createState() => _PlayerExplorerState();
}

class _PlayerExplorerState extends State<PlayerExplorer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kBigPadding),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.queue),
              Tab(text: l10n.explore),
              Tab(text: l10n.favorites),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const PlayerQueue(),
                Center(child: Text(context.l10n.explore)),
                Center(child: Text(context.l10n.favorites)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
