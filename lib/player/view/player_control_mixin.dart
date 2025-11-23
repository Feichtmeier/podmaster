import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

import '../player_manager.dart';
import 'player_full_view.dart';

mixin PlayerControlMixin {
  Future<void> togglePlayerFullMode(BuildContext context) async {
    if (di<PlayerManager>().playerViewState.value.fullMode) {
      di<PlayerManager>().updateState(fullMode: false);
      Navigator.of(context).popUntil((e) => e.isFirst);
    } else {
      di<PlayerManager>().updateState(fullMode: true);
      await showDialog(
        fullscreenDialog: true,
        context: context,
        builder: (context) => const PlayerFullView(),
      );
    }
  }
}
