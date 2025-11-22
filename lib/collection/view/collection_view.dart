import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/media_type.dart';
import '../../podcasts/view/podcast_collection_view.dart';
import '../../radio/view/radio_favorites_list.dart';
import '../collection_manager.dart';

class CollectionView extends StatefulWidget with WatchItStatefulWidgetMixin {
  const CollectionView({super.key});

  @override
  State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ListenableSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: di<CollectionManager>().mediaTypeNotifier.value.index,
      length: MediaType.values.length,
      vsync: this,
    );
    _subscription = _tabController.listen((_) {
      if (_tabController.indexIsChanging) {
        di<CollectionManager>().mediaTypeNotifier.value =
            MediaType.values[_tabController.index];
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TabBar(
        controller: _tabController,
        tabs: MediaType.values
            .map((e) => Tab(text: e.localize(context)))
            .toList(),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: MediaType.values
              .map(
                (e) => switch (e) {
                  MediaType.podcast => const PodcastCollectionView(),
                  MediaType.radioStation => const RadioFavoritesList(),
                },
              )
              .toList(),
        ),
      ),
    ],
  );
}
