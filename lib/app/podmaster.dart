import 'package:flutter/material.dart';
import 'package:phoenix_theme/phoenix_theme.dart' hide ColorX;
import 'package:system_theme/system_theme.dart';
import 'package:system_theme/system_theme_builder.dart';

import '../common/view/wait_for_registration_page.dart';
import '../extensions/build_context_x.dart';
import '../extensions/color_x.dart';

class Podmaster extends StatelessWidget {
  const Podmaster({
    super.key,
    this.lightTheme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.themeMode,
  });

  final ThemeData? lightTheme,
      darkTheme,
      highContrastTheme,
      highContrastDarkTheme;
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) => SystemThemeBuilder(
    builder: (context, accent) {
      final theme = phoenixTheme(color: accent.accent);

      return WaitForRegistrationPage(
        lightTheme: theme.lightTheme.copyWith(
          navigationRailTheme: createNavigationRailTheme(
            context,
            theme.lightTheme.colorScheme.primary,
          ),
        ),
        darkTheme: theme.darkTheme.copyWith(
          navigationRailTheme: createNavigationRailTheme(
            context,
            theme.darkTheme.colorScheme.primary,
          ),
        ),
      );
    },
  );

  NavigationRailThemeData createNavigationRailTheme(
    BuildContext context,
    Color color,
  ) {
    return NavigationRailTheme.of(context).copyWith(
      indicatorColor: NavigationRailTheme.of(context).indicatorColor?.scale(
        saturation: -1,
        lightness: context.colorScheme.isLight ? -0.9 : -0.9,
      ),

      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
