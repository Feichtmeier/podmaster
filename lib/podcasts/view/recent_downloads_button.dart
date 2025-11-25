import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:yaru/yaru.dart';

import '../../extensions/build_context_x.dart';
import '../../player/player_manager.dart';
import '../podcast_manager.dart';
import 'download_button.dart';

class RecentDownloadsButton extends StatefulWidget
    with WatchItStatefulWidgetMixin {
  const RecentDownloadsButton({super.key});

  @override
  State<RecentDownloadsButton> createState() => _RecentDownloadsButtonState();
}

class _RecentDownloadsButtonState extends State<RecentDownloadsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final activeDownloads = watchValue((PodcastManager m) => m.activeDownloads);

    final hasAnyDownloads = activeDownloads.isNotEmpty;
    final hasInProgressDownloads = activeDownloads.any((e) => !e.isDownloaded);

    if (hasInProgressDownloads) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller
        ..stop()
        ..value = 1.0;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: hasAnyDownloads ? 1.0 : 0.0,
      child: IconButton(
        icon: hasInProgressDownloads
            ? FadeTransition(
                opacity: _animation,
                child: Icon(
                  Icons.download_for_offline,
                  color: theme.colorScheme.primary,
                ),
              )
            : Icon(
                Icons.download_for_offline,
                color: hasAnyDownloads
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            titlePadding: EdgeInsets.zero,
            title: const YaruDialogTitleBar(
              title: Text('Recent Downloads'),
              border: BorderSide.none,
              backgroundColor: Colors.transparent,
            ),
            content: SizedBox(
              width: 400,
              height: 400,
              child: CustomScrollView(
                slivers: [
                  SliverList.builder(
                    itemCount: activeDownloads.length,
                    itemBuilder: (context, index) {
                      final episode = activeDownloads[index];
                      return ListTile(
                        onTap: () {
                          if (episode.isDownloaded) {
                            di<PlayerManager>().setPlaylist([episode]);
                          }
                        },
                        title: Text(episode.title ?? context.l10n.unknown),
                        subtitle: Text(episode.artist ?? context.l10n.unknown),
                        trailing: DownloadButton(episode: episode),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
