import 'package:podcast_search/podcast_search.dart';

class PodcastMetadata {
  const PodcastMetadata({
    required this.feedUrl,
    this.imageUrl,
    this.name,
    this.artist,
    this.genreList,
  });

  final String feedUrl;
  final String? imageUrl;
  final String? name;
  final String? artist;
  final List<String>? genreList;

  factory PodcastMetadata.fromItem(Item item) {
    if (item.feedUrl == null) {
      throw ArgumentError('Item must have a valid, non null feedUrl!');
    }
    return PodcastMetadata(
      feedUrl: item.feedUrl!,
      name: item.collectionName,
      artist: item.artistName,
      imageUrl: item.bestArtworkUrl,
      genreList: item.genre?.map((e) => e.name).toList() ?? <String>[],
    );
  }
}
