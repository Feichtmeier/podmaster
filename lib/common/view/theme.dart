// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../extensions/build_context_x.dart';
import '../../extensions/color_scheme_x.dart';
import '../../extensions/color_x.dart';

ButtonStyle getTextFieldSuffixStyle(BuildContext context, bool isLast) =>
    IconButton.styleFrom(
      fixedSize: const Size.square(40),
      shape: RoundedRectangleBorder(
        borderRadius: isLast
            ? BorderRadius.only(
                topRight: Radius.circular(context.buttonRadius),
                bottomRight: Radius.circular(context.buttonRadius),
              )
            : BorderRadius.zero,
      ),
    );

ButtonStyle getTextFieldPrefixStyle(BuildContext context, int index) =>
    IconButton.styleFrom(
      fixedSize: const Size.square(40),
      shape: RoundedRectangleBorder(
        borderRadius: index == 0
            ? BorderRadius.only(
                topLeft: Radius.circular(context.buttonRadius),
                bottomLeft: Radius.circular(context.buttonRadius),
              )
            : BorderRadius.zero,
      ),
    );

Color blendColor(Color baseColor, Color blendColor, double amount) {
  return Color.fromARGB(
    (baseColor.alpha * (1 - amount) + blendColor.alpha * amount).round(),
    (baseColor.red * (1 - amount) + blendColor.red * amount).round(),
    (baseColor.green * (1 - amount) + blendColor.green * amount).round(),
    (baseColor.blue * (1 - amount) + blendColor.blue * amount).round(),
  );
}

Color getPlayerBg(
  ThemeData theme,
  Color? playerAccent, {
  double blendAmount = 0.3,
  double saturation = -0.5,
}) {
  final colorScheme = theme.colorScheme;
  final isLight = colorScheme.isLight;
  final bgBaseColor = isLight ? colorScheme.surface : Colors.black;
  final accent =
      playerAccent?.scale(saturation: saturation) ?? theme.colorScheme.primary;

  return blendColor(bgBaseColor, accent, blendAmount);
}

Color getPlayerIconColor(ThemeData theme) {
  final colorScheme = theme.colorScheme;
  final isLight = colorScheme.isLight;

  if (isLight) {
    return colorScheme.onSurface;
  } else {
    return Colors.white;
  }
}
