import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../common/view/confirm.dart';
import '../../extensions/build_context_x.dart';
import '../data/unique_media.dart';
import '../player_manager.dart';
import 'player_full_view.dart';

mixin PlayerControlMixin {
  Future<void> togglePlayerFullMode(BuildContext context) async {
    if (di<PlayerManager>().playerViewState.value.fullMode) {
      di<PlayerManager>().updateState(fullMode: false);
      await Navigator.of(context).maybePop();
    } else {
      di<PlayerManager>().updateState(fullMode: true);
      await showDialog(
        context: context,
        builder: (context) => const PlayerFullView(),
      );
    }
  }

  Future<void> playMatrixMedia(
    BuildContext context, {
    required UniqueMedia media,
    bool newPlaylist = true,
  }) async {
    if (newPlaylist) {
      await di<PlayerManager>().setPlaylist([media]);
    } else if (!di<PlayerManager>().playlist.medias.contains(media)) {
      await di<PlayerManager>().addToPlaylist(media);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.appendedToQueue('${media.artist} - ${media.title}'),
            ),
          ),
        );
      }
    } else {
      if (context.mounted) {
        await ConfirmationDialog.show(
          context: context,
          title: Text(context.l10n.appendMediaToQueueTitle),
          content: Text(
            context.l10n.appendMediaToQueueDescription(
              '${media.artist} - ${media.title}',
            ),
          ),
          onConfirm: () async {
            await di<PlayerManager>().addToPlaylist(media);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.l10n.appendedToQueue(
                      '${media.artist} - ${media.title}',
                    ),
                  ),
                ),
              );
            }
          },
        );
      }
    }
  }
}
