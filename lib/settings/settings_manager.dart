import 'package:flutter_it/flutter_it.dart';

import '../common/extenal_path_service.dart';
import '../extensions/shared_preferences_x.dart';
import 'settings_service.dart';

/// Manages application settings.
///
/// Note: This manager is registered as a singleton in get_it and lives for the
/// entire app lifetime. Commands don't need explicit disposal as they're
/// automatically cleaned up when the app process terminates.
class SettingsManager {
  SettingsManager({
    required SettingsService service,
    required ExternalPathService externalPathService,
  }) {
    downloadsDirCommand = Command.createAsyncNoParam(() async {
      try {
        final path = await externalPathService.getPathOfDirectory();
        if (path != null) {
          await service.setValue(SPKeys.downloads, path);
        }
        return service.downloadsDir;
      } on Exception catch (e, s) {
        return Future.error(e, s);
      }
    }, initialValue: service.downloadsDir);
  }

  late Command<void, String?> downloadsDirCommand;
}
