// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import '../platforms.dart';
import '../../extensions/color_scheme_x.dart';
import '../../extensions/color_x.dart';

bool yaru = Platforms.isDesktop;

Color remixColor(Color targetColor, {List<Color> palette = Colors.accents}) {
  double minDistance = double.infinity;
  Color closestColor = palette[0];

  for (Color color in palette) {
    double distance = colorDistance(targetColor, color);
    if (distance < minDistance) {
      minDistance = distance;
      closestColor = color;
    }
  }

  return closestColor;
}

double colorDistance(Color color1, Color color2) {
  int rDiff = color1.r.toInt() - color2.r.toInt();
  int gDiff = color1.g.toInt() - color2.g.toInt();
  int bDiff = color1.b.toInt() - (color2.b * 0.4).toInt();
  return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
}

Color getTileColor(bool isUserEvent, ThemeData theme) {
  final userColor = theme.colorScheme.primary.scale(
    saturation: theme.colorScheme.isLight ? (yaru ? -0.3 : -0.6) : -0.6,
    lightness: theme.colorScheme.isLight ? 0.65 : (yaru ? -0.5 : -0.7),
  );

  return isUserEvent
      ? userColor
      : getMonochromeBg(theme: theme, factor: 6, darkFactor: 15);
}

Color getPanelBg(ThemeData theme) =>
    getMonochromeBg(theme: theme, darkFactor: 3);

Color getMonochromeBg({
  required ThemeData theme,
  double factor = 1.0,
  double? darkFactor,
  double? lightFactor,
}) => theme.colorScheme.surface.scale(
  lightness:
      (theme.colorScheme.isLight ? -0.02 : 0.005) *
      (theme.colorScheme.isLight
          ? lightFactor ?? factor
          : darkFactor ?? factor),
);

Color getEventBadgeColor(ThemeData theme, bool showAsSpecialBadge) =>
    showAsSpecialBadge
    ? theme.colorScheme.primary
    : theme.colorScheme.onSurface.withValues(alpha: 0.2);

Color getEventBadgeTextColor(ThemeData theme, String type) =>
    type == 'm.space.parent' || type == 'm.space.child'
    ? theme.colorScheme.onPrimary
    : theme.colorScheme.onSurface;

ButtonStyle get textFieldSuffixStyle => IconButton.styleFrom(
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topRight: Radius.circular(6),
      bottomRight: Radius.circular(6),
    ),
  ),
);

Color avatarFallbackColor(ColorScheme colorScheme) =>
    colorScheme.primary.withValues(alpha: 0.3);

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
