import 'package:shared_preferences/shared_preferences.dart';

extension SPKeys on SharedPreferences {
  static const downloads = 'downloadsCustomDir';
  static const lastCountryCode = 'lastCountryCode';
  static const lastLanguageCode = 'lastLanguageCode';
  static const usePodcastIndex = 'usePodcastIndex';
  static const themeIndex = 'themeIndex';
  static const podcastIndexApiKey = 'podcastIndexApiKey';
  static const podcastIndexApiSecret = 'podcastIndexApiSecret';
  static const favCountryCodes = 'favCountryCodes';
  static const favLanguageCodes = 'favLanguageCodes';
  static const ascendingFeeds = 'ascendingfeed:::';
  static const showPositionDuration = 'showPositionDuration';
  static const windowHeight = 'windowHeight';
  static const windowWidth = 'windowWidth';
  static const windowMaximized = 'windowMaximized';
  static const windowFullscreen = 'windowFullscreen';
  static const podcastUpdates = 'podcastUpdates';
  static const customThemeColor = 'customThemeColor';
  static const useCustomThemeColor = 'useCustomThemeColor';
  static const usePlayerColor = 'usePlayerColor';
  static const saveWindowSize = 'saveWindowSize';
  static const podcastFeedUrls = 'podcastFeedUrls';
  static const podcastImageUrlSuffix = '_imageUrl';
  static const podcastNameSuffix = '_name';
  static const podcastArtistSuffix = '_artist';
  static const podcastEpisodeDownloadedSuffix = '_episodeDownloaded';
  static const podcastsWithDownloads = 'podcastsWithDownloads';
  static const podcastsWithUpdates = 'podcastsWithUpdates';
  static const podcastLastUpdatedSuffix = '_last_updated';
  static const hideCompletedEpisodes = 'hideCompletedEpisodes';
}
