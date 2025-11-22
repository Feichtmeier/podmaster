import 'package:flutter/widgets.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/media_type.dart';
import '../../common/view/ui_constants.dart';
import '../../podcasts/view/podcast_search_view.dart';
import '../../radio/view/radio_browser.dart';
import '../search_manager.dart';
import 'search_field.dart';

class SearchView extends StatelessWidget with WatchItMixin {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final searchType = watchValue((SearchManager m) => m.searchTypeNotifier);
    return Column(
      spacing: kMediumPadding,
      children: [
        const SearchField(),
        Expanded(
          child: switch (searchType) {
            MediaType.podcast => const PodcastSearchViewNew(),
            MediaType.radioStation => const RadioBrowser(),
          }, // Placeholder for search results
        ),
      ],
    );
  }
}
