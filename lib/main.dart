import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';
import 'package:yaru/widgets.dart';

import 'app/mediadojo.dart';
import 'register_dependencies.dart';

Future<void> main() async {
  await YaruWindowTitleBar.ensureInitialized();
  await SystemTheme.accentColor.load();
  registerDependencies();
  runApp(const MediaDojo());
}
