import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

import 'app/app_config.dart';
import 'common/platforms.dart';
import 'player/player_manager.dart';

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
    );
}
