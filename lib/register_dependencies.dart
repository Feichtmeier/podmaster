import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_config.dart';
import 'common/platforms.dart';
import 'notifications/notifications_service.dart';
import 'player/player_manager.dart';
import 'podcasts/download_manager.dart';
import 'podcasts/podcast_library_service.dart';
import 'podcasts/podcast_manager.dart';
import 'podcasts/podcast_service.dart';
import 'settings/settings_manager.dart';
import 'settings/settings_service.dart';

void registerDependencies() {
  di
    ..registerSingletonAsync<SharedPreferences>(SharedPreferences.getInstance)
    ..registerLazySingleton<VideoController>(() {
      MediaKit.ensureInitialized();
      return VideoController(
        Player(
          configuration: const PlayerConfiguration(title: AppConfig.appName),
        ),
      );
    }, dispose: (s) => s.player.dispose())
    ..registerLazySingleton<Dio>(() => Dio(), dispose: (s) => s.close())
    ..registerSingletonAsync<PlayerManager>(
      () async => AudioService.init(
        config: AudioServiceConfig(
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: false,
          androidNotificationChannelName: AppConfig.appName,
          androidNotificationChannelId:
              Platforms.isAndroid || Platforms.isWindows
              ? AppConfig.appId
              : null,
          androidNotificationChannelDescription: 'MusicPod Media Controls',
        ),
        builder: () => PlayerManager(controller: di<VideoController>()),
      ),
      // dependsOn: [VideoController],
      dispose: (s) async => s.dispose(),
    )
    ..registerSingletonAsync<SettingsService>(() async {
      final service = SettingsService(
        sharedPreferences: di<SharedPreferences>(),
      );
      await service.init();
      return service;
    }, dependsOn: [SharedPreferences])
    ..registerLazySingleton<NotificationsService>(() => NotificationsService())
    ..registerSingletonWithDependencies<PodcastLibraryService>(
      () => PodcastLibraryService(sharedPreferences: di<SharedPreferences>()),
      dependsOn: [SharedPreferences],
    )
    ..registerSingletonWithDependencies<PodcastService>(
      () => PodcastService(
        libraryService: di<PodcastLibraryService>(),
        notificationsService: di<NotificationsService>(),
        settingsService: di<SettingsService>(),
      ),
      dependsOn: [PodcastLibraryService, SettingsService],
    )
    ..registerSingletonWithDependencies<PodcastManager>(
      () => PodcastManager(podcastService: di<PodcastService>()),
      dependsOn: [PodcastService],
    )
    ..registerLazySingleton<SettingsManager>(
      () => SettingsManager(service: di<SettingsService>()),
    )
    ..registerLazySingleton<DownloadManager>(
      () => DownloadManager(
        libraryService: di<PodcastLibraryService>(),
        settingsService: di<SettingsService>(),
        dio: di<Dio>(),
      ),
    );
}
