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
}
