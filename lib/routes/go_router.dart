import 'package:go_router/go_router.dart';
import 'package:volleyball_tournament_app/pages/home_page.dart';
import 'package:volleyball_tournament_app/pages/players/players_page_mobile.dart';
import 'package:volleyball_tournament_app/pages/tournament/knockout_stage/knockout_stage_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/settings/settings_page.dart';

import '../pages/history/history_page.dart';
import '../pages/players/players_page.dart';
import '../pages/responsive/responsive_layout.dart';
import '../pages/tournament/matches_mobile_page.dart';
import '../pages/tournament/matches_page.dart';
import '../pages/tournament/tournament_mobile_page.dart';
import '../pages/tournament/tournament_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
              path: '/tournament/:nomeDoTorneio/match',
              builder: (context, state) {
                final tournamentName = state.pathParameters['nomeDoTorneio'] ?? '';
                return ResponsiveLayout(
                  mobileScreen: MatchesMobilePage(tournamentName: tournamentName),
                  desktopScreen: MatchesPage(tournamentName: tournamentName),
                );
              },
          ),
        ]
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) => const ResponsiveLayout(mobileScreen: PlayersPageMobile(), desktopScreen: PlayersPage()),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/tournament',
        builder: (context, state) => const ResponsiveLayout(
          mobileScreen: TournamentMobilePage(),
          desktopScreen: TournamentPage(),
        ),
      ),
      GoRoute(
        path: '/tournament/:nomeDoTorneio/match',
        builder: (context, state) {
          final tournamentName = state.pathParameters['nomeDoTorneio'] ?? '';
          return ResponsiveLayout(
            mobileScreen: MatchesMobilePage(tournamentName: tournamentName),
            desktopScreen: MatchesPage(tournamentName: tournamentName),
          );
        },
        routes: [
          GoRoute(
            name: 'settings',
            path: 'settings',
            builder: (context, state) {
              return const SettingsPage();
            }
          ),
          GoRoute(
              name: 'fase2',
              path: 'fase2',
              builder: (context, state) {
                final tournamentName = state.pathParameters['nomeDoTorneio'] ?? '';
                return KnockoutStagePage(nomeTorneio: tournamentName);
              }
          ),
        ]
      ),
    ],
  );
}