import 'package:flutter_it/flutter_it.dart';

import '../collection/collection_manager.dart';
import '../player/data/station_media.dart';
import '../search/search_manager.dart';
import 'radio_library_service.dart';
import 'radio_service.dart';

class RadioManager {
  RadioManager({
    required RadioLibraryService radioLibraryService,
    required RadioService radioService,
    required SearchManager searchManager,
    required CollectionManager collectionManager,
  }) : _radioLibraryService = radioLibraryService,
       _radioService = radioService,
       _collectionManager = collectionManager {
    favoriteStationsCommand = Command.createAsync(
      _loadFavorites,
      initialValue: [],
    );

    _collectionManager.textChangedCommand.listen(
      (filterText, sub) => favoriteStationsCommand.run(filterText),
    );

    searchManager.textChangedCommand
        .debounce(const Duration(milliseconds: 500))
        .listen((filterText, sub) => updateSearchCommand.run(filterText));

    updateSearchCommand = Command.createAsync<String?, List<StationMedia>>(
      (filterText) => _loadMedia(name: filterText),
      initialValue: [],
    );

    toggleFavoriteStationCommand = Command.createAsync<String, void>((
      stationUuid,
    ) async {
      // Check if station is already a favorite
      final isFavorite = _radioLibraryService.favoriteStations.contains(
        stationUuid,
      );

      if (isFavorite) {
        await removeFavoriteStation(stationUuid);
      } else {
        await addFavoriteStation(stationUuid);
      }
    }, initialValue: null);

    favoriteStationsCommand.run();
  }

  final RadioLibraryService _radioLibraryService;
  final CollectionManager _collectionManager;
  final RadioService _radioService;
  late Command<String?, List<StationMedia>> favoriteStationsCommand;
  late Command<String?, List<StationMedia>> updateSearchCommand;
  late Command<String, void> toggleFavoriteStationCommand;

  Future<List<StationMedia>> _loadMedia({
    String? country,
    String? name,
    String? state,
    String? tag,
    String? language,
  }) async {
    if (name == null || name.isEmpty) {
      return [];
    }
    final result = await di<RadioService>().search(
      country: country,
      name: name,
      state: state,
      tag: tag,
      language: language,
    );
    return result?.map((e) => StationMedia.fromStation(e)).toList() ?? [];
  }

  Future<List<StationMedia>> _loadFavorites(String? filterText) async {
    final favoriteStations = _radioLibraryService.favoriteStations;

    final stations = <StationMedia>[];
    for (final stationId in favoriteStations) {
      StationMedia? media = StationMedia.getCachedStationMedia(stationId);
      if (media == null) {
        final station = await _radioService.getStationByUUID(stationId);
        if (station != null) {
          media = StationMedia.fromStation(station);
        }
      }
      if (media != null) {
        stations.add(media);
      }
    }

    return stations
        .where(
          (e) =>
              e.title.toLowerCase().contains(filterText?.toLowerCase() ?? ''),
        )
        .toList();
  }

  Future<void> addFavoriteStation(String stationUuid) async {
    await _radioLibraryService.addFavoriteStation(stationUuid);
    favoriteStationsCommand.run();
  }

  Future<void> removeFavoriteStation(String stationUuid) async {
    await _radioLibraryService.removeFavoriteStation(stationUuid);
    favoriteStationsCommand.run();
  }
}
