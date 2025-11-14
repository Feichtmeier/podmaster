import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_config.dart';
import '../../common/view/confirm.dart';
import '../../extensions/build_context_x.dart';
import '../settings_manager.dart';

class SettingsDialog extends StatelessWidget with WatchItMixin {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) => SimpleDialog(
    children: [
      ListTile(
        trailing: ElevatedButton(
          onPressed: di<SettingsManager>().downloadsDirCommand.execute,
          child: Text(context.l10n.open),
        ),
        title: Text(context.l10n.downloadsDirectory),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                context.l10n.downloadsDirectoryDescription(AppConfig.appName),
              ),
            ),
            watchValue(
              (SettingsManager m) => m.downloadsDirCommand.results,
            ).toWidget(
              onData: (dir, param) => Text(dir ?? ''),
              whileExecuting: (_, _) => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              onError: (e, lastResult, c) => Text(e.toString()),
            ),
          ],
        ),
      ),
      ListTile(
        title: Text(context.l10n.resetAllSettings),
        trailing: ElevatedButton(
          onPressed: () => ConfirmationDialog.show(
            context: context,
            title: Text(context.l10n.resetAllSettingsConfirm),
            onConfirm: di<SharedPreferences>().clear,
          ),
          child: Text(context.l10n.resetAllSettings),
        ),
      ),
    ],
  );
}
