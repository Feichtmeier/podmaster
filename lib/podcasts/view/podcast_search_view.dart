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
  Widget build(BuildContext context) => Column(
    spacing: 8,
    children: [
      const PodcastSearchViewHeader(),
      Expanded(
        child: watchValue((PodcastManager m) => m.updateSearchCommand.results)
            .toWidget(
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
              whileExecuting: (res, query) =>
                  const Center(child: CircularProgressIndicator.adaptive()),
            ),
      ),
    ],
  );
}

class PodcastSearchViewHeader extends StatefulWidget {
  const PodcastSearchViewHeader({super.key});

  @override
  State<PodcastSearchViewHeader> createState() =>
      _PodcastSearchViewHeaderState();
}

class _PodcastSearchViewHeaderState extends State<PodcastSearchViewHeader> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = di<PodcastManager>().textChangedCommand.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: TextField(
      controller: _controller,
      onChanged: di<PodcastManager>().textChangedCommand.execute,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        label: Text(context.l10n.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _controller.clear();
            di<PodcastManager>().textChangedCommand.execute('');
          },
        ),
      ),
    ),
  );
}
