import 'package:flutter_it/flutter_it.dart';

import '../player/data/station_media.dart';
import '../search/search_manager.dart';
import 'radio_library_service.dart';
import 'radio_service.dart';

class RadioManager {
  RadioManager({
    required RadioLibraryService radioLibraryService,
    required RadioService radioService,
    required SearchManager searchManager,
  }) : _radioLibraryService = radioLibraryService,
       _radioService = radioService {
    favoriteStationsCommand = Command.createAsyncNoParam(
      _loadFavorites,
      initialValue: [],
    );

    searchManager.textChangedCommand
        .debounce(const Duration(milliseconds: 500))
        .listen((filterText, sub) => updateSearchCommand.run(filterText));

    updateSearchCommand = Command.createAsync<String?, List<StationMedia>>(
      (filterText) => _loadMedia(name: filterText),
      initialValue: [],
    );
  }

  final RadioLibraryService _radioLibraryService;
  final RadioService _radioService;
  late Command<void, List<StationMedia>> favoriteStationsCommand;
  late Command<String?, List<StationMedia>> updateSearchCommand;

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

  Future<List<StationMedia>> _loadFavorites() async {
    final favoriteStations = _radioLibraryService.favoriteStations;

    return Future.wait(
      favoriteStations.map((stationId) async {
        StationMedia? media;
        media = StationMedia.getCachedStationMedia(stationId);
        if (media == null) {
          final station = await _radioService.getStationByUUID(stationId);
          if (station != null) {
            media = StationMedia.fromStation(station);
          }
        }
        return Future.value(media);
      }),
    );
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
