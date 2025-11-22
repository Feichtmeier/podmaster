import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/media_type.dart';
import '../../podcasts/view/podcast_collection_view.dart';
import '../../radio/view/radio_favorites_list.dart';
import '../collection_manager.dart';
import 'collection_search_field.dart';

class CollectionView extends StatelessWidget with WatchItMixin {
  const CollectionView({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const CollectionSearchField(),
      Expanded(
        child: switch (watchValue(
          (CollectionManager s) => s.mediaTypeNotifier,
        )) {
          MediaType.podcast => const PodcastCollectionView(),
          MediaType.radioStation => const RadioFavoritesList(),
        },
      ),
    ],
  );
}
