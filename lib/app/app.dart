import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../extensions/color_x.dart';
import '../l10n/app_localizations.dart';
import '../player/player_manager.dart';

class App extends StatelessWidget with WatchItMixin {
  const App({
    super.key,
    required this.child,
    this.lightTheme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.themeMode,
  });

  final Widget child;
  final ThemeData? lightTheme,
      darkTheme,
      highContrastTheme,
      highContrastDarkTheme;
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    final playerColor = watchValue(
      (PlayerManager s) => s.playerViewState.select((e) => e.color),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: ThemeMode.system,
      theme: lightTheme?.copyWith(
        colorScheme: lightTheme?.colorScheme.copyWith(
          primary:
              playerColor?.scale(lightness: -0.3, saturation: 0.3) ??
              lightTheme?.colorScheme.primary,
        ),
      ),
      darkTheme: darkTheme?.copyWith(
        colorScheme: darkTheme?.colorScheme.copyWith(
          primary:
              playerColor?.scale(lightness: 0.5, saturation: 0.3) ??
              darkTheme?.colorScheme.primary,
        ),
      ),
      home: child,
    );
  }
}

class StaticApp extends StatelessWidget with WatchItMixin {
  const StaticApp({
    super.key,
    required this.child,
    this.lightTheme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.themeMode,
  });

  final Widget child;
  final ThemeData? lightTheme,
      darkTheme,
      highContrastTheme,
      highContrastDarkTheme;
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    themeMode: ThemeMode.system,
    theme: lightTheme,
    darkTheme: darkTheme,
    home: child,
  );
}
