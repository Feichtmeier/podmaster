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
    getFavoriteStationsCommand = Command.createAsync(
      _loadFavorites,
      initialValue: [],
    );

    _collectionManager.textChangedCommand.listen(
      (filterText, sub) => getFavoriteStationsCommand.run(filterText),
    );

    searchManager.textChangedCommand
        .debounce(const Duration(milliseconds: 500))
        .listen((filterText, sub) => updateSearchCommand.run(filterText));

    updateSearchCommand = Command.createAsync<String?, List<StationMedia>>(
      (filterText) => _loadMedia(name: filterText),
      initialValue: [],
    );

    toggleFavoriteStationCommand =
        Command.createUndoableNoResult<
          String,
          ({bool wasAdd, StationMedia? media})
        >(
          (stationUuid, stack) async {
            final currentList = getFavoriteStationsCommand.value;
            final isFavorite = currentList.any((s) => s.id == stationUuid);

            // Store operation info for undo
            if (isFavorite) {
              // Removing: store the station being removed
              final stationToRemove = currentList.firstWhere(
                (s) => s.id == stationUuid,
              );
              stack.push((wasAdd: false, media: stationToRemove));

              // Optimistic: remove from list
              getFavoriteStationsCommand.value = currentList
                  .where((s) => s.id != stationUuid)
                  .toList();
            } else {
              // Adding: try to get cached media for optimistic update
              final cachedStation = StationMedia.getCachedStationMedia(
                stationUuid,
              );
              stack.push((wasAdd: true, media: cachedStation));

              // Optimistic: add if we have cached media
              if (cachedStation != null) {
                getFavoriteStationsCommand.value = [
                  ...currentList,
                  cachedStation,
                ];
              }
            }

            // Async persist
            await (isFavorite
                ? _radioLibraryService.removeFavoriteStation(stationUuid)
                : _radioLibraryService.addFavoriteStation(stationUuid));

            // Refresh to ensure consistency (fetches from network if needed)
            getFavoriteStationsCommand.run();
          },
          undo: (stack, reason) async {
            final undoData = stack.pop();
            final currentList = getFavoriteStationsCommand.value;

            if (undoData.wasAdd) {
              // Was an add, so remove it
              if (undoData.media != null) {
                getFavoriteStationsCommand.value = currentList
                    .where((s) => s.id != undoData.media!.id)
                    .toList();
              }
            } else {
              // Was a remove, so add it back
              if (undoData.media != null) {
                getFavoriteStationsCommand.value = [
                  ...currentList,
                  undoData.media!,
                ];
              }
            }
          },
        );

    getFavoriteStationsCommand.run();
  }

  final RadioLibraryService _radioLibraryService;
  final CollectionManager _collectionManager;
  final RadioService _radioService;
  late Command<String?, List<StationMedia>> getFavoriteStationsCommand;
  late Command<String?, List<StationMedia>> updateSearchCommand;
  late final Command<String, void> toggleFavoriteStationCommand;

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
    getFavoriteStationsCommand.run();
  }

  Future<void> removeFavoriteStation(String stationUuid) async {
    await _radioLibraryService.removeFavoriteStation(stationUuid);
    getFavoriteStationsCommand.run();
  }
}
