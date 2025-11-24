import 'package:podcast_search/podcast_search.dart';

import '../player/data/episode_media.dart';

extension PodcastX on Podcast {
  List<EpisodeMedia> toEpisodeMediaList(String url, Item? item) => episodes
      .where((e) => e.contentUrl != null)
      .map(
        (e) => EpisodeMedia(
          e.contentUrl!,
          episode: e,
          feedUrl: url,
          albumArtUrl: item?.artworkUrl600 ?? item?.artworkUrl ?? image,
          collectionName: title,
          artist: copyright,
          genres: [if (item?.primaryGenreName != null) item!.primaryGenreName!],
        ),
      )
      .toList();
}
