import 'package:flutter/material.dart';
import '../common/view/ui_constants.dart';

import '../l10n/app_localizations.dart';

extension BuildContextX on BuildContext {
  MediaQueryData get mq => MediaQuery.of(this);
  Size get mediaQuerySize => MediaQuery.sizeOf(this);
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get showSideBar => mediaQuerySize.width > kShowSideBarThreshHold;
  AppLocalizations get l10n => AppLocalizations.of(this);
  double get buttonRadius => theme.buttonTheme.shape is RoundedRectangleBorder
      ? (theme.buttonTheme.shape as RoundedRectangleBorder).borderRadius
            .resolve(TextDirection.ltr)
            .topLeft
            .x
      : 12;
}
