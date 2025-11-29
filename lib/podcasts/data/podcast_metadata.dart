import 'package:podcast_search/podcast_search.dart';

class PodcastMetadata {
  const PodcastMetadata({
    required this.feedUrl,
    this.imageUrl,
    this.name,
    this.artist,
    this.description,
    this.genreList,
  });

  final String feedUrl;
  final String? imageUrl;
  final String? name;
  final String? artist;
  final String? description;
  final List<String>? genreList;

  factory PodcastMetadata.fromItem(Item item, {String? description}) {
    if (item.feedUrl == null) {
      throw ArgumentError('Item must have a valid, non null feedUrl!');
    }
    return PodcastMetadata(
      feedUrl: item.feedUrl!,
      name: item.collectionName,
      artist: item.artistName,
      imageUrl: item.bestArtworkUrl,
      description: description,
    );
  }
}
