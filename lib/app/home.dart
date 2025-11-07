import 'package:flutter/material.dart';

import '../extensions/build_context_x.dart';
import '../player/view/player_view.dart';
import '../podcasts/view/podcast_collection_view.dart';
import '../podcasts/view/podcast_search_view.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: TabBar(
          tabs: [
            Tab(text: context.l10n.search),
            Tab(text: context.l10n.collection),
          ],
        ),
      ),
      body: const TabBarView(
        children: [PodcastSearchViewNew(), PodcastCollectionView()],
      ),
      bottomNavigationBar: const PlayerView(),
    ),
  );
}
