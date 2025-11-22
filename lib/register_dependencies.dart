import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app_config.dart';
import 'collection/collection_manager.dart';
import 'common/extenal_path_service.dart';
import 'common/platforms.dart';
import 'notifications/notifications_service.dart';
import 'online_art/online_art_service.dart';
import 'player/player_manager.dart';
import 'podcasts/download_manager.dart';
import 'podcasts/podcast_library_service.dart';
import 'podcasts/podcast_manager.dart';
import 'podcasts/podcast_service.dart';
import 'radio/radio_library_service.dart';
import 'radio/radio_manager.dart';
import 'radio/radio_service.dart';
import 'search/search_manager.dart';
import 'settings/settings_manager.dart';
import 'settings/settings_service.dart';

void registerDependencies() {
  di
    ..registerSingletonAsync<WindowManager>(() async {
      final wm = WindowManager.instance;
      await wm.ensureInitialized();
      await wm.waitUntilReadyToShow(
        const WindowOptions(
          backgroundColor: Colors.transparent,
          minimumSize: Size(500, 700),
          size: Size(900, 800),
          center: true,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
        ),
        () async {
          await windowManager.show();
          await windowManager.focus();
        },
      );

      return wm;
    })
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
    ..registerSingleton<SearchManager>(SearchManager())
    ..registerSingletonWithDependencies<PodcastManager>(
      () => PodcastManager(
        podcastService: di<PodcastService>(),
        searchManager: di<SearchManager>(),
      ),
      dependsOn: [PodcastService],
    )
    ..registerLazySingleton<ExternalPathService>(
      () => const ExternalPathService(),
    )
    ..registerSingletonWithDependencies<SettingsManager>(
      () => SettingsManager(
        service: di<SettingsService>(),
        externalPathService: di<ExternalPathService>(),
      ),
      dependsOn: [SettingsService],
    )
    ..registerSingletonWithDependencies<DownloadManager>(
      () => DownloadManager(
        libraryService: di<PodcastLibraryService>(),
        settingsService: di<SettingsService>(),
        dio: di<Dio>(),
      ),
      dependsOn: [SettingsService],
    )
    ..registerSingletonWithDependencies<RadioLibraryService>(
      () => RadioLibraryService(sharedPreferences: di<SharedPreferences>()),
      dependsOn: [SharedPreferences],
    )
    ..registerLazySingleton<OnlineArtService>(
      () => OnlineArtService(dio: di<Dio>()),
    )
    ..registerSingletonWithDependencies<RadioService>(
      () => RadioService(
        playerManager: di<PlayerManager>(),
        onlineArtService: di<OnlineArtService>(),
      ),
      dependsOn: [PlayerManager],
    )
    ..registerLazySingleton<RadioManager>(
      () => RadioManager(
        radioLibraryService: di<RadioLibraryService>(),
        radioService: di<RadioService>(),
        searchManager: di<SearchManager>(),
      ),
    )
    ..registerLazySingleton<CollectionManager>(() => CollectionManager());
}
