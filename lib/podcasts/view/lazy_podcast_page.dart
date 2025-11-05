import 'package:flutter/material.dart';
import 'package:podcast_search/podcast_search.dart';
import 'package:watch_it/watch_it.dart';

import '../../common/logging.dart';
import '../../common/view/no_search_result_page.dart';
import '../../extensions/build_context_x.dart';
import '../../player/data/episode_media.dart';
import '../podcast_library_service.dart';
import '../podcast_manager.dart';
import 'lazy_podcast_loading_page.dart';
import 'podcast_page.dart';

class LazyPodcastPage extends StatefulWidget with WatchItStatefulWidgetMixin {
  const LazyPodcastPage({
    super.key,
    this.podcastItem,
    this.feedUrl,
    this.imageUrl,
    required this.updateMessage,
    required this.multiUpdateMessage,
  });

  final Item? podcastItem;
  final String? feedUrl;
  final String? imageUrl;
  final String updateMessage;
  final String Function(int length) multiUpdateMessage;

  @override
  State<LazyPodcastPage> createState() => _LazyPodcastPageState();
}

class _LazyPodcastPageState extends State<LazyPodcastPage> {
  late Future<List<EpisodeMedia>?> _episodes;
  String? url;

  @override
  void initState() {
    super.initState();
    url = widget.feedUrl ?? widget.podcastItem?.feedUrl;
    if (url == null) {
      printMessageInDebugMode('checkupdates called without feedUrl or item!');
      _episodes = Future.value(<EpisodeMedia>[]);
    } else {
      _episodes = _findEpisodes(url!);
    }
  }

  Future<List<EpisodeMedia>?> _findEpisodes(String url) async {
    final podcastService = di<PodcastService>();
    final podcastLibraryService = di<PodcastLibraryService>();
    if (podcastLibraryService.isPodcastSubscribed(url) &&
        podcastService.getPodcastEpisodesFromCache(url) == null) {
      await podcastService.checkForUpdates(
        feedUrls: {url},
        updateMessage: widget.updateMessage,
        multiUpdateMessage: widget.multiUpdateMessage,
      );
    }

    final episodes = await podcastService.findEpisodes(feedUrl: url);
    await podcastLibraryService.removePodcastUpdate(url);

    return episodes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _episodes,
      builder: (context, snapshot) {
        final feedUrl = widget.feedUrl ?? widget.podcastItem?.feedUrl;
        final title =
            (feedUrl == null
                ? null
                : di<PodcastLibraryService>().getSubscribedPodcastName(
                    feedUrl,
                  )) ??
            widget.podcastItem?.collectionName ??
            widget.podcastItem?.trackName ??
            context.l10n.podcast;
        final imageUrl =
            widget.imageUrl ??
            widget.podcastItem?.artworkUrl600 ??
            widget.podcastItem?.artworkUrl ??
            snapshot.data?.first.artUrl;

        if (!snapshot.hasData) {
          return LazyPodcastLoadingPage(
            title: title,
            imageUrl: imageUrl,
            child: const Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        if (snapshot.hasError) {
          return LazyPodcastLoadingPage(
            title: title,
            imageUrl: imageUrl,
            child: NoSearchResultPage(message: Text(snapshot.error.toString())),
          );
        }

        final episodes = snapshot.data!;

        if (feedUrl == null || episodes.isEmpty) {
          return LazyPodcastLoadingPage(
            title: title,
            imageUrl: imageUrl,
            child: NoSearchResultPage(
              message: Text(context.l10n.podcastFeedIsEmpty),
            ),
          );
        }

        return PodcastPage(
          imageUrl: imageUrl,
          episodes: episodes,
          feedUrl: feedUrl,
          title: title,
        );
      },
    );
  }
}
