import 'package:podcast_search/podcast_search.dart';

extension PodcastItemX on Item {
  Map<String, dynamic> toJson() => {
    'artistId': artistId,
    'collectionId': collectionId,
    'trackId': trackId,
    'guid': guid,
    'artistName': artistName,
    'collectionName': collectionName,
    'collectionExplicitness': collectionExplicitness,
    'trackExplicitness': trackExplicitness,
    'trackName': trackName,
    'trackCount': trackCount,
    'collectionCensoredName': collectionCensoredName,
    'trackCensoredName': trackCensoredName,
    'artistViewUrl': artistViewUrl,
    'collectionViewUrl': collectionViewUrl,
    'feedUrl': feedUrl,
    'trackViewUrl': trackViewUrl,
    'artworkUrl30': artworkUrl30,
    'artworkUrl60': artworkUrl60,
    'artworkUrl100': artworkUrl100,
    'artworkUrl600': artworkUrl600,
    'releaseDate': releaseDate?.toIso8601String(),
    'country': country,
    'primaryGenreName': primaryGenreName,
    'contentAdvisoryRating': contentAdvisoryRating,
    'genreIds': genre?.map((g) => g.id.toString()).toList(),
    'genres': genre?.map((g) => g.name).toList(),
  };
}
