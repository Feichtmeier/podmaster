import 'package:flutter/material.dart';

import '../extensions/build_context_x.dart';

enum MediaType {
  podcast,
  radioStation;

  String localize(BuildContext context) => switch (this) {
    MediaType.podcast => context.l10n.podcasts,
    MediaType.radioStation => context.l10n.stations,
  };

  IconData iconData() => switch (this) {
    MediaType.podcast => Icons.podcasts,
    MediaType.radioStation => Icons.radio,
  };
}
