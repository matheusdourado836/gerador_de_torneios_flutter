import 'package:go_router/go_router.dart';
import 'package:volleyball_tournament_app/pages/home_page.dart';

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
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) => const PlayersPage(),
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
      ),
    ],
  );
}