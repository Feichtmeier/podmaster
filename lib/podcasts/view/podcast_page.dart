import 'package:blur/blur.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:go_router/go_router.dart';
import 'package:podcast_search/podcast_search.dart';
import 'package:yaru/widgets.dart';

import '../../collection/view/collection_search_field.dart';
import '../../common/view/html_text.dart';
import '../../common/view/safe_network_image.dart';
import '../../common/view/sliver_sticky_panel.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../extensions/string_x.dart';
import '../../player/data/episode_media.dart';
import '../../player/view/player_view.dart';
import '../data/podcast_genre.dart';
import '../data/podcast_metadata.dart';
import '../podcast_manager.dart';
import 'podcast_favorite_button.dart';
import 'podcast_page_episode_list.dart';
import 'recent_downloads_button.dart';

class PodcastPage extends StatelessWidget with WatchItMixin {
  const PodcastPage({super.key, required this.feedUrl, this.podcastItem});

  final String feedUrl;
  final Item? podcastItem;

  static void go(BuildContext context, {EpisodeMedia? media, Item? item}) {
    if (media == null && item == null) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(context.l10n.noPodcastFound)));
      return;
    }

    final feedUrl = media?.feedUrl ?? item!.feedUrl!;

    context.go(
      '/podcast/${Uri.encodeComponent(feedUrl)}',
      extra:
          item ??
          Item(
            feedUrl: media!.feedUrl,
            artworkUrl: media.artUrl,
            collectionName: media.collectionName,
            artistName: media.artist,
            genre: media.genres.mapIndexed((i, e) => Genre(i, e)).toList(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showInfo = watchValue((PodcastManager m) => m.showInfo);

    final results = watchValue(
      (PodcastManager m) => m
          .getAndRunMetadataCommand(
            GetMetadataCapsule(feedUrl: feedUrl, item: podcastItem),
          )
          .results,
    );

    final isRunning = results.isRunning;
    final hasError = results.hasError;
    final error = results.error;

    final name = results.data?.name;
    final image = results.data?.imageUrl;
    final artist = results.data?.artist;
    final genres = results.data?.genreList;

    return Scaffold(
      appBar: YaruWindowTitleBar(
        leading: Center(
          child: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        title: Text(
          isRunning ? '...' : name?.unEscapeHtml ?? context.l10n.podcast,
        ),
        actions: [
          const Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kSmallPadding),
              child: RecentDownloadsButton(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PlayerView(),
      body: hasError
          ? Center(
              child: Text(error?.toString() ?? context.l10n.genericErrorTitle),
            )
          : CustomScrollView(
              slivers: [
                if (image != null)
                  SliverToBoxAdapter(
                    child: Material(
                      color: Colors.transparent,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Blur(
                            blur: 20,
                            colorOpacity: 0.7,
                            blurColor: const Color.fromARGB(255, 48, 48, 48),
                            child: SafeNetworkImage(
                              height: 350,
                              width: double.infinity,
                              url: image,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (!showInfo)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SafeNetworkImage(
                                height: 250,
                                width: 250,
                                url: image,
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                          if (showInfo) ...[
                            Positioned(
                              bottom: kMediumPadding,
                              left: kMediumPadding,
                              top: 55,
                              right: kMediumPadding,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SingleChildScrollView(
                                  child: HtmlText(
                                    wrapInFakeScroll: false,
                                    color: Colors.white,
                                    text:
                                        di<PodcastManager>()
                                            .getPodcastDescriptionFromCache(
                                              feedUrl,
                                            ) ??
                                        '',
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: kMediumPadding,
                              left: 50,
                              right: kMediumPadding,
                              child: SizedBox(
                                width: 400,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Wrap(
                                    children:
                                        genres
                                            ?.map(
                                              (e) => Padding(
                                                padding: const EdgeInsets.only(
                                                  right: kSmallPadding,
                                                ),
                                                child: Container(
                                                  height:
                                                      context
                                                          .theme
                                                          .buttonTheme
                                                          .height -
                                                      2,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal:
                                                            kMediumPadding,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          100,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      PodcastGenre.values
                                                              .firstWhereOrNull(
                                                                (v) =>
                                                                    v.name
                                                                        .toLowerCase() ==
                                                                    e.toLowerCase(),
                                                              )
                                                              ?.localize(
                                                                context.l10n,
                                                              ) ??
                                                          e,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList() ??
                                        [],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          Positioned(
                            top: kMediumPadding,
                            left: kMediumPadding,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: showInfo
                                    ? context.colorScheme.primary
                                    : Colors.black54,
                              ),
                              onPressed: () =>
                                  di<PodcastManager>().showInfo.value =
                                      !showInfo,
                              icon: Icon(
                                Icons.info,
                                color: showInfo
                                    ? context.colorScheme.onPrimary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverStickyPanel(
                  height: 80,
                  backgroundColor: context.theme.scaffoldBackgroundColor,
                  centerTitle: false,
                  controlPanel: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: PodcastFavoriteButton(
                      metadata: PodcastMetadata(
                        feedUrl: feedUrl,
                        imageUrl: image,
                        name: name,
                        artist: artist,
                      ),
                    ),
                    trailing: const ShowOnlyDownloadsButton(singleButton: true),
                    title: Text(
                      name?.unEscapeHtml ?? context.l10n.podcast,
                      style: context.textTheme.bodySmall,
                      overflow: TextOverflow.visible,
                      maxLines: 3,
                    ),
                    subtitle: Text(
                      artist?.unEscapeHtml ?? context.l10n.podcast,
                    ),
                  ),
                ),
                PodcastPageEpisodeList(feedUrl: feedUrl),
              ],
            ),
    );
  }
}
