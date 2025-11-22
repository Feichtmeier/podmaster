import 'package:shared_preferences/shared_preferences.dart';

import '../extensions/shared_preferences_x.dart';

class RadioLibraryService {
  final SharedPreferences _sharedPreferences;

  RadioLibraryService({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  List<String> get favoriteStations =>
      _sharedPreferences.getStringList(SPKeys.favoriteStations) ?? [];
  bool isFavoriteStation(String stationUuid) =>
      favoriteStations.contains(stationUuid);
  Future<void> setFavoriteStations(List<String> value) async =>
      _sharedPreferences.setStringList(SPKeys.favoriteStations, value);
  Future<void> addFavoriteStation(String stationUuid) async {
    if (favoriteStations.contains(stationUuid)) return;
    final stations = List<String>.from(favoriteStations)..add(stationUuid);
    await setFavoriteStations(stations);
  }

  Future<void> removeFavoriteStation(String stationUuid) async {
    if (!favoriteStations.contains(stationUuid)) return;
    final stations = List<String>.from(favoriteStations)..remove(stationUuid);
    await setFavoriteStations(stations);
  }
}
