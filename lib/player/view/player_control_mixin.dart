import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:go_router/go_router.dart';

import '../player_manager.dart';

mixin PlayerControlMixin {
  Future<void> togglePlayerFullMode(BuildContext context) async {
    final playerManager = di<PlayerManager>();
    final isFullMode = playerManager.playerViewState.value.fullMode;
    if (isFullMode) {
      playerManager.updateState(fullMode: false);
      if (context.canPop()) {
        context.pop();
      }
    } else {
      playerManager.updateState(fullMode: true);
      await context.push('/player');
    }
  }
}
