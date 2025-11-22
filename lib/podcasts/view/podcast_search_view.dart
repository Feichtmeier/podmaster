import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../../common/view/no_search_result_page.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../podcast_manager.dart';
import 'podcast_card.dart';

class PodcastSearchViewNew extends StatelessWidget with WatchItMixin {
  const PodcastSearchViewNew({super.key});

  @override
  Widget build(BuildContext context) =>
      watchValue((PodcastManager m) => m.updateSearchCommand.results).toWidget(
        onData: (result, param) => result.items.isEmpty
            ? NoSearchResultPage(message: Text(context.l10n.nothingFound))
            : GridView.builder(
                itemCount: result.items.length,
                padding: kGridViewPadding,
                gridDelegate: kGridViewDelegate,
                itemBuilder: (context, index) => PodcastCard(
                  key: ValueKey(result.items.elementAt(index).feedUrl),
                  podcastItem: result.items.elementAt(index),
                ),
              ),
        onError: (error, lastResult, param) =>
            NoSearchResultPage(message: Text(error.toString())),
        whileRunning: (res, query) =>
            const Center(child: CircularProgressIndicator.adaptive()),
      );
}
