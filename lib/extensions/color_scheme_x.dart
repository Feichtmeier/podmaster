import 'package:flutter/material.dart';

extension ColorSchemeX on ColorScheme {
  /// Whether the brightness is dark.
  bool get isDark => brightness == Brightness.dark;

  /// Whether the brightness is light.
  bool get isLight => brightness == Brightness.light;

  /// Whether the primary color is either black or white.
  bool get isHighContrast =>
      const [Colors.black, Colors.white].contains(primary);

  /// A color to indicate success e.g. for text input validation.
  ///
  /// ```dart
  /// Theme.of(context).colorScheme.success
  /// ```
  ///
  /// See also:
  ///  * [ColorScheme.error]
  Color get success => Colors.greenAccent;

  /// A color to indicate warnings.
  ///
  /// This is the counterpart of [ColorScheme.error].
  ///
  /// ```dart
  /// Theme.of(context).colorScheme.warning
  /// ```
  ///
  /// See also:
  ///  * [ColorScheme.error]
  Color get warning => Colors.orangeAccent;

  /// A color for presenting links.
  ///
  /// ```dart
  /// Theme.of(context).colorScheme.link
  /// ```
  Color get link => Colors.blueAccent;

  /// A color for presenting links on [inverseSurface].
  ///
  /// ```dart
  /// Theme.of(context).colorScheme.inverseLink
  /// ```
  Color get inverseLink => Colors.lightBlueAccent;
}
