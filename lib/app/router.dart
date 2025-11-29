import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:podcast_search/podcast_search.dart';

import '../player/data/station_media.dart';
import '../player/view/player_full_view.dart';
import '../podcasts/view/podcast_page.dart';
import '../radio/view/station_page.dart';
import 'home.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: '/',
          pageBuilder: (_, _) => const NoTransitionPage(child: Home()),
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: '/player',
          pageBuilder: (_, _) =>
              const NoTransitionPage(child: PlayerFullView()),
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: '/podcast/:feedUrl',
          pageBuilder: (_, state) => NoTransitionPage(
            child: PodcastPage(
              feedUrl: state.pathParameters['feedUrl']!,
              podcastItem: state.extra as Item?,
            ),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: '/station/:uuid',
          pageBuilder: (_, state) => NoTransitionPage(
            child: StationPage(
              uuid: state.pathParameters['uuid']!,
              stationMedia: state.extra as StationMedia,
            ),
          ),
        ),
      ],
    ),
  ],
);
