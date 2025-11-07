import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class App extends StatelessWidget {
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
